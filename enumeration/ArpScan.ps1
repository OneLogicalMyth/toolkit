
$range = 1..254
$subnet = '192.168.1'

# Ping the local subnet
$null = 1..254 | %{
    Get-WmiObject -Class Win32_PingStatus -Filter "Address=`"$($subnet).$_`" and timeout=300"
} | ?{ $_.ResponseTime }

# parse the arp table on the local machine to see what valid addresses were found
arp -a  | Select-String '(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})' -AllMatches | %{ $_.matches } | Select-Object -ExpandProperty Value | ?{ $_ -like "$subnet.*" }
