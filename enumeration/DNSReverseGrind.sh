echo "[*] Grinding 1 to $1 hosts for subnet $2 against DNS server $3"

for s in `seq 1 $1`;do host $2.$s $3; done | grep 'domain name' | sed 's/\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.in-addr\.arpa/\4\.\3\.\2\.\1/' | cut -d' ' -f1,5 > DNSReverseGrindHosts.txt

echo "[+] Completed. Results saved to ./DNSReverseGrindHosts.txt"
