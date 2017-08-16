Param(

    [Parameter(Mandatory = $True)] [string] $InFile,
    [Parameter(Mandatory = $True)] [string] $Key
)

if ((Test-Path $InFile) -ne $True) {

    Write-Host "Please provides a snapshot to upload to Comae Stardust Platform using -InFile and -Key parameters." -Foregroundcolor Red
    Exit 1
}

if ($PSVersionTable.PSVersion.Major -ge 5) {

    $File = $InFile
    $Archive = $InFile + ".zip"

    Compress-Archive -LiteralPath $File -DestinationPath $Archive

    if ((Test-Path $Archive) -eq $True) {

        $InFile = $Archive
    }
}

$1MB = 1024 * 1024

$BufferSize = 32 * $1MB

$Buffer = New-Object byte[] $BufferSize

$FileSizeInBytes = (Get-Item $InFile).Length

$FileSizeInMB = [math]::Round($FileSizeInBytes / $1MB)

$CurrentInBytes = 0

$ChunkNumber = 1

$NumberOfChunks = [math]::Truncate($FileSizeInBytes / $BufferSize)

if ($FileSizeInBytes % $BufferSize) {

    $NumberOfChunks += 1
}

$FileName = Split-Path $InFile -leaf

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

$FileStream = [System.IO.File]::OpenRead($InFile)

while ($BytesRead = $FileStream.Read($Buffer, 0, $BufferSize)) {

    $Content = $GetEncoding.GetString($Buffer, 0, $BytesRead)

    $Body = $BodyTemplate -f $Content

    $Uri = "https://api.comae.io/v1/upload/dump/chunks?chunkSize=$BytesRead&chunk=$ChunkNumber&id=$UniqueFileId&filename=$FileName&chunks=$NumberOfChunks"

    try {

        Invoke-WebRequest -Uri $Uri -Method Get -Headers $Headers -TimeoutSec 86400 -UseBasicParsing
    }
    catch [System.Net.WebException] {

        do {

            $Response = Invoke-WebRequest -Uri $Uri -Method Post -Body $Body -Headers $Headers -TimeoutSec 86400 -UseBasicParsing

        } while ($Response.StatusCode -ne 200)
    }

    $CurrentInBytes += $BytesRead

    $CurrentInMB = [math]::Round($CurrentInBytes / $1MB)

    $ChunkNumber += 1

    Write-Progress -Activity "Uploading snapshot..." -Status "$CurrentInMB MB / $FileSizeInMB MB" -PercentComplete (($CurrentInBytes / $FileSizeInBytes) * 100)
}

$FileStream.Close()
