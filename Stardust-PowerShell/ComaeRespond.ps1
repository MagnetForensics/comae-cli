Param (
 [Parameter(Mandatory=$true)]
 [string]$ClientId, 
 [Parameter(Mandatory=$true)]
 [string]$ClientSecret
)

$hostname = "api.comae.io"

$TempDir = [System.IO.Path]::GetTempPath()
Set-Location $TempDir
Write-Host "Current Directory: " $pwd
if (Test-Path -Path Comae-Toolkit.zip) { 
    Remove-Item Comae-Toolkit.zip
}

if (Test-Path -Path Comae-Toolkit) {
    Remove-Item Comae-Toolkit\* -Force -Recurse
}

$token = Get-ComaeAPIKey -ClientId $ClientId -ClientSecret $ClientSecret

$postParams = @{token=$token}
$Uri = "https://" + $hostname + "/tools/download"
Invoke-WebRequest -Uri $Uri -Method POST -OutFile Comae-Toolkit.zip -Body $postParams 

$rootDir = $pwd

if (Test-Path -Path Comae-Toolkit.zip) {
    Expand-Archive -Path Comae-Toolkit.zip

    $arch = "x64"
    if ($env:Processor_Architecture -eq "x86") { $arch = "x86" }

    Set-Location -Path  ".\Comae-Toolkit\$arch\"
    . ($PSScriptRoot + "\Comae-Toolkit\" + $arch + "\Comae.ps1")
    Send-ComaeDumpFile -Key $token -Path $rootDir\Dumps -ItemType Directory -IsCompress

    # Clean everything.
    Remove-Item $rootDir\Dumps\* -Force -Recurse
    Remove-Item $rootDir\Comae-Toolkit.zip
    Remove-Item $rootDir\Comae-Toolkit\* -Force -Recurse
}