Param(

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
