# Comae Stardust PowerShell

This repository contains a set of PowerShell cmdlets for developers and administrators to develop, deploy and manage Comae Stardust applications.

* For documentation on how to build and deploy applications to Comae Stardust please see the [Comae Stardust Documentation Center](https://blog.comae.io/documentation/).
* For comprehensive documentation on the developer cmdlets see [How to install and configure Comae PowerShell](https://blog.comae.io/install-configure-powershell/).
* For comprehensive documentation on the full set of Comae Stardust cmdlets see [Comae Stardust Management Center](https://blog.comae.io).
* For suggesting improvements, join our improvement discussion [#1](https://github.com/comaeio/Stardust-PowerShell/issues/1).

## Features

* Create
  * Create your dump file `New-ComaeDumpFile` or snapshot `New-ComaeSnapshot`.

* Upload
  * Upload your dump file `Send-ComaeDumpFile` or snapshot `Send-ComaeSnapshot` directly to the Comae Stardust platform.

* Create and Upload
  * Create and upload your dump file `Send-ComaeDumpFile` or snapshot `Send-ComaeSnapshot` directly to the Comae Stardust platform.

For detail descriptions and examples of the cmdlets, type
* ```help comae``` to get all the cmdlets.
* ```help <cmdlet name>``` to get the details of a specific cmdlet.

## Installation

```powershell
Import-Module .\Comae.ps1
```

## Using Comae Stardust PowerShell

#### Dump files

```powershell
# Create dump file
New-ComaeDumpFile -Directory "C:\Comae-CrashDumps"
New-ComaeDumpFile -Directory "C:\Comae-CrashDumps" -IsCompress

# Upload dump file
Send-ComaeDumpFile -Key "" -Path "C:\Comae-CrashDumps\FileName.dmp" -ItemType "File"

# Create and upload dump file
Send-ComaeDumpFile -Key "" -Path "C:\Comae-CrashDumps" -ItemType "Directory"
Send-ComaeDumpFile -Key "" -Path "C:\Comae-CrashDumps" -ItemType "Directory" -IsCompress
```

#### Snapshots

```powershell
# Create snapshot
New-ComaeSnapshot -Directory "C:\Comae-Snapshots"

# Upload snapshot
Send-ComaeSnapshot -Key "" -Path "C:\Comae-Snapshots\FileName.json.zip" -ItemType "File"

# Create and upload snapshot
Send-ComaeSnapshot -Key "" -Path "C:\Comae-Snapshots" -ItemType "Directory"

# Convert dump file to snapshot
Convert-DumpFileToSnapshot -FilePath "C:\Comae-CrashDumps\FileName.dmp" -Directory "C:\Comae-Snapshots"
Convert-DumpFileToSnapshot -FilePath "C:\Comae-CrashDumps\FileName.dmp" -Directory "C:\Comae-Snapshots" -SymbolPath "C:\Symbols"
Convert-DumpFileToSnapshot -FilePath "C:\Comae-CrashDumps\FileName.dmp" -Directory "C:\Comae-Snapshots" -SymbolServer "http://msdl.microsoft.com/download/symbols"
Convert-DumpFileToSnapshot -FilePath "C:\Comae-CrashDumps\FileName.dmp" -Directory "C:\Comae-Snapshots" -SymbolPath "C:\Symbols" -SymbolServer "http://msdl.microsoft.com/download/symbols"
```

### Source Code

1. Download the source code from GitHub repo
2. Follow the [Comae PowerShell Developer Guide](https://github.com/comaeio/Stardust-PowerShell/wiki/Stardust-Powershell-Developer-Guide)

### Supported PowerShell Versions

* [Windows Management Framework 3] (https://www.microsoft.com/en-us/download/details.aspx?id=34595)
* [Windows Management Framework 4] (https://www.microsoft.com/en-us/download/details.aspx?id=40855)
* [Windows Management Framework 5] (https://www.microsoft.com/en-us/download/details.aspx?id=50395)

## Get Started

In general, follow these steps to start using Comae Stardust PowerShell

* Get yourself authenticated with [Comae Stardust](https://my.comae.io).
* Use the cmdlets

## Find Your Way


You can use the following cmdlet to find out all the cmdlets for your environment

```powershell
# Return all the cmdlets for Comae
Get-Command *Comae*
```

## Contribute Code or Provide Feedback

If you encounter any bugs with the library please file an issue in the [Issues](https://github.com/comaeio/Stardust-PowerShell/issues) section of the project.

# Learn More

* [Comae Stardust Script Center](https://blog.comae.io/stardust)

---
_Contact [support@comae.io](mailto:support@comae.io) with any additional questions or comments._
