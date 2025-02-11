#!/bin/bash

user=$1
password=$2
vlan10='vlan 10 name test'
vlan10ipaddr='int vlan 10' 
vlan15='vlan 15 name prod'
vlan15ipaddr='int vlan 15'
hostname=$3
minicom -D /dev/$4 <<EOF > resultatconf.txt

$user
$password
$password
configure terminal
hostname $hostname
$vlan10
$vlan10ipaddr
ip address 172.16.10.254 255.255.255.0
int range gi1/0/1-12
switchport access vlan 10
no shutdown
$vlan15
$vlan15ipaddr
ip address 172.16.15.254 255.255.255.0
exit
int range gi1/0/12-24
switchport access vlan 15
no shutdown
exit
EOF
