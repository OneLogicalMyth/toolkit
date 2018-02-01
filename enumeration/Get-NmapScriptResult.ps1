param($nmapXML)

[xml]$ScanResults = Get-Content $nmapXML

$ScanResults.SelectNodes('//nmaprun/host/status[@state="up"]') | foreach{

    $HostInfo = $_.ParentNode
    $HostIP = $HostInfo.selectsinglenode('./address[@addrtype="ipv4"]').addr

    $HostInfo.hostscript.script |
    Select-Object @{n='Host';e={$HostIP}},@{n='ScriptName';e={$_.id}},@{n='IsVulnerable';e={$_.output -match 'VULNERABLE'}}

}
