﻿$hostname = "api.comae.com"

Function Get-ComaeAPIKey(
    [Parameter(Mandatory = $True)] [string] $ClientId,
    [Parameter(Mandatory = $True)] [string] $ClientSecret
    )
{
    $Headers = @{
        "Content-Type" = "application/json"
        "Cache-Control" = "no-cache"
    }

    $Body = @{
        "grant_type" = "client_credentials"
        "client_id" = $ClientId
        "client_secret" = $ClientSecret
        "audience" = "JHYFRulOwjLslg87tUt4bCT8i4O3yBsm"
    }

    $Key = ""

    $Uri = "https://comae.auth0.com/oauth/token"

    $Response = Invoke-WebRequest -Uri $Uri -Method Post -Body ($Body|ConvertTo-Json) -Headers $Headers -TimeoutSec 86400 -UseBasicParsing

    if ($Response.StatusCode -eq 200) {
        $Key = ($Response.Content | ConvertFrom-JSON).access_token
    }

    Return $Key
}

Function New-ComaeSnapshot(
    [Parameter(Mandatory = $True)] [string] $Directory
    )
{
    if ((Test-Path  '.\DumpIt.exe') -ne $True) {
        Write-Error "This script needs to be in the same directory as '.\DumpIt.exe'."
        Return 1
    }

    if ((Test-Path  '.\Dmp2Json.exe') -ne $True) {
        Write-Error "This script needs to be in the same directory as '.\Dmp2Json.exe'."
        Return 1
    }

    if ((Test-Path $Directory) -ne $True) {

        New-Item $Directory -ItemType "Directory"
    }

    $DateTime = Get-Date

    $Date = [String]::Format("{0}-{1:00}-{2:00}", $DateTime.Year, $DateTime.Month, $DateTime.Day)
    $Time = [String]::Format("{0:00}-{1:00}-{2:00}", $DateTime.Hour, $DateTime.Minute, $DateTime.Second)

    $SnapshotDirectory = "$Directory\$env:COMPUTERNAME-$Date-$Time"

    Write-Output "Launching DumpIt.exe..."

    .\DumpIt.exe /L /A Dmp2Json.exe /C "/Y srv*C:\Symbols*http://msdl.microsoft.com/download/symbols /C \"/live /all /archive /snapshot $SnapshotDirectory""
}

