Function Get-NessusPluginSummary {
param($NessusFile,[int[]]$PluginFilter)

    begin
    {
        if($PluginFilter -eq 0)
        {
            Write-Warning 'Please give a list of plugin IDs to summarise'
            return
        }

        $XML = New-Object XML
        $XML.Load((Convert-Path $NessusFile))
    }

    process
    {
        foreach($PluginID in $PluginFilter)
        {
            $ReportHosts = $XML.SelectNodes('//ReportHost')
            
            foreach($ReportHost in $ReportHosts)
            {
                $Out = '' | Select-Object ("Host,$($PluginFilter -join ',')" -split ',')
                $Out.Host = $ReportHost.name
                $HasResult = $false

                foreach($id in $PluginFilter)
                {
                    if($ReportHost.SelectSingleNode("ReportItem[@pluginID=`"$id`"]").pluginID -eq $id)
                    {
                        $Out.$id = 'X'
                        $HasResult = $true
                    }else{
                        $Out.$id = $null
                    }
                }
                if($HasResult)
                {
                    $Out
                }                
            }
        }
    }
    
}
