# Comae Module
## Get-ComaeCases
### Synopsis
Get the list of cases the token belongs to.
### Syntax
```powershell
Get-ComaeCases [-Token] <String> [[-OrganizationId] <String>] [[-Hostname] <String>] [<CommonParameters>]
```
### Parameters
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>Token</nobr> |  | Bearer token generated by the user on via the user interface of the Comae platform. | true | false |  |
| <nobr>OrganizationId</nobr> |  | Optional. If this parameter is null or empty, all the cases from all the organization will be returned. | false | false |  |
| <nobr>Hostname</nobr> |  | Default hostname is beta.comae.tech but this can be changed for private instances. | false | false | beta.comae.tech |
### Examples
**EXAMPLE 1**
Get list
```powershell
PS C:\\\> $Cases = Get-ComaeCases -Token $Token
```

## Get-ComaeOrganizations
### Synopsis
Get the list of organizations the token belongs to.
### Syntax
```powershell
Get-ComaeOrganizations [-Token] <String> [[-Hostname] <String>] [<CommonParameters>]
```
### Parameters
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>Token</nobr> |  | Bearer token generated by the user on via the user interface of the Comae platform. | true | false |  |
| <nobr>Hostname</nobr> |  | Default hostname is beta.comae.tech but this can be changed for private instances. | false | false | beta.comae.tech |
### Examples
**EXAMPLE 1**
Get list
```powershell
PS C:\\\> $Organizations = Get-ComaeOrganizations -Token $Token
```

## Get-ComaeToolkitPath
### Synopsis
Return the path to Comae Toolkit executables.
### Syntax
```powershell
Get-ComaeToolkitPath [<CommonParameters>]
```
### Examples
**EXAMPLE 1**
Return value

```powershell
PS C:\\\> Get-ComaeToolkitPath
```
## Invoke-ComaeADWinAnalyze
### Synopsis
Invoke DumpIt on a remote Windows AD instance, and send it to the Comae platform.
### Syntax
```powershell
Invoke-ComaeADWinAnalyze [-Token] <String> [-OrganizationId] <String> [-CaseId] <String> [-ComputerName] <String> 
[[-Hostname] <String>] [<CommonParameters>]
```
### Parameters
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>Token</nobr> |  | Bearer token generated by the user on via the user interface of the Comae platform. | true | false |  |
| <nobr>OrganizationId</nobr> |  | The organization id can be retrieved in the user interface or by calling Get-ComaeOrganizations. | true | false |  |
| <nobr>CaseId</nobr> |  | The case id can be retrieved in the user interface or by calling Get-ComaeCases. | true | false |  |
| <nobr>ComputerName</nobr> |  | The name of the machine in the Active Directory domain. | true | false |  |
| <nobr>Hostname</nobr> |  | Default hostname is beta.comae.tech but this can be changed for private instances. | false | false | beta.comae.tech |
### Examples
**EXAMPLE 1**
Invoke a Active Directory run command with overriding the script 'ComaeRespond.ps1' on a Windows VM machine name '$machinename. 
```powershell 
PS C:\\\> Invoke-ComaeAwsVMWinAnalyze -Token $Token -OrganizationId $OrganizationId -CaseId $CaseId  
-ComputerName $machinename.
```

## Invoke-ComaeAwsVMWinAnalyze
### Synopsis
Invoke DumpIt on a remote Windows Aws Virtual Machine, and send it to the Comae platform.
### Syntax
```powershell
Invoke-ComaeAwsVMWinAnalyze [-Token] <String> [-OrganizationId] <String> [-CaseId] <String> [[-AccessKey] <String>] 
[[-SecretKey] <String>] [-Region] <String> [-InstanceId] <String> [[-Hostname] <String>] [<CommonParameters>]
```
### Parameters
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>Token</nobr> |  | Bearer token generated by the user on via the user interface of the Comae platform. | true | false |  |
| <nobr>OrganizationId</nobr> |  | The organization id can be retrieved in the user interface or by calling Get-ComaeOrganizations. | true | false |  |
| <nobr>CaseId</nobr> |  | The case id can be retrieved in the user interface or by calling Get-ComaeCases. | true | false |  |
| <nobr>AccessKey</nobr> |  | Aws Access Key \(optional\). Only used if Get-AWSCredentials is null. | false | false |  |
| <nobr>SecretKey</nobr> |  | Aws Secret Key \(optional\). Only used if Get-AWSCredentials is null. | false | false |  |
| <nobr>Region</nobr> |  | The region where the Aws virtual machine belongs to. | true | false |  |
| <nobr>InstanceId</nobr> |  | The instance id of the Aws virtual machine. | true | false |  |
| <nobr>Hostname</nobr> |  | Default hostname is beta.comae.tech but this can be changed for private instances. | false | false | beta.comae.tech |
### Examples
**EXAMPLE 1**
Invoke a SSM run command with overriding the script 'ComaeRespond.ps1' on a Windows VM instance id '$instanceid' in region '$region'.  
```powershell
PS C:\\\> Invoke-ComaeAwsVMWinAnalyze -Token $Token -OrganizationId $OrganizationId -CaseId $CaseId  
-Region $region -InstanceId $instanceid
```