Function Send-ComaeSnapshot(
    [Parameter(Mandatory = $True)] [string] $Key, # Returned by Get-ComaeAPIKey
    [Parameter(Mandatory = $True)] [string] $Path,
    [Parameter(Mandatory = $True)] [string] $ItemType
    )
{
    if ($ItemType -eq "Directory") {
        if ((Test-Path  '.\DumpIt.exe') -ne $True) {
          Write-Error "This script needs to be in the same directory as '.\DumpIt.exe'."
            Return 1
       }
        $Directory = $Path

        if ((Test-Path $Directory) -ne $True) {

            New-Item $Directory -ItemType "Directory"
        }

        $DateTime = Get-Date

        $Date = [String]::Format("{0}-{1:00}-{2:00}", $DateTime.Year, $DateTime.Month, $DateTime.Day)
        $Time = [String]::Format("{0:00}-{1:00}-{2:00}", $DateTime.Hour, $DateTime.Minute, $DateTime.Second)

        $SnapshotDirectory = "$Directory\$env:COMPUTERNAME-$Date-$Time"

        Write-Output "Launching DumpIt.exe..."

        .\DumpIt.exe /L /A Dmp2Json.exe /C "/Y srv*C:\Symbols*http://msdl.microsoft.com/download/symbols /C \"/live /all /archive /snapshot $SnapshotDirectory""

        $SnapshotFile = "$Directory\$env:COMPUTERNAME-$Date-$Time.json.zip"
    }
    elseif ($ItemType -eq "File") {

        $SnapshotFile = $Path
    }
    else {

        Write-Error "Please provide -ItemType parameter as Directory or File."

        Return 1
    }

    if ((Test-Path $SnapshotFile) -ne $True) {

        Write-Error "Could not find snapshot file '$SnapshotFile'"

        Return 1
    }

    $FileName = Split-Path $SnapshotFile -Leaf

    $Boundary = "---powershellOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZ"

    $Headers = @{
        "Authorization" = "Bearer " + $Key;
        "Content-Type" = "multipart/form-data; boundary=$Boundary";
        "Accept" = "*/*";
        "Accept-Encoding" = "gzip, deflate, br";
        "pragma" = "no-cache";
        "cache-control" = "no-cache"
    }

$BodyTemplate = @"
--$Boundary
Content-Disposition: form-data; name="filename"

$FileName
--$Boundary
Content-Disposition: form-data; name=`"file`"; filename=`"$FileName`"
Content-Type: application/octet-stream

{0}
--$Boundary--
`r`n
"@

    $GetEncoding = [System.Text.Encoding]::GetEncoding("iso-8859-1")

    $BufferSize = (Get-Item $SnapshotFile).Length

    if ($BufferSize) {

        $Buffer = [System.IO.File]::ReadAllBytes($SnapshotFile)

        $Content = $GetEncoding.GetString($Buffer, 0, $BufferSize)

        $Body = $BodyTemplate -f $Content

        $Uri = "https://" + $hostname + "/v1/upload/json"

        Write-Output "Uploading $SnapshotFile..."

        do {

            $Response = Invoke-WebRequest -Uri $Uri -Method Post -Body $Body -Headers $Headers -TimeoutSec 86400 -UseBasicParsing

        } while ($Response.StatusCode -ne 200)

        Write-Output "Done."
    }
}

Function New-ComaeDumpFile(
    [Parameter(Mandatory = $True)] [string] $Directory,
    [Parameter(Mandatory = $False)] [switch] $IsCompress
    )
{
    if ((Test-Path  '.\DumpIt.exe') -ne $True) {
        Write-Error "This script needs to be in the same directory as '.\DumpIt.exe'."
        Return 1
    }

    if ((Test-Path $Directory) -ne $True) {
        New-Item $Directory -ItemType "Directory"
    }

    $DateTime = Get-Date

    $Date = [String]::Format("{0}-{1:00}-{2:00}", $DateTime.Year, $DateTime.Month, $DateTime.Day)
    $Time = [String]::Format("{0:00}-{1:00}-{2:00}", $DateTime.Hour, $DateTime.Minute, $DateTime.Second)

    if ($IsCompress) {
        $Extension = "zdmp"
        $Compression = "/compress"
    }
    else {
        $Extension = "dmp"
        $Compression = ""
    }

    $DumpFile = "$Directory\$env:COMPUTERNAME-$Date-$Time.$Extension"

    Write-Output "Launching DumpIt.exe..."

    .\DumpIt.exe /quiet $Compression /output $DumpFile

    $DumpFile
}

Function Send-ComaeDumpFile(
    [Parameter(Mandatory = $True)] [string] $Key, # Returned by Get-ComaeAPIKey
    [Parameter(Mandatory = $True)] [string] $Path,
    [Parameter(Mandatory = $True)] [string] $ItemType,
    [Parameter(Mandatory = $False)] [switch] $IsCompress
    )
{

    if ($ItemType -eq "Directory") {
        if ((Test-Path  '.\DumpIt.exe') -ne $True) {
          Write-Error "This script needs to be in the same directory as  '.\DumpIt.exe' script."
            Return 1
       }
        $Directory = $Path

        if ((Test-Path $Directory) -ne $True) {

            New-Item $Directory -ItemType "Directory"
        }

        $DateTime = Get-Date

        $Date = [String]::Format("{0}-{1:00}-{2:00}", $DateTime.Year, $DateTime.Month, $DateTime.Day)
        $Time = [String]::Format("{0:00}-{1:00}-{2:00}", $DateTime.Hour, $DateTime.Minute, $DateTime.Second)

        if ($IsCompress) {

            $Extension = "zdmp"
            $Compression = "/compress"
        }
        else {

            $Extension = "dmp"
            $Compression = ""
        }

        $DumpFile = "$Directory\$env:COMPUTERNAME-$Date-$Time.$Extension"

        Write-Output "Launching DumpIt.exe..."

        .\DumpIt.exe /quiet $Compression /output $DumpFile
    }
    elseif ($ItemType -eq "File") {

        $DumpFile = $Path
    }
    else {

        Write-Error "Please provide -ItemType parameter as Directory or File."

        Return 1
    }

    if ((Test-Path $DumpFile) -ne $True) {

        Write-Error "Could not find dump file '$DumpFile'"

        Return 1
    }

# This does not work if the file is bigger than 2GB.
#     if (($PSVersionTable.PSVersion.Major -ge 5) -and (!$IsCompress)) {
#
#         $ArchiveFile = $DumpFile + ".zip"
#
#         Compress-Archive -LiteralPath $DumpFile -DestinationPath $ArchiveFile
#
#         if ((Test-Path $ArchiveFile) -eq $True) {
#
#             $DumpFile = $ArchiveFile
#         }
#     }

    $1MB = 1024 * 1024

    $BufferSize = 32 * $1MB

    $Buffer = New-Object byte[] $BufferSize

    $FileSizeInBytes = (Get-Item $DumpFile).Length

    $FileSizeInMB = [Math]::Round($FileSizeInBytes / $1MB)

    $CurrentInBytes = 0

    $ChunkNumber = 1

    $NumberOfChunks = [Math]::Truncate($FileSizeInBytes / $BufferSize)

    if ($FileSizeInBytes % $BufferSize) {

        $NumberOfChunks += 1
    }

    $FileName = Split-Path $DumpFile -Leaf

    $UniqueFileId = "$FileSizeInBytes-$FileName"

    $Boundary = "---powershellOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZ"

    $Headers = @{
        "Authorization" = "Bearer " + $Key;
        "Content-Type" = "multipart/form-data; boundary=$Boundary";
        "Accept" = "*/*";
        "Accept-Encoding" = "gzip, deflate, br";
        "pragma" = "no-cache";
        "cache-control" = "no-cache"
    }

$BodyTemplate = @"
--$Boundary
Content-Disposition: form-data; name="filename"

$FileName
--$Boundary
Content-Disposition: form-data; name=`"file`"; filename=`"$FileName`"
Content-Type: application/octet-stream

{0}
--$Boundary--
`r`n
"@

    $GetEncoding = [System.Text.Encoding]::GetEncoding("iso-8859-1")

    $FileStream = [System.IO.File]::OpenRead($DumpFile)

    while ($BytesRead = $FileStream.Read($Buffer, 0, $BufferSize)) {

        $Content = $GetEncoding.GetString($Buffer, 0, $BytesRead)

        $Body = $BodyTemplate -f $Content

        $Uri = "https://" + $hostname + "/v1/upload/dump/chunks?chunkSize=$BytesRead&chunk=$ChunkNumber&id=$UniqueFileId&filename=$FileName&chunks=$NumberOfChunks"

        try {

            Invoke-WebRequest -Uri $Uri -Method Get -Headers $Headers -TimeoutSec 86400 -UseBasicParsing
        }
        catch [System.Net.WebException] {

            do {

                $Response = Invoke-WebRequest -Uri $Uri -Method Post -Body $Body -Headers $Headers -TimeoutSec 86400 -UseBasicParsing

            } while ($Response.StatusCode -ne 200)
        }

        $CurrentInBytes += $BytesRead

        $CurrentInMB = [Math]::Round($CurrentInBytes / $1MB)

        $ChunkNumber += 1

        Write-Progress -Activity "Uploading $DumpFile..." -Status "$CurrentInMB MB / $FileSizeInMB MB" -PercentComplete (($CurrentInBytes / $FileSizeInBytes) * 100)
    }

    $Uri = "https://" + $hostname + "/v1/upload/dump/completed"

    $Body = @{
        "id" = "$UniqueFileId";
        "filename" = "$FileName";
        "chunks" = $NumberOfChunks
    }

    $Headers = @{
        "Authorization" = "Bearer " + $Key;
        "Content-Type" = "application/json; charset=utf-8";
        "Accept" = "*/*";
        "Accept-Encoding" = "gzip, deflate, br";
        "pragma" = "no-cache";
        "cache-control" = "no-cache"
    }

    $Body = $Body | ConvertTo-Json

    $Response = Invoke-WebRequest -Uri $Uri -Method Post -Body $Body -Headers $Headers -TimeoutSec 86400 -UseBasicParsing

    $FileStream.Close()

    $DumpFile
}

