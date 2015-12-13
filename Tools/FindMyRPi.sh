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
# Usage: 
# ----------------------------------------------------------------------------------------

# Change this if your network interface is different
i="en0"

echo "----------------------------------"
echo "## Be patient it takes a bit... ##"
echo "----------------------------------"

cidr=$(while read y; do echo ${y%.*}".0/$(m=0; 

while read -n 1 x && [ $x = f ]; 
do m=$[m+4]; 
done < <(ifconfig $i | awk '/mask/             {$4=substr($4,3); print $4}'); 
echo $m )"; 

done < <(ifconfig $i | awk '/inet[ ]/{print $2}'))

myip=`ifconfig $i | grep "inet " | awk 'NR==1 {print $2}'`
echo "sudo nmap -n -T4 -PN -p9091 --exclude $myip $cidr"
sudo nmap -n -T4 -PN -p9091 --exclude "$myip" "$cidr"