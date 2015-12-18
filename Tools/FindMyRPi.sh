#!/bin/bash

#
# Purpose: Scan your lan range of IP addresses (/24)
#          and reports the fingerprint. If you read Raspberry than you found what you were
#		   looking for.
#
# Author: Mario Esposito 2014
# License: Use and Enjoy at your will and zero responsibility for me.
#
# Requirements: nmap - if you don't have it you can install it for free from nmap.org 
# usage: ./command_name.sh or ./command_name.sh -6
# ----------------------------------------------------------------------------------------

# Change this if your network interface is different
i="en0"

echo "-----------------------------------"
echo "## Be patient, it takes a bit... ##"
echo "-----------------------------------"

myip=`ifconfig $i | grep "inet " | awk 'NR==1 {print $2}'`

#
# IPV6 section
#
if [ $1 = "-6" ]; then
	echo "# Scanning..."
	sudo nmap -6 --script=targets-ipv6-multicast-echo.nse --script-args 'newtargets,interface='$i -sL --exclude "$myip"
	exit
fi

#
# IPV4 section
#

# build CIDR
cidr=$(while read y; 
do echo ${y%.*}".0/$(m=0; 

while read -n 1 x && [ $x = f ]; 
do m=$[m+4]; 
done < <(ifconfig $i | awk '/mask/             {$4=substr($4,3); print $4}'); 
echo $m )"; 

done < <(ifconfig $i | awk '/inet[ ]/{print $2}'))

# scan an entire subnet and to do that you need some information about Classes Inter-Domain Routing (CIDR)

echo "# Scanning..."
sudo nmap -n -T4 -PN -p9091 --exclude "$myip" "$cidr"

# MICRO KNOWLEDGE

# CIDR is the short for Classless Inter-Domain Routing, an IP addressing 
# scheme that replaces the older system based on classes A, B, and C. 
# A single IP address can be used to designate many unique IP addresses with CIDR. 
# A CIDR IP address looks like a normal IP address except that it ends with a slash followed by a number, 
# called the IP network prefix. CIDR addresses reduce the size of routing tables and make more IP addresses available within organizations.

# if you are going to ssh into a remote using IPv6 address remember that the syntax is 
# ssh -6 fe80::21b:21ff:fe22:e865%eth1   <-- change the interface accordingly
#

