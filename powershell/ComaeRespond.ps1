Param (
 [Parameter(Mandatory=$true)][string]$Token,
 [Parameter] [string] $Hostname="api.comae.com"
)

$TempDir = [System.IO.Path]::GetTempPath()
Set-Location $TempDir
Write-Host "Current Directory: " $pwd
if (Test-Path -Path Comae-Toolkit.zip) {
    Remove-Item Comae-Toolkit.zip
}

if (Test-Path -Path Comae-Toolkit) {
    Remove-Item Comae-Toolkit\* -Force -Recurse
}

$postParams = @{token=$Token}
$Uri = "https://" + $Hostname + "/tools/download"
Invoke-WebRequest -Uri $Uri -Method POST -OutFile Comae-Toolkit.zip -Body $postParams

$rootDir = $pwd

if (Test-Path -Path Comae-Toolkit.zip) {
    Expand-Archive -Path Comae-Toolkit.zip

    $arch = "x64"
    if ($env:Processor_Architecture -eq "x86") { $arch = "x86" }
    if ($env:Processor_ArchiteW6432 -eq "ARM64") { $arch = "ARM64" }

    Set-Location -Path  ".\Comae-Toolkit\$arch\"
    . .\Comae.ps1
    Send-ComaeDumpFile -Key $Token -Path $rootDir\Dumps -ItemType Directory -IsCompress -Hostname $Hostname

    Set-Location $rootDir
    # Clean everything.
    Remove-Item $rootDir\Dumps\* -Force -Recurse
    Remove-Item $rootDir\Comae-Toolkit.zip
    Remove-Item $rootDir\Comae-Toolkit\* -Force -Recurse
}