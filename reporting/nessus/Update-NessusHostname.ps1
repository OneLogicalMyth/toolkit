Function Update-HostName {
param($NessusFile,$OutPath)

    $NessusFile = Get-Item $NessusFile
    [xml]$NessusData = Get-Content $NessusFile.FullName
    $Hosts = $NessusData.SelectNodes('//ReportHost')

    foreach($NHost in $Hosts)
    {
        # obfuscate IP address by staring out first 2 parts *.*.1.1
        $ObIp = $NHost.name -replace '(^\d{1,3}\.\d{1,3})','*.*'
        $Description = ($NessusFile.BaseName -split '_')[0]
        $NHost.name = "$Description ($ObIp)"
    }

    $NewFile = $NessusFile.BaseName + "_modified.nessus"
    $NewPath = Join-Path $NessusFile.Directory $OutPath
    $NewFile = Join-Path $NewPath $NewFile
    $NessusData.Save($NewFile)

}
