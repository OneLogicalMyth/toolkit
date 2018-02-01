echo "[*] Starting ARP scan of local network"
arp-scan -l | tail -n +3 | head -n -3 | cut -d$'\t' -f1 > ValidIPs.txt
for i in $(cat ./ValidIPs.txt); do echo "[*] $i was identified from ARP"; done
echo "[+] ARP scan has completed and saved to ./ValidIPs.txt"

