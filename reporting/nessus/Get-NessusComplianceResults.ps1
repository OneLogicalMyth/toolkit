Function Get-NessusComplianceResults {
param([string[]]$NessusFile)

    $NessusXML = New-Object Xml
    $NessusXML.Load((Convert-Path $NessusFile))

    $ComplianceResults = $NessusXML.SelectNodes('//ReportItem[@pluginFamily="Policy Compliance"]')

    foreach($check in $ComplianceResults)
    {
        if($Check.'compliance-info' -match 'not identified that the chosen audit applies|This audit checks the testable')
        {
            continue
        }

        $Out = '' | Select-Object Hostname, Benchmark, CheckNumber, Check, ValueObtained, ValueRequired, Result
        $Out.Hostname = $check.ParentNode.name
        $Out.Benchmark = $check.'compliance-audit-file'.Replace('_',' ') -replace '.audit'
        $Out.Check = $check.'compliance-check-name'
        $Out.ValueObtained = $check.'compliance-actual-value'
        $Out.ValueRequired = $check.'compliance-policy-value'
        $Out.Result = $check.'compliance-result'

        if($Out.Benchmark -match 'CIS')
        {
            try
            {
                $Out.CheckNumber = [System.Version]($Out.Check.Split(' ')[0])
            }
            catch
            {
                $global:test = $check
            }
        }else{
            $Out.CheckNumber = $null
        }
        
        $Out
    }

}
