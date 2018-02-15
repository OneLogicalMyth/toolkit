Function Get-CVEDescription {
param($CVE)

    $Info = Invoke-WebRequest "https://cve.mitre.org/cgi-bin/cvename.cgi?name=$CVE"
    $null = $Info.Content -match '(?smi)<th colspan="2">Description</th>.*?<td colspan="2">(.*?)</td>'
    $Description = $Matches.1
    $Description = $Description.Trim()

    Write-Output "__$($CVE)__"
    Write-Output "$($Description -replace "`n")"

}
