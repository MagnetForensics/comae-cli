Param(

    [Parameter(Mandatory = $True)] [string] $Uri,
    [Parameter(Mandatory = $True)] [string] $Key
)

$DateTime = Get-Date

$Date = [String]::Format("{0}{1:00}{2:00}", $DateTime.Year, $DateTime.Month, $DateTime.Day)
$Time = [String]::Format("{0:00}{1:00}{2:00}", $DateTime.Hour, $DateTime.Minute, $DateTime.Second)

$FileName = "$env:COMPUTERNAME-$Date-$Time.json"

$CurrentDirectory = Convert-Path .

$ZipFilePath = $CurrentDirectory + "\" + "Comae-Toolkit.zip"
$JsonFilePath = $CurrentDirectory + "\" + $FileName

if ((Test-Path $ZipFilePath) -ne $True) {

    Add-Type -assembly "system.io.compression.filesystem"

    Invoke-WebRequest -Uri $Uri -OutFile $ZipFilePath
}

$ToolkitPath = $CurrentDirectory + "\" + "Comae-Toolkit"

if ((Test-Path $ToolkitPath) -ne $True) {

    [io.compression.zipfile]::ExtractToDirectory($ZipFilePath, $CurrentDirectory)
}

if ([environment]::Is64BitOperatingSystem) {

    $ToolkitPath = $ToolkitPath + "\" + "x64"
}
else {

    $ToolkitPath = $ToolkitPath + "\" + "x86"
}

Set-Location -Path $ToolkitPath

Write-Output "Launching DumpIt.exe..."

.\DumpIt.exe /L /A Dmp2Json.exe /C "/Y srv*C:\Symbols*http://msdl.microsoft.com/download/symbols /C \"/zlib /all /json $JsonFilePath""

Set-Location -Path $CurrentDirectory

$FileName = $FileName + ".gz"
$JsonFilePath = $JsonFilePath + ".gz"

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

$BufferSize = (Get-Item $JsonFilePath).Length

if ($BufferSize) {

    $Buffer = [System.IO.File]::ReadAllBytes($JsonFilePath)

    $Content = $GetEncoding.GetString($Buffer, 0, $BufferSize)

    $Body = $BodyTemplate -f $Content

    $Uri = "https://api.comae.io/v1/upload/json"

    Write-Output "Uploading $FileName..."

    do {

        $Response = Invoke-WebRequest -Uri $Uri -Method Post -Body $Body -Headers $Headers -TimeoutSec 86400 -UseBasicParsing

    } while ($Response.StatusCode -ne 200)

    Write-Output "Done."
}
