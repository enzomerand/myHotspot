# myHotspot 1.3 - Par Nyzo
*myhotspot.sh* créé de faux points d'accès wifi (hotspot), utilisant Airbase-ng et MITMf.
## Installation
### Configuration
Fonctionne sur Ubuntu 14.04 LTS et les versions antérieures, **si vous n'êtes pas en ethernet, vous devrez avoir deux cartes wifi (soit wlan0 et wlan1, généralement)**
### Paquets requis
DHCP, Aircrack, MITMf.
```sh
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install isc-dhcp-server aircrack-ng python
```
Pour MITMf :
```sh
cd /etc
sudo git clone https://github.com/byt3bl33d3r/MITMf.git
cd MITMf
sudo pip install -r requirements.txt
su root
./setup.sh
```
Sur Kali, une erreur peut apparaître : *ImportError: no module named pcap*. Pour résoude cette erreur, lancez la commande : 
```sh
sudo apt-get install python-pycap
```
Plus d'infos sur [MITMf].
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


Si au lancement de MITMf un erreur similaire apparaît :
```sh
Traceback (most recent call last):
  File "mitmf.py", line 41, in <module>
    import user_agents
  File "/usr/local/lib/python2.7/dist-packages/user_agents/__init__.py", line 3, in <module>
    from .parsers import parse
  File "/usr/local/lib/python2.7/dist-packages/user_agents/parsers.py", line 4, in <module>
    from ua_parser import user_agent_parser
  File "/usr/local/lib/python2.7/dist-packages/ua_parser-0.4.0-py2.7.egg/ua_parser/user_agent_parser.py", line 460, in <module>
    yamlFile = open(yamlPath)
IOError: [Errno 2] No such file or directory: '/usr/local/lib/python2.7/dist-packages/ua_parser-0.4.0-py2.7.egg/ua_parser/regexes.yaml'
```
Alors executez la commande suivante :
```sh
pip install -e git+git://github.com/selwin/ua-parser.git#egg=ua-parser
```

## À venir
Correction du bug du bypass ssl. Implémentation dans arduino (sous un autre langage).

[MITMf]:https://github.com/byt3bl33d3r/MITMf
