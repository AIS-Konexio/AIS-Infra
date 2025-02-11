#!/bin/bash

user=$1	
password=$2
hostname=$3
ipaddr=$4' 255.255.255.0'
minicom -D /dev/$5 <<EOF > resultat.txt

$user
$password
$password
configure terminal
hostname $hostname
interface vlan 1
ip address $ipaddr
exit
EOF