Function Convert-DumpFileToSnapshot(
    [Parameter(Mandatory = $True)] [string] $FilePath,
    [Parameter(Mandatory = $True)] [string] $Directory,
    [Parameter(Mandatory = $False)] [string] $SymbolPath,
    [Parameter(Mandatory = $False)] [string] $SymbolServer
    )
{
    if ((Test-Path  '.\Z2Dmp.exe') -ne $True) {
        Write-Error "This script needs to be in the same directory as '.\Z2Dmp.exe'."
        Return 1
    }

    if ((Test-Path  '.\Dmp2Json.exe') -ne $True) {
        Write-Error "This script needs to be in the same directory as '.\Dmp2Json.exe'."
        Return 1
    }

    if ((Test-Path $FilePath) -ne $True) {

        Write-Error "Could not find dump file '$FilePath'"

        Return 1
    }

    if ((Test-Path $Directory) -ne $True) {

        Write-Error "Could not find directory '$Directory'"

        Return 1
    }

    if (!$SymbolPath) {

        $SymbolPath = "C:\Symbols"
    }

    if (!$SymbolServer) {

        $SymbolServer = "https://msdl.microsoft.com/download/symbols"
    }

    $FileName = (Get-Item $FilePath).BaseName
    $Extension = (Get-Item $FilePath).Extension

    if ($Extension -eq ".zdmp") {

        $DecompressedDumpFile = (Split-Path $FilePath) + "\" + "$FileName.dmp"

        Write-Output "Launching Z2Dmp.exe..."

        .\Z2Dmp.exe $FilePath $DecompressedDumpFile

        $FilePath = $DecompressedDumpFile
    }

    $DateTime = Get-Date

    $Date = [String]::Format("{0}-{1:00}-{2:00}", $DateTime.Year, $DateTime.Month, $DateTime.Day)
    $Time = [String]::Format("{0:00}-{1:00}-{2:00}", $DateTime.Hour, $DateTime.Minute, $DateTime.Second)

    $SnapshotDirectory = "$Directory\$FileName-$Date-$Time"

    Write-Output "Launching Dmp2Json.exe..."

    .\Dmp2Json.exe /Y srv*$SymbolPath*$SymbolServer /Z $FilePath /C "/all /archive /snapshot $SnapshotDirectory"
}

