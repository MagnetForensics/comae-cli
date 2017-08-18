﻿Function New-ComaeSnapshot(
    [Parameter(Mandatory = $True)] [string] $Directory
    )
{
    if ((Test-Path $Directory) -ne $True) {

        New-Item $Directory -ItemType "Directory"
    }

    $DateTime = Get-Date

    $Date = [String]::Format("{0}-{1:00}-{2:00}", $DateTime.Year, $DateTime.Month, $DateTime.Day)
    $Time = [String]::Format("{0:00}-{1:00}-{2:00}", $DateTime.Hour, $DateTime.Minute, $DateTime.Second)

    $SnapshotDirectory = "$Directory\$env:COMPUTERNAME-$Date-$Time"

    Write-Output "Launching DumpIt.exe..."

    .\DumpIt.exe /L /A Dmp2Json.exe /C "/Y srv*C:\Symbols*http://msdl.microsoft.com/download/symbols /C \"/all /archive /snapshot $SnapshotDirectory""
}

Function Send-ComaeSnapshot(
    [Parameter(Mandatory = $True)] [string] $Key,
    [Parameter(Mandatory = $True)] [string] $Path,
    [Parameter(Mandatory = $True)] [string] $ItemType
    )
{
    if ($ItemType -eq "Directory") {

        $Directory = $Path

        if ((Test-Path $Directory) -ne $True) {

            New-Item $Directory -ItemType "Directory"
        }

        $DateTime = Get-Date

        $Date = [String]::Format("{0}-{1:00}-{2:00}", $DateTime.Year, $DateTime.Month, $DateTime.Day)
        $Time = [String]::Format("{0:00}-{1:00}-{2:00}", $DateTime.Hour, $DateTime.Minute, $DateTime.Second)

        $SnapshotDirectory = "$Directory\$env:COMPUTERNAME-$Date-$Time"

        Write-Output "Launching DumpIt.exe..."

        .\DumpIt.exe /L /A Dmp2Json.exe /C "/Y srv*C:\Symbols*http://msdl.microsoft.com/download/symbols /C \"/all /archive /snapshot $SnapshotDirectory""

        $SnapshotFile = "$Directory\$env:COMPUTERNAME-$Date-$Time.json.zip"
    }
    elseif ($ItemType -eq "File") {

        $SnapshotFile = $Path
    }
    else {

        Write-Host "Please provide -ItemType parameter as Directory or File." -Foregroundcolor Red

        Exit 1
    }

    if ((Test-Path $SnapshotFile) -ne $True) {

        Write-Host "Could not find snapshot file '$SnapshotFile'" -Foregroundcolor Red

        Exit 1
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

        $Uri = "https://api.comae.io/v1/upload/json"

        Write-Output "Uploading $SnapshotFile..."

        do {

            $Response = Invoke-WebRequest -Uri $Uri -Method Post -Body $Body -Headers $Headers -TimeoutSec 86400 -UseBasicParsing

        } while ($Response.StatusCode -ne 200)

        Write-Output "Done."
    }
}

Function New-ComaeDumpFile(
    [Parameter(Mandatory = $True)] [string] $Path
    )
{
    Write-Output "Launching DumpIt.exe..."

    .\DumpIt.exe /quiet /output $Path
}

Function Send-ComaeDumpFile(
    [Parameter(Mandatory = $True)] [string] $Key,
    [Parameter(Mandatory = $True)] [string] $Path,
    [Parameter(Mandatory = $True)] [string] $ItemType
    )
{
    if ($ItemType -eq "Directory") {

        $Directory = $Path

        if ((Test-Path $Directory) -ne $True) {

            New-Item $Directory -ItemType "Directory"
        }

        $DateTime = Get-Date

        $Date = [String]::Format("{0}-{1:00}-{2:00}", $DateTime.Year, $DateTime.Month, $DateTime.Day)
        $Time = [String]::Format("{0:00}-{1:00}-{2:00}", $DateTime.Hour, $DateTime.Minute, $DateTime.Second)

        $DumpFile = "$Directory\$env:COMPUTERNAME-$Date-$Time.dmp"

        Write-Output "Launching DumpIt.exe..."

        .\DumpIt.exe /quiet /output $DumpFile
    }
    elseif ($ItemType -eq "File") {

        $DumpFile = $Path
    }
    else {

        Write-Host "Please provide -ItemType parameter as Directory or File." -Foregroundcolor Red

        Exit 1
    }

    if ((Test-Path $DumpFile) -ne $True) {

        Write-Host "Could not find dump file '$DumpFile'" -Foregroundcolor Red

        Exit 1
    }

    if ($PSVersionTable.PSVersion.Major -ge 5) {

        $ArchiveFile = $DumpFile + ".zip"

        Compress-Archive -LiteralPath $DumpFile -DestinationPath $ArchiveFile

        if ((Test-Path $ArchiveFile) -eq $True) {

            $DumpFile = $ArchiveFile
        }
    }

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

        $CurrentInMB = [Math]::Round($CurrentInBytes / $1MB)

        $ChunkNumber += 1

        Write-Progress -Activity "Uploading $DumpFile..." -Status "$CurrentInMB MB / $FileSizeInMB MB" -PercentComplete (($CurrentInBytes / $FileSizeInBytes) * 100)
    }

    $Uri = "https://api.comae.io/v1/upload/dump/completed"

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
}
