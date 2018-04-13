Function Get-NessusHostList {
param($NessusFile)

    begin
    {
        $NessusXML = New-Object Xml
        $NessusXML.Load((Convert-Path $NessusFile))
    }
    
    process
    {
        foreach($ReportItem in $NessusXML.NessusClientData_v2.Report.ReportHost)
        {
            $Out = '' | Select-Object Host, DNSName, OperatingSystem, Started, Ended
            $Out.Host = $ReportItem.name
            $Out.DNSName = $ReportItem.HostProperties.SelectSingleNode('tag[@name="host-fqdn"]').'#text'
            $Out.Started = $ReportItem.HostProperties.SelectSingleNode('tag[@name="HOST_START"]').'#text'
            $Out.Ended = $ReportItem.HostProperties.SelectSingleNode('tag[@name="HOST_END"]').'#text'

            $Out.OperatingSystem = $ReportItem.HostProperties.SelectSingleNode('tag[@name="operating-system"]').'#text'
            if(-not [System.String]::IsNullOrEmpty($Out.OperatingSystem))
            {
                $Out.OperatingSystem = $Out.OperatingSystem.Trim()
            }

            $Out        
        }
    }
    
}
