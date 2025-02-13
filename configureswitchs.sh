#!/bin/bash
user=konexioais
baseip="172.16."
ipswitch=".254"
netmask="255.255.255.0"
declare -A iplan=([admin]=0 [front]=5 [test]=10 [prod]=15)
read -p "Entrez le mot de passe des switchs : " password

function ChercheCableConsole() {
    if [ -e /dev/serial ]; then
        devserial=`ls /dev/serial/by-id/ | grep -i cisco`
    fi
}

function BranchementCableConsole() {
ChercheCableConsole
if [ -v $devserial ]; then 
    echo -n "Reliez le pc et le switch avec un cable console"
    while [ -v $devserial ]; do
        echo -n "."
        sleep .5
	ChercheCableConsole
    done
    echo
fi
}

function ConfigureSwitch() {
lan=$1
switchname=sw-${lan}00
ipaddr=$baseip${iplan[$lan]}$ipswitch
BranchementCableConsole
date=`date +%Y%m%d%M%S`
#minicom -D $devserial -C ResultatConfig_${lan}_${date}.txt <<EOF
cat <<EOF > ResultatConfig_${lan}_${date}.txt
cisco
cisco
$user
$password
$password
configure terminal
hostname $switchname
interface vlan 1
ip address $ipaddr $netmask
exit
EOF
devserial=
}

function ConfigureTestProdSwitch() {
switchname="sw-test-prod00"
BranchementCableConsole
date=`date +%Y%m%d%M%S`
#minicom -D $devserial -C ResultatConfig_${lan}_${date}.txt <<EOF
cat <<EOF > ResultatConfig_test_prod_${date}.txt
cisco
cisco
$user
$password
$password
configure terminal
hostname $switchname
vlan ${iplan[test]} name test
interface vlan ${iplan[test]}
ip address $baseip${iplan[test]}$ipswitch $netmask
interface range gi1/0/1-12
switchport access vlan ${iplan[test]}
no shutdown
vlan ${iplan[prod]} name prod
interface vlan ${iplan[prod]}
ip address $baseip${iplan[prod]}$ipswitch $netmask
interface range gi1/0/12-24
switchport access vlan ${iplan[prod]}
no shutdown
exit
EOF
}

while true; do
    read -n1 -p "Configure switch [a] : Admin, [f] : Front, [t] : Test-Prod, [q] : quit" toto
    echo
    case $toto in
        [aA]) echo "Configuration du switch Admin"; ConfigureSwitch admin; continue;;
        [fF]) echo "Configuration du switch Front"; ConfigureSwitch front; continue;;
        [tTpP]) echo "Configuration du switch Test-Prod"; ConfigureTestProdSwitch; continue;;
        [qQ]) echo "Fin"; break;;
        *) echo "Invalid input..."; continue;;
    esac
done
