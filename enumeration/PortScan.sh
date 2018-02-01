echo "#######################################################################"
echo "## PortScan.sh by Liam Glanfield - https://github.com/onelogicalmyth ##"
echo "#######################################################################"

# configuration
nuser="liam"
npass="password"

if [ ! -f ValidIPs.txt ];then echo "[x] A file called ValidIPs.txt is not present, now exiting"; exit; fi

########################################################
# Create directories for storing host results and misc #
########################################################
echo "[*] Creating a directory for each valid IP"
for h in `cat ValidIPs.txt`; do mkdir $h;done

echo "[*] Starting postgresql service for Metasploit imports"
service postgresql start
echo "[*] Starting nessusd service for Nessus scanning"
service nessusd start

##############################################
# Inital Port Scans Top 1000 TCP and Top 100 #
##############################################

# Top 1000 TCP port scan
echo "[-] Performing a top 1000 TCP port scan against all hosts listed in ValidIPs.txt"
nmap -sT -T4 -Pn -iL ValidIPs.txt -oA InitalScanTCP > /dev/null
echo "[+] Top 1000 TCP port scan against all hosts listed in ValidIPs.txt has completed"
echo "[*] Exporting open TCP ports per host and saving to ./HOST/InitalOpenPortsTCP.txt"
for h in `cat ValidIPs.txt`;do ports=$(cat InitalScanTCP.gnmap | cut -d':' -f2,3 | grep open | grep $h | cut -d':' -f2 | grep -E -o "[0-9]{1,6}/open" | grep -E -o "[0-9]{1,6}" | sort -n -u | tr '\n' ',');if [ -n "$ports" ]; then echo ${ports:0:-1} > ./$h/InitalOpenPortsTCP.txt; fi;ports=""; done
echo "[-] Performing a targetted version scan against each host with open ports within the top 1000 range"
for h in `cat ValidIPs.txt`; do if [ -f ./$h/InitalOpenPortsTCP.txt ]; then hports=$(cat ./$h/InitalOpenPortsTCP.txt); fi; if [ -n "$hports" ]; then echo "[*] Host $h has $hports open"; nmap -vv -sTV -A -T4 --version-intensity 9 -p$hports -oA ./$h/DetailedScan $h > /dev/null; fi;hports=""; done
echo "[+] Targetted version scanning has completed"
echo "[*] Outputting inital top 1000 TCP open port summary to InitalPortSummaryTCP.txt"
cat InitalScanTCP.gnmap | awk '/\/open/ {print $2;system("cat InitalScanTCP.gnmap | grep " $2 "| grep -E -o \"[0-9]{1,6}/open\"")}' > InitalPortSummaryTCP.txt

# Top 100 UDP port scan
echo "[*] Performing a top 100 UDP port scan against all hosts listedin ValidIPs.txt"
nmap -sU -T4 -F -Pn -iL ValidIPs.txt -oA InitalScanUDP > /dev/null
echo "[+] Top 100 UDP port scan against all hosts listed in ValidIPs.txt has completed"
echo "[*] Exporting open UDP ports per host and saving to ./HOST/InitalOpenPortsUDP.txt"
for h in `cat ValidIPs.txt`;do ports=$(cat InitalScanUDP.gnmap | cut -d':' -f2,3 | grep open | grep $h | cut -d':' -f2 | grep -E -o "[0-9]{1,6}/open/udp" | grep -E -o "[0-9]{1,6}" | sort -n -u | tr '\n' ',');if [ -n "$ports" ]; then echo ${ports:0:-1} > ./$h/InitalOpenPortsUDP.txt;ports=""; fi; done
echo "[*] Outputting inital top 100 UDP open port summary to InitalPortSummaryUDP.txt"
cat InitalScanUDP.gnmap | awk '/\/open/ {print $2;system("cat InitalScanUDP.gnmap | grep " $2 "| grep -E -o \"[0-9]{1,6}/open/udp\"")}' > InitalPortSummaryUDP.txt


