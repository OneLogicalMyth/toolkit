Function Get-NessusPluginSummary {
param($NessusFile=$null,[string]$PluginName=$null,[int]$PluginID=$null,[int]$MinimumSeverity=1)

    if(-not $NessusFile)
    {
        Write-Warning 'Please provide a Nessus scan file path.'
        return
    }
        
    
    # Get items that are not informational by default
    [xml]$Nessus = Get-Content $NessusFile
    $ReportItems = $Nessus.SelectNodes('//ReportItem') | Where-Object { $_.severity -ge $MinimumSeverity }

    # If plugin name/id provided filter based on that
    if($PluginName)
    {
        $ReportItems = $ReportItems | Where-Object { $_.pluginName -like $PluginName }
    }
    if($PluginID)
    {
        $ReportItems = $ReportItems | Where-Object { $_.pluginID -like $PluginID }
    }

    # output results
    Foreach($Item in $ReportItems)
    {

        $Out = '' | Select-Object Host, PluginID, PluginName, Protocol, Port, ServiceName, Risk, CVSSBaseScore2, CVSSVector2, CVSSBaseScore3, CVSSVector3, CVSSCVESource, Synopsis, Solution
        $Out.Host = $Item.ParentNode.name
        $Out.PluginID = $Item.pluginID
        $Out.PluginName = $Item.pluginName
        $Out.Protocol = $Item.protocol
        $Out.Port = $Item.port
        $Out.ServiceName = $Item.svc_name
        $Out.Risk = $Item.risk_factor
        $Out.CVSSBaseScore2 = $Item.cvss_base_score
        $Out.CVSSVector2 = $Item.cvss_vector
        $Out.CVSSBaseScore3 = $Item.cvss3_base_score
        $Out.CVSSVector3 = $Item.cvss3_vector
        $Out.Synopsis = $Item.synopsis
        $Out.Solution = $Item.solution
        $Out.CVSSCVESource = $Item.cvss_score_source
        $Out

    }


}
