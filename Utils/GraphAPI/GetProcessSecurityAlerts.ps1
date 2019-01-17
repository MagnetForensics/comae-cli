<#

.COPYRIGHT
Copyright (c) Comae Technologies DMCC. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

    Module Name:
        GetProcessSecurityAlerts

    Abstract:
        Identify processes to be dumped for a memory forensics investigation using the alerts
        returned by Microsoft Graph Security API
        
        Analyze the generated memory dumps with Comae Stardust: https://my.comae.io

        Maybe in the future, we will add a direct integration inside Comae Stardust - but for the moment having a 
        PowerShell script helping analysts to narrow down what to do is perfect.

    Author: 
        Matt Suiche (msuiche) 17-jan-2019

#>

####################################################

Function Get-ProcessesRelatedAlerts() {

<#
.SYNOPSIS
This function is used to get the process IDs of the latest alerts retrievable by the Graph Security API.
.DESCRIPTION
The function connects to the Graph Security API Interface and gets the top 25 alerts from each category indexed by the 
Security API provider.
.EXAMPLE
Get-ProcessesRelatedAlerts
.NOTES
NAME: Get-ProcessesRelatedAlerts
#>

[cmdletbinding()]

    # Top categories, with processes[n] members - There are probably more, I didn't find a proper documentation listing all the possible
    # categories anywhere. Hopefully, this gets released soon.
    $categories = "suspiciousPowerShell", "exploit", "Petya", "DoubleExtension"
    $graphApiVersion = "v1.0"

    foreach ($category in $categories)
    {
        $resource = "security/alerts?`$filter=Category eq '$category'`&`$top=25"

        try {
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
            $data = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value
            # $data
            $objs = $data | Select-Object id, description, category, eventDateTime, fileStates, hostStates, userStates, assignedTo, severity, status

            foreach ($obj in $objs) {
                $status = $obj.status
                $assignedTo = $obj.assignedTo
                $severity = $obj.severity
                $category = $obj.category
                $eventId = $obj.id

                $userStates = $obj.userStates | Select-Object domainName, accountName
                $hostStates = $obj.hostStates | Select-Object netBiosName, privateIpAddress, publicIpAddress
                $fileStates = $obj.hostStates | Select-Object name, path

                $domainName = $userStates.domainName
                $accountName = $userStates.accountName

                $netBiosName = $hostStates.netBiosName
                $privateIpAddress = $hostStates.privateIpAddress
                $publicIpAddress = $hostStates.publicIpAddress

            
                if (![bool]$privateIpAddress) { $privateIpAddress = "<Unknown>" }
                if (![bool]$publicIpAddress) { $publicIpAddress = "<Unknown>" }

                $eventDate = [datetime]::Parse($obj.eventDateTime)
                $details = $obj.description
                $details = $details.Split(" ")

                Write-Host "----------------"
                # Each event has a status which tells you if someone is taking care of it. Lots of cool stuff around that.
                Write-Host "[+] EventId: $eventId" -ForegroundColor red -BackgroundColor white
                switch ($status)
                {
                    "newAlert" { 
                        Write-Host "A $severity priority event of category '$category' happened on $eventDate, and is currently unmanaged." -ForegroundColor red; 
                        break; 
                    }
                    "inProgress" { 
                        Write-Host "A $severity priority event of category '$category' happened on $eventDate, and is currently handled by $assignedTo" -ForegroundColor yellow;
                        break;  
                    } 
                }

                # Just breaking down the sentence into around 80 chars per line, so it's readable.
                Write-Host "`n[+] Details:" -ForegroundColor red -BackgroundColor white
                $len = 0
                foreach ($word in $details) {
                    Write-Host "$word "  -NoNewline
                    $len += $word.Length
                    if ($len -ge 80) { Write-Host ""; $len = 0 }
                }
                Write-Host " "

                # Network information related to where the target machine is located, this could be leverage with a PsExec or something like this.
                Write-Host "`n[+] Information:" -ForegroundColor red -BackgroundColor white
                # Write-Host "Proceed to a memory snapshot of the following processes using either the TaskMgr, Process Explorer or ProcDump, to get more information" -ForegroundColor red -BackgroundColor white
                Write-Host "Machine: $domainName\\$accountName - NetBiosName: $netBiosName - Internal IP: $privateIpAddress - External IP: $publicIpAddress"
                
                # One event can contain multiple process
                Write-Host "`n[+] Related Processes:" -ForegroundColor red -BackgroundColor white
                foreach ($process in $data.processes) 
                {
                    $obj = $process | Select-Object processId, name, createdDateTime, commandLine, parentProcessId, parentProcessName
                    
                    # $process
                    #$processCreationDate = [datetime]::Parse($obj.createdDateTime)
                    #$ts = New-TimeSpan -Start $processCreationDate -End $eventDate
                    #$intervalInSecs = $ts.Seconds
                    $processPid = $obj.processId
                    $parentProcessName = $obj.parentProcessName
                    $parentProcessPid = $obj.parentProcessPid
                    $processName = $obj.name
                    $commandLine = $obj.commandLine

                    # Probably some internal bugs related to Graph API, several members do not have the right information filled in. :(
                    if (![bool]$processName) { $processName = "<Unknown>" }
                    if (![bool]$parentProcessName) { $parentProcessName = "<Unknown>" }
                    if (![bool]$parentProcessId) { $parentProcessId = "<Unknown>" }
                    Write-Host "- $processName (PID: $processPid) (Parent Process: $parentProcessName ($parentProcessId))"
                    if ($commandLine) { Write-Host "  Command Line: '$commandLine'" }
                    Write-Host "  You can use the following command to create a full dump of the process with ProcDump: " -NoNewline
                    Write-Host "'procdump -ma $processPid'" -ForegroundColor green
                }

                Write-Host "----------------`n"
            }
        } 
        catch {
            $ex = $_.Exception
            $errorResponse = $ex.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorResponse)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();
            Write-Host "Response content:`n$responseBody" -f Red
            Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
            Write-Host
            break
        }
    }
}


