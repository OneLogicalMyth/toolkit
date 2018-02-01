Function Get-NessusOutdatedLinuxPackage {
param($NessusFile,$ConsolidateCVEAfter=99999)

    begin
    {
        [xml]$NessusXML = Get-Content $NessusFile
        $NessusSoft = $NessusXML.NessusClientData_v2.Report.ReportHost.ReportItem | ?{ $_.'plugin_output' -like '*Installed package*' -and [int]$_.severity -gt 0 }
        if(-not $NessusSoft)
        {
            Write-Warning 'No vuln software found within Nessus file.'
            return
        }
    }
    
    process
    {
        if($NessusSoft)
        {
            $Interim = foreach($Finding in $NessusSoft)
            {
                # regex split on install version and then only ouput if the line starts with a digit (version number)
                $Software = $Finding.'plugin_output' -split "Installed\spackage\s:\s(.*?)`n|Installed\spackage\s:\s(.*?)`n`n" | Where-Object { $_ -match "^\w" }
                foreach($SofItem in $Software)
                {

                    $Out = '' | Select-Object Host, Name, CVE, Installed
                    $Out.Host = $Finding.ParentNode.name
                    
                    # remove the annoying java multiple vulnerabilities
                    if($Finding.pluginName -like 'Ubuntu 14.04 LTS*')
                    {
                        $Out.Name = 'Ubuntu 14.04 LTS'
                    }else{
                        $Out.Name = $Finding.pluginName.Replace(',','')
                    }  

                    $Out.CVE = $Finding.cve
                    $Out.Installed = $SofItem
                    $Out
                }
                Remove-Variable Software
            }
            
            $Interim | Group-Object Host,Name,Installed | Foreach{
                $Item = $_
                $Details = $_.Name -split ', '
                $Out = '' | Select-Object Host, 'Software Name', 'Installed Version', 'CVE Reference'
                $Out.Host = $Details[0]
                $Out.'Software Name' = $Details[1]
                $Out.'Installed Version' = $Details[2]

                # Limit CVEs returned to 1 at the most
                $global:CVEs = ($_.group | Select-Object -ExpandProperty CVE | Sort-Object)
                $CVECount = $CVEs.Count
                if($CVECount -gt $ConsolidateCVEAfter)
                {
                    $Out.'CVE Reference' = "$CVECount CVE references were identified, $($CVEs | Select-Object -First 1) was the oldest."
                }else{
                    $Out.'CVE Reference' = $CVEs -join ','
                }

                $Out
            }
        }
    }
        
}