## Invoke-ComaeAzVMWinAnalyze
### Synopsis
Invoke DumpIt on a remote Windows Azure Virtual Machine, and send it to the Comae platform.
### Syntax
```powershell
Invoke-ComaeAzVMWinAnalyze [-Token] <String> [-OrganizationId] <String> [-CaseId] <String> [-ResourceGroupName] 
<String> [-VMName] <String> [[-Hostname] <String>] [<CommonParameters>]
```
### Parameters
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>Token</nobr> |  | Bearer token generated by the user on via the user interface of the Comae platform. | true | false |  |
| <nobr>OrganizationId</nobr> |  | The organization id can be retrieved in the user interface or by calling Get-ComaeOrganizations. | true | false |  |
| <nobr>CaseId</nobr> |  | The case id can be retrieved in the user interface or by calling Get-ComaeCases. | true | false |  |
| <nobr>ResourceGroupName</nobr> |  | The resource group name where the Azure virtual machine belongs to. | true | false |  |
| <nobr>VMName</nobr> |  | The name of the Azure virtual machine. | true | false |  |
| <nobr>Hostname</nobr> |  | Default hostname is beta.comae.tech but this can be changed for private instances. | false | false | beta.comae.tech |
### Examples
**EXAMPLE 1**
Invoke a run command 'RunPowerShellScript' with overriding the script 'ComaeRespond.ps1' on a Windows VM named '$VMName' in resource group '$rgname'.  

```powershell
PS C:\\\> Invoke-ComaeAzVMWinAnalyze -Token $Token -OrganizationId $OrganizationId -CaseId $CaseId  
-ResourceGroupName $rgname -VMName $VMName
```

## New-ComaeDumpFile
### Synopsis
Create a full memory Microsoft crash dump.
### Syntax
```powershell
New-ComaeDumpFile [-Directory] <String> [-IsCompress] [<CommonParameters>]
```
### Parameters
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>Directory</nobr> |  | Destination folder for the output file. | true | false |  |
| <nobr>IsCompress</nobr> |  | Enables compression for the output file. Useful for large memory images. Memory images can be uncompressed using z2dmp available in the toolkit, but also on GitHub as an opensource software in Rust \(https://github.com/comaeio/z2dmp-rust/\) and C \(https://github.com/comaeio/z2dmp/\) | false | false | False |
### Examples
**EXAMPLE 1**
Creates a compressed memory image into the given target folder.
```powershell
PS C:\\\> New-ComaeDumpFile -Directory C:\\Dumps -IsCompress
```
## Send-ComaeDumpFile
### Synopsis
Send a memory file to the Comae Platform.
### Syntax
```powershell
Send-ComaeDumpFile [-Token] <String> [-Path] <String> [-ItemType] <String> [-OrganizationId] <String> [-CaseId] 
<String> [[-Hostname] <String>] [<CommonParameters>]
```
### Parameters
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>Token</nobr> |  | Bearer token generated by the user on via the user interface of the Comae platform. | true | false |  |
| <nobr>Path</nobr> |  | Path to memory image generated by DumpIt. | true | false |  |
| <nobr>ItemType</nobr> |  | File \(default\). | true | false | File |
| <nobr>OrganizationId</nobr> |  | The organization id can be retrieved in the user interface or by calling Get-ComaeOrganizations. | true | false |  |
| <nobr>CaseId</nobr> |  | The case id can be retrieved in the user interface or by calling Get-ComaeCases. | true | false |  |
| <nobr>Hostname</nobr> |  | Default hostname is beta.comae.tech but this can be changed for private instances. | false | false | beta.comae.tech |
### Examples
**EXAMPLE 1**
Send a memory image to a custom Comae endpoint.

```powershell
PS C:\\\> Send-ComaeDumpFile -Hostname $Hostname -Token $Token -ItemType File  
-OrganizationId $OrganizationId -CaseId $CaseId -Path $FileDump
```

## Send-ComaeSnapshotFile
### Synopsis
Send a memory snapshot archive to the Comae Platform.
### Syntax
```powershell
Send-ComaeSnapshotFile [-Token] <String> [-Path] <String> [-ItemType] <String> [-OrganizationId] <String> [-CaseId] 
<String> [[-Hostname] <String>] [<CommonParameters>]
```
### Parameters
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>Token</nobr> |  | Bearer token generated by the user on via the user interface of the Comae platform. | true | false |  |
| <nobr>Path</nobr> |  | Path to memory image generated by DumpIt. | true | false |  |
| <nobr>OrganizationId</nobr> |  | The organization id can be retrieved in the user interface or by calling Get-ComaeOrganizations. | true | false |  |
| <nobr>CaseId</nobr> |  | The case id can be retrieved in the user interface or by calling Get-ComaeCases. | true | false |  |
| <nobr>Hostname</nobr> |  | Default hostname is beta.comae.tech but this can be changed for private instances. | false | false | beta.comae.tech |
### Examples
**EXAMPLE 1**
Send a memory snapshot archive to a custom Comae endpoint.

```powershell
PS C:\\\> Send-Send-ComaeSnapshotFile -Hostname $Hostname -Token $Token 
-OrganizationId $OrganizationId -CaseId $CaseId -Path $FileDump
```