###########################
# Full TCP Scan to Finish #
###########################
echo "[-] Performing an all port TCP scan against all hosts listed in ValidIPs.txt"
nmap -sT -T4 -Pn -p0- -iL ValidIPs.txt -oA FullTCPScan > /dev/null
ports=$(cat FullTCPScan.gnmap | grep -E -o "[0-9]{1,6}/open" | cut -d'/' -f1 | sort -n -u | tr '\n' ',')
ports=${ports:0:-1}
echo "[+] All port TCP scan against all hosts listed in ValidIPs.txt has completed"
echo "[*] Exporting the FullPortSummaryTCP.txt"
cat FullTCPScan.gnmap | awk '/\/open/ {print $2;system("cat FullTCPScan.gnmap | grep " $2 "| grep -E -o \"[0-9]{1,6}/open\"")}' > FullPortSummaryTCP.txt
echo "[-] Performing an all TCP version scan against all hosts with open ports"
cat FullTCPScan.gnmap | grep -E "[0-9]{1,6}/open" | cut -d' ' -f2 > HostsWithTCPPortsOpen.txt
nmap -vv -sTV -A -T4 --version-intensity 9 -p$(echo $ports) -iL HostsWithTCPPortsOpen.txt -oA DetailedScan > /dev/null
echo "[+] All port TCP version scan completed"
echo "[*] Importing nmap TCP to Metasploit"
msfconsole -q -x "db_import DetailedScan.xml;exit"
echo "[*] Importing nmap UDP to Metasploit"
msfconsole -q -x "db_import InitalScanUDP.xml;exit"


###############################
# Weak Service Configurations #
###############################

# mysqldump
mysql=$(grep -E "[0-9]{1,6}/open/tcp//mysql/" FullTCPScan.gnmap | cut -d' ' -f2)
if [ -n "$mysql" ]; then
	echo "[*] MySQL/Maria service has been detected trying default creds mysqldump"
	for s in $mysql; do
	    echo "Attempting mysqldump on host $s"
	    mysqldump -u root -h $s -A > ./$s/mysqldump.txt
	done
fi

# smbclient 
smbclient=$(grep -E "[0-9]{1,6}/open/tcp//netbios-ssn/.*[0-9]{1,6}/open/tcp//microsoft-ds/" FullTCPScan.gnmap | cut -d' ' -f2)
if [ -n "$smbclient" ]; then
	echo "[*] A Windows host with NetBIOS and SMB ports open has been detected attempting smbclient and enum4linux"
	for s in $smbclient; do
	    echo "[*] Attempting smbclient using NULL against host $s to list shares"
	    smbclient -U "" -L $s -N 2>/dev/null > ./$s/smbclient_null_shares.txt
	    if [ "NT_STATUS_ACCESS_DENIED" = $(grep -E -o "NT_STATUS_ACCESS_DENIED" ./$s/smbclient_null_shares.txt) ]; then echo "[-] NULL login is disabled for $s"; else echo "[?] Guest login might be enabled or a time out for $s"; fi
	    echo "[*] Attempting smbclient using Guest against host $s to list shares"
	    smbclient -U "Guest"%"" -L $s 2>/dev/null > ./$s/smbclient_guest_shares.txt
	    if [ "NT_STATUS_ACCOUNT_DISABLED" = $(grep -E -o "NT_STATUS_ACCOUNT_DISABLED" ./$s/smbclient_guest_shares.txt) ]; then echo "[-] Guest login is disabled for $s"; else echo "[?] Guest login might be enabled or a time out for $s"; fi
	done
fi

# snmp 
snmp=$(grep -E "[0-9]{1,6}/open/udp//snmp/" InitalScanUDP.gnmap | cut -d' ' -f2)
if [ -n "$snmp" ]; then
	echo "[*] SNMP has been detected attempting snmp-check versions 1 and 2c"
	for s in $snmp; do
	    echo "[*] Attempting snmp-check version 1 against host $s"
	    snmp-check -v1 -c public $s 2>/dev/null > ./$s/snmp-check_v1.txt
	    line=$(cat ./$s/snmp-check_v1.txt | grep "Routing information:" -n | cut -d':' -f1)
	    line=$(expr $line + 3)
        for n in $(cat ./$s/snmp-check_v1.txt | tail -n +$line | head -n -1 | sed 's/\s\s//g;s/ 0\.0\.0\.0 /\//;s/ 0//' | grep -E "^[0-9]"); do echo "[+] Network route identified on $s as $n"; done
	    echo "[*] Attempting snmp-check version 2c against host $s"
	    snmp-check -v2c -c public $s 2>/dev/null > ./$s/snmp-check_v2c.txt
        line=$(cat ./$s/snmp-check_v2c.txt | grep "Routing information:" -n | cut -d':' -f1)
	    line=$(expr $line + 3)
        for n in $(cat ./$s/snmp-check_v2c.txt | tail -n +$line | head -n -1 | sed 's/\s\s//g;s/ 0\.0\.0\.0 /\//;s/ 0//' | grep -E "^[0-9]"); do echo "[+] Network route identified on $s as $n"; done
	done
fi

# finish with a Nessus
echo "[*] Starting a Nessus scan against all identified hosts"
echo "[+] Nessus scan started - $(python /opt/toolkit/enumeration/NessusFrom-nmapXML.py -u liam -p password -f FullTCPScan.xml | grep -E -o "Scan name : .*?")"