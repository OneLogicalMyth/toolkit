Function Export-FWRules {
  $Output = @(netsh advfirewall firewall show rule name=all)

  $Object = New-Object -Type PSObject

  $Output | Where {$_ -match '^([^:]+):\s*(\S.*)$' } | Foreach -Begin {
  $FirstRun = $true
  $HashProps = @{}
  } -Process {
  if (($Matches[1] -eq 'Rule Name') -and (!($FirstRun))) {
  New-Object -TypeName PSCustomObject -Property $HashProps

  $HashProps = @{}
  } $HashProps.$($Matches[1]) = $Matches[2]
  $FirstRun = $false
  } -End {
  New-Object -TypeName PSCustomObject -Property $HashProps}
}
