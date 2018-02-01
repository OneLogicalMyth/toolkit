Function Remove-NessusFindings
{
param($NessusFile,[int[]]$PluginsToKeep)

    begin
    {
        $FileDetail = Get-Item -Path $NessusFile
        $SaveFile = ($FileDetail.Directory.FullName) + '\' + ($FileDetail.BaseName) + '_MODIFIED.nessus'

        Write-Progress -Activity 'Removing unwanted Nessus plugin results from hosts' -Status 'Loading Nessus file to memory'

        $XML = New-Object XML
        $XML.Load((Convert-Path $NessusFile))

        # Selects all report items (plugin output)
        $Plugins = $XML.SelectNodes('//ReportItem')

        $TotalToProcess = $Plugins.Count
        $OnePercent = 100 / $TotalToProcess
        $i = 1

    }

    process
    {
        foreach($Plugin in $Plugins)
        {
            if($PluginsToKeep -notcontains [int]$Plugin.pluginID)
            {
                Write-Progress -Activity 'Removing unwanted Nessus plugin results from hosts' -Status "Removing plugin $($Plugin.pluginName) from host $($Plugin.ParentNode.name)" -PercentComplete ($OnePercent * $i)
                $Plugin.ParentNode.RemoveChild($Plugin) | Out-Null
            }

            $i++
        }
    }

    end
    {
        Write-Progress -Activity 'Removing unwanted Nessus plugin results from hosts' -Status 'Saving modified Nessus file'
        $XML.Save($SaveFile)
        Write-Progress -Activity 'Removing unwanted Nessus plugin results from hosts' -Status 'Complete' -Completed
    }

}


