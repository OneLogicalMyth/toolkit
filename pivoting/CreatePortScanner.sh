#!/bin/bash
if [ $# -eq 0 ]; then
    echo "Usage: ./CreatePortScanner.sh ps 10 192.168.1 1..254 > PortScan.ps1"
    echo "Usage: ./CreatePortScanner.sh nc 10 192.168.1 1..254 > PortScan.sh"
    echo "Usage: ./CreatePortScanner.sh ls 10 > SimpleTop10List.txt"
    echo "Usage: ./CreatePortScanner.sh <nc_or_ps> <no._top_ports> <network> <rangestart>..<rangeend>"
else
   ports=$(nmap --top-ports $2 -v -oG - 2>/dev/null | grep 'TCP(' | cut -d' ' -f4 | cut -d';' -f2 | cut -d')' -f1)

    if [ $1 = "ps" ]; then
        psports=$(echo "\$ports = \"$(echo $ports | sed 's/\([0-9]\{1,6\}\)-\([0-9]\{1,6\}\)/\$\(\1\.\.\2 -join ","\)/g')\" -split \",\"")
        echo $psports
        echo "$4 | %{ \$h = \"$3.\$_\";\"Testing ports on \$h\";\$ports | %{ try{(New-Object system.net.sockets.tcpclient).connect(\$h,\$_);\"\$h - \$_ - Open\"} catch { \$null } } }"
    fi

    if [ $1 = "nc" ]; then
        for h in $(seq $(echo $4 | cut -d'.' -f1,3 --output-delimiter ' '))
        do
	    echo "echo \"Ports open on $3.$h\""
            for l in `echo $ports | tr ',' '\n'`; do echo "nc -zv $3.$h $l 2>&1 | grep succeeded | cut -d' ' -f4"; done
        done
    fi

    if [ $1 = "ls" ]; then
	echo $ports
    fi
fi