####################################################

function Get-AuthToken {

<#
.SYNOPSIS
This function is used to authenticate with the Graph API REST interface
.DESCRIPTION
The function authenticate with the Graph API Interface with the tenant name
.EXAMPLE
Get-AuthToken
Authenticates you with the Graph API interface
.NOTES
NAME: Get-AuthToken
#>

[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    $User
)

    $userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User

    $tenant = $userUpn.Host

    Write-Host "Checking for AzureAD module..."

    $AadModule = Get-Module -Name "AzureAD" -ListAvailable

    if ($AadModule -eq $null)
    {
        Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
        $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable
    }

    if ($AadModule -eq $null)
    {
        Write-Host
        Write-Host "AzureAD Powershell module not installed..." -f Red
        Write-Host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
        Write-Host "Script can't continue..." -f Red
        Write-Host
        exit
    }

    # Getting path to ActiveDirectory Assemblies
    # If the module count is greater than 1 find the latest version
    if ($AadModule.count -gt 1)
    {
        $Latest_Version = ($AadModule | select version | Sort-Object)[-1]
        $aadModule = $AadModule | ? { $_.version -eq $Latest_Version.version }

            # Checking if there are multiple versions of the same module found
            if($AadModule.count -gt 1){
            $aadModule = $AadModule | select -Unique
            }

        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
    }
    else
    {
        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
    }

    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null

    [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null

    $clientId = "22ea8966-f683-403f-b772-2bd485ddb553"

    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"

    $resourceAppIdURI = "https://graph.microsoft.com"

    $authority = "https://login.microsoftonline.com/$Tenant"

    try {
        $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

        # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
        # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession

        $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"

        $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")

        $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$clientId,$redirectUri,$platformParameters,$userId).Result

        # If the accesstoken is valid then create the authentication header
        if ($authResult.AccessToken)
        {

            # Creating header for Authorization token
            $authHeader = @{
                'Content-Type'='application/json'
                'Authorization'="Bearer " + $authResult.AccessToken
                'ExpiresOn'=$authResult.ExpiresOn
                }
            return $authHeader
        }
        else
        {
            Write-Host
            Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
            Write-Host
            break
        }
    }
    catch {
        Write-Host $_.Exception.Message -f Red
        Write-Host $_.Exception.ItemName -f Red
        Write-Host
        break
    }
}

####################################################
#
# main
#
Write-Host

# Checking if authToken exists before running authentication
if ($global:authToken)
{

    # Setting DateTime to Universal time to work in all timezones
    $DateTime = (Get-Date).ToUniversalTime()

    # If the authToken exists checking when it expires
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

    if ($TokenExpires -le 0)
    {
        Write-Host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        Write-Host

        # Defining User Principal Name if not present
        if ($User -eq $null -or $User -eq ""){
            $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
            Write-Host
        }
        $global:authToken = Get-AuthToken -User $User
    }
}
else 
{
    if ($User -eq $null -or $User -eq "")
    {
        $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
        Write-Host
    }

    $global:authToken = Get-AuthToken -User $User
}

####################################################

Write-Host "##################################################################################################" -ForegroundColor green
Write-Host "# GetProcessSecurityAlerts v0.1 (17 January 2019)                                                #" -ForegroundColor green
Write-Host "#   Identify processes to be dumped for a memory forensics investigation using the alerts        #" -ForegroundColor green
Write-Host "#   returned by Microsoft Graph Security API                                                     #" -ForegroundColor green
Write-Host "#   Analyze the generated memory dumps with Comae Stardust: https://my.comae.io                  #" -ForegroundColor green
# TODO: Comae Stardust also has an API interface to upload memory dumps that could be added. More information: https://github.com/comaeio/Stardust-PowerShell
Write-Host "##################################################################################################`n" -ForegroundColor green

Get-ProcessesRelatedAlerts
