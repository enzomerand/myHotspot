![myHotspot](http://mtfo.fr/myhotspot.png)
# myHotspot 1.4 - Par Nyzo
*myhotspot.sh* créé de faux points d'accès wifi (hotspot), utilisant Airbase-ng et MITMf.
## Installation
### Configuration
Testé sur Ubuntu 14.04 LTS et les versions antérieures, **si vous n'êtes pas en ethernet, vous devrez avoir deux cartes wifi (soit wlan0 et wlan1, généralement) dont une qui accepte le mode moniteur.**

**La compatibilité sur Ubuntu 15.10 est actuellement en phase de test.**
### Installation
Plusieurs paquets requis seront installés automatiquement.
Pour commencer, clonez le dêpot ou téléchargez-le (git ou wget) :
```sh
cd /etc
sudo git clone https://github.com/Nyzo/myHotspot.git
cd myHotspot
sudo chmod +x myhotspot.sh
```
Lancez la commande suivante pour installer myHotspot et ses dépendances :
```sh
sudo ./myhotspot.sh install
```
Pour terminer l'installation, éditez le fichier de configuration MITMF :
```sh
sudo nano /etc/MITMf/config/mitmf.conf
```
Puis repérez la ligne *port = 53* dans la section *[[DNS]]* et changez le port par un port non utilisé (54 par exemple) **seulement si vous utilisez dnsmasq (port 53)**. Pour savoir si un port est utilisé, faites :
```sh
netstat -tulpn | grep :53
```
Puis repérez le PID associé au port 53 puis tuez-le :

**(exemple)**
```sh
kill 2721
```
### Mise à jour
Pour mettre à jour myHotspot et ses dépendances, éxecutez la commande suivante :
```sh
sudo ./myhospot.sh update
```
### Utiliser le script
Identifiez-vous en tant que root :
```sh
su root
```
Ou utilisez sudo devant la commande d'éxecution du script.
Allez dans le répertoire myHotspot :
```sh
cd /etc/myHotspot/
```
Lancez le script :
```sh
./myhotspot.sh start
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

* Arrêtez apparmor
```sh
sudo /etc/init.d/apparmor stop
```
* Editez /etc/apparmor.d/usr.sbin.dhcpd avec les permissions root :
```sh
sudo nano /etc/apparmor.d/usr.sbin.dhcpd
```
* Et assurez-vous que le fichier contient ces lignes (peu importe l'ordre) :
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
* Démarrez apparmor
```sh
sudo /etc/init.d/apparmor start
```

Après cette opération, apparmor va autoriser le serveur DHCP à ouvrir les fichiers /etc/dhcp/dhcpd.conf or /var/lib/dhcp/dhcpd.leases ou /pentest/wireless/myhotspot/dhcpd.conf. Pour plus d'informations, regardez **man apparmor**


Si au lancement de MITMf une erreur similaire à celle-ci apparaît :
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
Alors exécutez la commande suivante :
```sh
pip install -e git+git://github.com/selwin/ua-parser.git#egg=ua-parser
```


Si à l'installation des paquets python requis (avec pip) une erreur comme celle-ci apparaît :
```sh
Traceback (most recent call last):
  File "/usr/bin/pip", line 9, in <module>
    load_entry_point('pip==1.5.4', 'console_scripts', 'pip')()
  File "/usr/local/lib/python2.7/dist-packages/pkg_resources/__init__.py", line 546, in load_entry_point
    return get_distribution(dist).load_entry_point(group, name)
  File "/usr/local/lib/python2.7/dist-packages/pkg_resources/__init__.py", line 2666, in load_entry_point
    return ep.load()
  File "/usr/local/lib/python2.7/dist-packages/pkg_resources/__init__.py", line 2339, in load
    return self.resolve()
  File "/usr/local/lib/python2.7/dist-packages/pkg_resources/__init__.py", line 2345, in resolve
    module = __import__(self.module_name, fromlist=['__name__'], level=0)
  File "/usr/lib/python2.7/dist-packages/pip/__init__.py", line 61, in <module>
    from pip.vcs import git, mercurial, subversion, bazaar  # noqa
  File "/usr/lib/python2.7/dist-packages/pip/vcs/mercurial.py", line 9, in <module>
    from pip.download import path_to_url
  File "/usr/lib/python2.7/dist-packages/pip/download.py", line 25, in <module>
    from requests.compat import IncompleteRead
ImportError: cannot import name IncompleteRead
```
Alors éxecutez la commande suivante :
```sh
easy_install -U pip
```
## À venir
Wiki en cours de création.

Plus d'infos sur [MITMf].

[MITMf]:https://github.com/byt3bl33d3r/MITMf
