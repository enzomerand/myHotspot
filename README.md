# myHotspot 1.1 - Par Nyzo
*myhotspot.sh* créé de faux points d'accès wifi (hotspot), utilisant Airbase-ng, sslstrip et ettercap.
## Installation
### Configuration
Fonctionne sur Ubuntu 14.04 LTS et les versions antérieures, **si vous n'êtes pas en ethernet, vous devrez avoir deux cartes wifi (soit wlan0 et wlan1, généralement)**
### Paquets requis
DHCP, Aircrack, SSLStrip2, Net-Creds, DNS2Proxy, dnspython.
```sh
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install isc-dhcp-server aircrack-ng python-scapy python python-pcapy
```
Pour Net-Creds (requis pour voir les mots de passe, etc) :
```sh
cd /etc
sudo git clone https://github.com/DanMcInerney/net-creds.git
```
Pour SSLStrip2 :
```sh
cd /etc
sudo git clone https://github.com/LeonardoNve/sslstrip2.git
cd sslstrip2
python setup.py install
```
Pour DNS2Proxy :
```sh
cd /etc
sudo git clone https://github.com/LeonardoNve/dns2proxy.git
```
Pour DNSPython :
```sh
cd /etc
sudo git clone https://github.com/rthalley/dnspython.git
cd dnspython
python setup.py install
```
### Installer
Clonez le dépôt Github :
```sh
cd /etc/
sudo clone git https://github.com/Nyzo/myHotspot.git
sudo chmod 755  myhotspot.sh
```
Si vous n'avez pas installer git :
```sh
apt-get install git
```
## Utiliser le script
Identifiez-vous en tant que root :
```sh
su root
```
Allez dans le répertoire myHotspot :
```sh
cd /etc/myHotspot/
```
Lancez le script :
```sh
./myhotspot.sh
```
Et suivez les instructions.
## Correction de bug(s)
*Contactez-moi si vous rencontrez n'importe quel bug(s), j'emploierai tout les moyens possibles pour le(s) résoudre(s).*

Parfois, au lancement du serveur DHCP, une erreur apparaît comme :
```
Can't open /etc/dhcp/dhcp.conf: permission denied
```
ou
```
Can't open /var/lib/dhcp/dhcpd.leases: permission denied.
```
ou
```
Can't open /pentest/wireless/myhotspot/dhcpd.conf: Permission denied
```

Si après avoir vérifier les permissions cela affiche toujours un message d'erreur, vérifiez **apparmor** :
```sh
sudo apparmor_status
```

Si **/usr/sbin/dhcpd** est présent dans la liste, suivez ces instructions :

1. Arrêtez apparmor
```sh
sudo /etc/init.d/apparmor stop
```
2. Editez /etc/apparmor.d/usr.sbin.dhcpd avec les permissions root :
```sh
sudo nano /etc/apparmor.d/usr.sbin.dhcpd
```
3. Et assurez-vous que le fichier contient ces lignes (peu importe l'ordre) :
```sh
  /etc/dhcp/ r,
  /etc/dhcp/** r,
  /etc/dhcpd{,6}.conf r,
  /etc/dhcpd{,6}_ldap.conf r,
  /pentest/wireless/myhotspot/dhcpd{,6}.conf r,

  /usr/sbin/dhcpd mr,

  /var/lib/dhcp/dhcpd{,6}.leases* lrw,
  /var/log/ r,
  /var/log/** rw,
  /{,var/}run/{,dhcp-server/}dhcpd{,6}.pid rw,
```
4. Démarrez apparmor
```sh
sudo /etc/init.d/apparmor start
```

Après cette opération, apparmor va autoriser le serveur DHCP à ouvrir les fichiers /etc/dhcp/dhcpd.conf or /var/lib/dhcp/dhcpd.leases ou /pentest/wireless/myhotspot/dhcpd.conf. Pour plus d'informations, regardez **man apparmor**

## À venir
Correction du bug de sslstrip.
