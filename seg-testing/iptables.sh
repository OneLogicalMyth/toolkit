#!/bin/bash
# Drops all IPv4 traffic other than intra-kernel & that specified
#
# Check for root access
if [[ $EUID -ne 0 ]]; then
   echo ""
   echo "This script must be run as root in order to change iptables rules" 
   echo ""
   exit 1
fi
# Flush iptables rules
iptables -F
# Set default iptables rules to DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
# Accept traffic between kernel processes
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
# Accept inbound traffic relating to established communications
iptables -A INPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT
# Following line defines targets to allow traffic to
# Add one host or network address per-line
iptables -A OUTPUT -d w.x.y.z/32 -j ACCEPT
# Bring up ethernet interface
ifconfig eth1 up
# Allow vlan tagging if required
modprobe 8021q
# Add vlan subinterface if required
vconfig add eth1 <vlan-number>
# Add address to subinterface
ifconfig eth1.100 192.168.1.10/24 up
# Add routing info
route add default gw <address>
exit 0
