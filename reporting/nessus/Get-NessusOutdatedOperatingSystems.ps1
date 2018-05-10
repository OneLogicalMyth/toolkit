Function Sort-IPv4Address {
param($Object,$SortProperty)

    $1 = { if ($_.$SortProperty -match '^(\d{1,3})\.\d{1,3}\.\d{1,3}\.\d{1,3}$') { [int]$matches[1] } }
    $2 = { if ($_.$SortProperty -match '^\d{1,3}\.(\d{1,3})\.\d{1,3}\.\d{1,3}$') { [int]$matches[1] } }
    $3 = { if ($_.$SortProperty -match '^\d{1,3}\.\d{1,3}\.(\d{1,3})\.\d{1,3}$') { [int]$matches[1] } }
    $4 = { if ($_.$SortProperty -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.(\d{1,3})$') { [int]$matches[1] } }

    # sort it by 3 expressions
    $Object | Sort-Object $1, $2, $3, $4


}

Function Get-NessusOutdatedOperatingSystems {
param($NessusFile=$null)

    # Filter on outdated operating system plugins
    # 108797  - Unsupported Windows OS
    # 84729   - Microsoft Windows Server 2003 Unsupported Installation Detection
    # 33850   - Unix Operating System Unsupported Version Detection
    [xml]$Nessus = Get-Content $NessusFile
    $ReportItems = $Nessus.SelectNodes('//ReportItem') | Where-Object { $_.pluginID -in (108797,84729,33850) }

    $Result = Foreach($Item in $ReportItems)
    {
        $Out = '' | Select-Object Host, 'Operating System'
        $Out.Host = $Item.ParentNode.Name
        $Out.'Operating System' = ($Item.ParentNode.hostproperties.tag | ?{$_.name -eq 'operating-system' }).'#text' -replace "`n",', '
        $Out
    } 
    $Result = $Result | Select-Object -Property * -Unique
    Sort-IPAddress -Object $Result -SortProperty Host

}
