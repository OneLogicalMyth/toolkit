Function Get-NessusOutdatedLinuxPackage {
param([string[]]$NessusFile,$ConsolidateCVEAfter=1)
    
    process
    {
        $Interim = foreach($file in $NessusFile)
        {
            [xml]$NessusXML = Get-Content $file
            $NessusSoft = $NessusXML.NessusClientData_v2.Report.ReportHost.ReportItem | ?{ ($_.'plugin_output' -match '(?smi)package\s:\s(.*?)$|installed\s:\s(.*?)$') -and [int]$_.severity -gt 0 }

            foreach($Finding in $NessusSoft)
            {
                $Software = $Finding.'plugin_output' -split '(?smi)package\s:\s(.*?)$|installed\s:\s(.*?)$' | Where-Object { $_ -match "^\w" }
                foreach($SofItem in $Software)
                {

                    $Out = '' | Select-Object Host, Name, CVE, Installed
                    $Out.Host = $Finding.ParentNode.name
                    $Out.Name = $Finding.pluginName.Replace(',','').trim()
                    $Out.CVE = $Finding.cve
                    $Out.Installed = $SofItem
                    $Out
                }
                Remove-Variable Software
            }
        }  

        $Interim | Group-Object Installed | Foreach{
            $Item = $_
            $Out = '' | Select-Object Host, 'Package Installed', 'CVE Reference'
            $Out.Host = ($_.group | Select-Object -ExpandProperty Host -Unique | Sort-Object) -join ','
            $Out.'Package Installed' = $item.Name

            # Limit CVEs returned to 1 at the most
            $CVEs = ($_.group | Select-Object -ExpandProperty CVE -Unique | Sort-Object)
            $CVECount = $CVEs.Count
            if($CVECount -gt $ConsolidateCVEAfter)
            {
                $Out.'CVE Reference' = "$($CVEs | Select-Object -First 1) was the oldest with $CVECount CVE references identified in total."
            }else{
                $Out.'CVE Reference' = $CVEs -join ','
            }

            $Out
        }
        
    }
        
}