Function Invoke-ComaeAzVMWinAnalyze(
    [Parameter(Mandatory = $True)] [string] $ClientId,
    [Parameter(Mandatory = $True)] [string] $ClientSecret,
    [Parameter(Mandatory = $True)] [string] $ResourceGroupName,
    [Parameter(Mandatory = $True)] [string] $VMName
) {
    $Token = Get-ComaeAPIKey -ClientId $ClientId -ClientSecret $ClientSecret

    if ((Test-Path  '.\ComaeRespond.ps1') -ne $True) {
        Write-Error "This script needs to be in the same directory as '.\ComaeRespond.ps1'."
        Return $False
    }

    if (!(Get-Module -ListAvailable -Name Az.Compute)) {
        Write-Error "You need to install Azure PowerShell Az module. (Install-Module -Name Az -AllowClobber)"
        Return $False
    }

    if ((Get-AzContext) -eq $null) { Connect-AzAccount }
    Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -Name $VMName -CommandId 'RunPowerShellScript' -ScriptPath '.\ComaeRespond.ps1' -Parameter @{Token=$Token}
}

Function Invoke-ComaeAzVMLinAnalyze(
    [Parameter(Mandatory = $True)] [string] $ClientId,
    [Parameter(Mandatory = $True)] [string] $ClientSecret,
    [Parameter(Mandatory = $True)] [string] $ResourceGroupName,
    [Parameter(Mandatory = $True)] [string] $VMName
) {
    Write-Error "This current cmdlet is not implemented yet."
    # if ((Test-Path  '.\ComaeRespond.sh') -ne $True) {
    # 	Write-Error "This script needs to be in the same directory as '.\ComaeRespond.sh'."
    #     Return 1
    # }

    # az vm run-command invoke -g myResourceGroup -n myVm --command-id RunShellScript --scripts "sudo apt-get update && sudo apt-get install -y nginx"
    # if ((Get-AzContext) -eq $null) { Connect-AzAccount }
    # Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -Name $VMName -CommandId 'RunShellScript' -ScriptPath '.\ComaeAzureIR.sh' -Parameter @{ClientId = $ClientId; ClientSecret = $ClientSecret}
}

