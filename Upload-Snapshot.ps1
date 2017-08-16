Param(

    [Parameter(Mandatory = $True)] [string] $Uri,
    [Parameter(Mandatory = $True)] [string] $Key,
    [Parameter(Mandatory = $True)] [string] $Directory
)

if ((Test-Path $Directory) -ne $True) {

    New-Item $Directory -Type Directory
}

$DateTime = Get-Date

$Date = [String]::Format("{0}-{1:00}-{2:00}", $DateTime.Year, $DateTime.Month, $DateTime.Day)
$Time = [String]::Format("{0:00}-{1:00}-{2:00}", $DateTime.Hour, $DateTime.Minute, $DateTime.Second)

$SnapshotDirectory = "$Directory\$env:COMPUTERNAME-$Date-$Time"

Write-Output "Launching DumpIt.exe..."

.\DumpIt.exe /L /A Dmp2Json.exe /C "/Y srv*C:\Symbols*http://msdl.microsoft.com/download/symbols /C \"/all /archive /snapshot $SnapshotDirectory""

$Boundary = "---powershellOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZ"

$Headers = @{
    "Authorization" = "Bearer " + $Key;
    "Content-Type" = "multipart/form-data; boundary=$Boundary";
    "Accept" = "*/*";
    "Accept-Encoding" = "gzip, deflate, br";
    "pragma" = "no-cache";
    "cache-control" = "no-cache"
}

$FileName = "$env:COMPUTERNAME-$Date-$Time.json.zip"

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

$ArchiveFile = "$Directory\$FileName"

$BufferSize = (Get-Item $ArchiveFile).Length

if ($BufferSize) {

    $Buffer = [System.IO.File]::ReadAllBytes($ArchiveFile)

    $Content = $GetEncoding.GetString($Buffer, 0, $BufferSize)

    $Body = $BodyTemplate -f $Content

    $Uri = "https://api.comae.io/v1/upload/json"

    Write-Output "Uploading $ArchiveFile..."

    do {

        $Response = Invoke-WebRequest -Uri $Uri -Method Post -Body $Body -Headers $Headers -TimeoutSec 86400 -UseBasicParsing

    } while ($Response.StatusCode -ne 200)

    Write-Output "Done."
}
