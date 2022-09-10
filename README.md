# Comae CLI
## Get Started

In general, follow these steps to start using Comae CLI.

* Get yourself authenticated with [Comae](https://beta.comae.tech).
## PowerShell for Windows
This repository contains a set of PowerShell cmdlets for developers and administrators to develop, deploy and manage Comae Stardust applications.

* For documentation on how to build and deploy applications to Comae please see the [Comae Documentation Center](https://help.comae.tech/).
* For suggesting improvements, join our improvement discussion [#1](https://github.com/comaeio/comae-cli/issues/1).

### Features

* Create
  * Create your dump file `New-ComaeDumpFile`

* Upload
  * Upload your dump file `Send-ComaeDumpFile` to the Comae platform.

* Microsoft Azure / Amazon Aws / Active Directory
  * `Invoke-ComaeAwsVMWinAnalyze`
  * `Invoke-ComaeAzVMWinAnalyze`
  * `Invoke-ComaeADWinAnalyze`

For detail descriptions and examples of the cmdlets, type
* `Get-Help Comae` to get all the cmdlets.
* `Get-Help <cmdlet name>` to get the details of a specific cmdlet.

### Installation

```powershell
    Expand-Archive -Path Comae-Toolkit.zip -Force
    Set-Location -Path  ".\Comae-Toolkit"
    Import-Module .\Comae.psm1
```

### Using Comae PowerShell CLI

#### Memory images / Dump files
```powershell
# Generate the Token from the UI interface of the Comae Platform.
$Token = "XXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# Create a memory image
$DumpFile = New-ComaeDumpFile -Directory $rootDir\Dumps -IsCompress

# Upload a memory image
$DumpFile = New-ComaeDumpFile -Directory $rootDir\Dumps -IsCompress
Send-ComaeDumpFile -Token $Token -Path $DumpFile -ItemType File -Hostname $Hostname -OrganizationId $OrganizationId -CaseId $CaseId
```

### Source Code

1. Download the source code from GitHub repo

### Supported PowerShell Versions

* [Windows Management Framework 3](https://www.microsoft.com/en-us/download/details.aspx?id=34595)
* [Windows Management Framework 4](https://www.microsoft.com/en-us/download/details.aspx?id=40855)
* [Windows Management Framework 5](https://www.microsoft.com/en-us/download/details.aspx?id=50395)

### Find Your Way

You can use the following cmdlet to find out all the cmdlets for your environment

```powershell
# Return all the cmdlets for Comae
Get-Command *Comae*
```

## Contribute Code or Provide Feedback

If you encounter any bugs with the library please file an issue in the [Issues](https://github.com/comaeio/comae-cli/issues) section of the project.

# Learn More

* 👩‍💻 [Comae Resources Center](https://github.com/comaeio/)
* 👩‍💻 Join us via [Magnet IdeaLab](http://magnetidealab.com). ✨✨

---
_Contact [help@comae.com](mailto:help@comae.com) with any additional questions or comments._
