# USAGE: cd /home/$(whoami) && ./HostScan.sh 1.1.1.1

cleanIP=$(echo $1 | sed 's/\./_/g')
folder=$(echo $cleanIP)
tcpfile="$(echo $cleanIP)T"
udpfile="$(echo $cleanIP)U"
verfile="$(echo $tcpfile)DETAILED"
xmlfile="$(echo $tcpfile).xml"

mkdir $folder

nmap -Pn -sS --stats-every 3m --max-retries 1 --max-scan-delay 20 --defeat-rst-ratelimit -T4 -p0-65535 -oA ./$folder/$tcpfile $1
nmap -Pn --top-ports 1000 -sU --stats-every 3m --max-retries 1 -T3 -oA ./$folder/$udpfile $1

ports=$(cat ./$folder/$xmlfile | grep portid | grep protocol=\"tcp\" | cut -d'"' -f4 | paste -sd "," -)
echo "TCP Open Ports: $ports"
if [ -n "$ports" ]; then
    nmap -nvv -Pn -sSV -T1 -p$ports --version-intensity 9 -A -oA ./$folder/$verfile $1
fi

#Copy over nmap style sheet and update XML to refer to it
sed -i 's/\(stylesheet href="\).*\(" type\)/\1nmap.xsl\2/g' ./$folder/$tcpfile.xml
sed -i 's/\(stylesheet href="\).*\(" type\)/\1nmap.xsl\2/g' ./$folder/$udpfile.xml
sed -i 's/\(stylesheet href="\).*\(" type\)/\1nmap.xsl\2/g' ./$folder/$verfile.xml
cp /usr/share/nmap/nmap.xsl ./$folder/
