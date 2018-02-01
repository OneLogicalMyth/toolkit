Function Get-NessusServicePermissions 
{
param($NessusFile)

    begin
    {
        $XML = New-Object XML
        $XML.Load((Convert-Path $NessusFile))

        # Insecure Windows Service Permissions - PluginID 65057
        $ServicePermissions = $XML.SelectNodes('//ReportItem[@pluginID="65057"]')

    }

    process
    {
        foreach($Issue in $ServicePermissions)
        {
            $PluginOutput = $Issue.plugin_output -split "Path :" | Select-Object -Skip 1 | foreach{ "Path :$_".Trim() -replace ' : ',';' }
            
            foreach($Service in $PluginOutput)
            {
                $Service = $Service | ConvertFrom-Csv -Delimiter ';' -Header setting,value

                $Out = '' | Select-Object Host, 'Service Path', 'Service Name', 'File write allowed for groups', 'Full control of directory allowed for groups'
                $Out.Host = $Issue.ParentNode.Name
                $Out.'Service Path' = $Service | Where-Object { $_.setting -eq 'path' } | Select-Object -ExpandProperty value
                $Out.'Service Name' = $Service | Where-Object { $_.setting -eq 'Used by services' } | Select-Object -ExpandProperty value
                $Out.'File write allowed for groups' = $Service | Where-Object { $_.setting -eq 'File write allowed for groups' } | Select-Object -ExpandProperty value
                $Out.'Full control of directory allowed for groups' = $Service | Where-Object { $_.setting -eq 'Full control of directory allowed for groups' } | Select-Object -ExpandProperty value
                $Out
            }
        }
    }

}
