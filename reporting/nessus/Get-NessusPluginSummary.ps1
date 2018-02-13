Function Get-NessusPluginSummary {
param($NessusFile=$null,[int]$PluginName=$null,[int]$PluginID=$null,[int]$MinimumSeverity=1)

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

        $Out = '' | Select-Object Host, PluginID, PluginName, Protocol, Port, ServiceName
        $Out.Host = $Item.ParentNode.name
        $Out.PluginID = $Item.pluginID
        $Out.PluginName = $Item.pluginName
        $Out.Protocol = $Item.protocol
        $Out.Port = $Item.port
        $Out.ServiceName = $Item.svc_name
        $Out

    }


}
