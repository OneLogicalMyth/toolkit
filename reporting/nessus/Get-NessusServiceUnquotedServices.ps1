Function Get-NessusServiceUnquotedServices
{
param($NessusFile)

    begin
    {
        $XML = New-Object XML
        $XML.Load((Convert-Path $NessusFile))

        # Microsoft Windows Unquoted Service Path Enumeration - PluginID 63155
        $ServicePath = $XML.SelectNodes('//ReportItem[@pluginID="63155"]')

    }

    process
    {
        foreach($Issue in $ServicePath)
        {
            $PluginOutput = $Issue.plugin_output -replace ' : ',';' | ConvertFrom-Csv -Delimiter ';' -Header ServiceName,Path | Where-Object { $_.ServiceName -notlike 'Nessus found the following service* with an untrusted path' }
            
            foreach($Service in $PluginOutput)
            {
                $Out = '' | Select-Object Host, 'Service Name', 'Service Path'
                $Out.Host = $Issue.ParentNode.Name
                $Out.'Service Path' = $Service.Path
                $Out.'Service Name' = $Service.ServiceName
                $Out
            }
        }
    }

}