Function Invoke-ComaeAwsVMWinAnalyze(
    [Parameter(Mandatory = $True)] [string] $ClientId,
    [Parameter(Mandatory = $True)] [string] $ClientSecret,
    [Parameter(Mandatory = $False)] [string] $AccessKey = $null,
    [Parameter(Mandatory = $False)] [string] $SecretKey = $null,
    [Parameter(Mandatory = $True)] [string] $Region,
    [Parameter(Mandatory = $True)] [string] $InstanceId
) {
    if ((Test-Path  '.\ComaeRespond.ps1') -ne $True) {
        Write-Error "This script needs to be in the same directory as '.\ComaeRespond.ps1'."
        Return 1
    }

    if (!(Get-Module -ListAvailable -Name AWSPowerShell.NetCore)) {
        Write-Error "You need to install AWS Tools for PowerShell. (Install-Module -Name AWSPowerShell.NetCore -AllowClobber)"
        Return $False
    }

    if ((Get-AWSCredentials -ProfileName default) -eq $null) {
	    if ([string]::IsNullOrEmpty($AccessKey) -or [string]::IsNullOrEmpty($SecretKey)) {
	       Write-Error "You need to log in to your AWS account. Use -AccessKey and -SecretKey"
	       Return $False
	    }
	    else
	    {
	    	Set-AWSCredentials –AccessKey $AccessKey –SecretKey $SecretKey
	    }
    }

    Set-DefaultAWSRegion -Region $Region

    $Token = Get-ComaeAPIKey -ClientId $ClientId -ClientSecret $ClientSecret

    # Create a copy of ComaeRespond.ps1 on the remote machine's Temp folder.
    $content = Get-Content .\ComaeRespond.ps1 -Raw
    $b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
    $Parameter = @{'commands'=@("`$encoded = '$b64'",
                                '$content = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encoded))',
                                '$tmpPath = [System.IO.Path]::GetTempPath()',
                                '$tmpFileName = "comae" + $(Get-Date -Format yyyy-MM-dd) + ".ps1"'
                                '$tmpFile = $tmpPath + $tmpFileName',
                                '$content | Out-File $tmpFile -Force',
                                'Write-Host "Tmp file at: $tmpFile"',
                                'Set-Location $tmpPath',
                                "& `$tmpFile -Token '$Token'")}
    try{
        $SSMCommand = Send-SSMCommand -InstanceId $InstanceId -DocumentName AWS-RunPowerShellScript -Comment 'Cloud Incident Response with Comae' -Parameter $Parameter
    } catch {
        if ($_.FullyQualifiedErrorId -like "*Amazon.SimpleSystemsManagement.Model.InvalidInstanceIdException*") {
            Write-Error "Invalid Instance ID, does the AMI have a version of the EC2 config service installed which is compatible with SSM?"
            return
        }

        Write-Error $_.exception.message
    }

    Get-SSMCommandInvocation -CommandId $SSMCommand.CommandId -Details $true | Select-Object -ExpandProperty CommandPlugins
}

Function Invoke-ComaeAwsVMLinAnalyze(
    [Parameter(Mandatory = $True)] [string] $ClientId,
    [Parameter(Mandatory = $True)] [string] $ClientSecret,
    [Parameter(Mandatory = $False)] [string] $AccessKey,
    [Parameter(Mandatory = $False)] [string] $SecretKey,
    [Parameter(Mandatory = $True)] [string] $Region,
    [Parameter(Mandatory = $True)] [string] $InstanceId
) {
    Write-Error "This current cmdlet is not implemented yet."
}

Function Invoke-ComaeADWinAnalyze(
    [Parameter(Mandatory = $True)] [string] $Token
) {
    Write-Error "This current cmdlet is not implemented yet."

    if ((Test-Path  '.\ComaeRespond.ps1') -ne $True) {
        Write-Error "This script needs to be in the same directory as '.\ComaeRespond.ps1'."
        Return 1
    }

    $clientArgs = ($Token)
    if (Test-Connection -ComputerName $ComputerName -Quiet) {
        Invoke-Command -ComputerName $ComputerName -FilePath .\ComaeRespond.ps1 -ArgumentList $clientArgs
    } else {
        Write-Error "Invoke-Command can not be used on the remote machine."
    }
}
