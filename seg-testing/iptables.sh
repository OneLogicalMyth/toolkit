#!/bin/bash
# Accepts traffic on all ports for egress testing
#
# Check for root access
if [[ $EUID -ne 0 ]]; then
   echo ""
   echo "This script must be run as root in order to change iptables rules" 
   echo ""
   exit 1
fi
# Start Nginx Web Server for testing
# (Other web servers are available)
systemctl start nginx
# Flush iptables rules
iptables -F
# Set default iptables rules to ACCEPT
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
# Accept loopback & ICMP traffic
iptables -t nat -A PREROUTING -i lo -j RETURN
iptables -t nat -A PREROUTING -p icmp -j RETURN
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
# Accept established communications
iptables -t nat -A PREROUTING -m state --state RELATED,ESTABLISHED -j RETURN
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
# Permit traffic to OpenSSH server on tcp/22
# Permit traffic to the Nginx server on tcp/80
# If you need to run actual services on other ports (ssh, smb, etc)
# Then it will be necessary to add lines to the following section for each
# port required
iptables -t nat -A PREROUTING -p tcp -m tcp --dport 22 -j RETURN
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
iptables -t nat -A PREROUTING -p tcp -m tcp --dport 80 -j RETURN
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
# Add dynamic NAT to forward all other traffic to port 80
# Irrespective of source or destination port
iptables -t nat -A PREROUTING -p tcp -j DNAT --to-destination :80
exit 0
