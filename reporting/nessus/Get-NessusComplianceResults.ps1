Function Get-NessusComplianceResults {
param($NessusFile)

    $NessusXML = New-Object Xml
    $NessusXML.Load((Convert-Path $NessusFile))

    $ComplianceResults = $NessusXML.SelectNodes('//ReportItem[@pluginFamily="Policy Compliance"]')

    foreach($check in $ComplianceResults)
    {

        $Out = '' | Select-Object Hostname, Benchmark, Check, ValueObtained, ValueRequired, Result
        $Out.Hostname = $check.ParentNode.name
        $Out.Benchmark = $check.'compliance-audit-file'.Replace('_',' ') -replace '.audit'
        $Out.Check = $check.'compliance-check-name'
        $Out.ValueObtained = $check.'compliance-actual-value'
        $Out.ValueRequired = $check.'compliance-policy-value'
        $Out.Result = $check.'compliance-result'
        $Out
    }

}
