# Disable-WiFi-On-Ethernet

Un script NetworkManager qui désactive automatiquement le Wi-Fi lorsqu'une connexion Ethernet est détectée.

## Fonctionnalités

- Désactive automatiquement le Wi-Fi lorsqu'une connexion Ethernet est active
- Envoie une notification à l'utilisateur lorsque le Wi-Fi est désactivé
- Journalise les actions entreprises pour faciliter le débogage
- Fonctionne via les scripts de dispatch NetworkManager

## Prérequis

- NetworkManager
- notify-send (libnotify-bin)
- Droits sudo pour l'installation

## Installation

```bash
# Cloner le dépôt
git clone https://github.com/ChouaibKhamallah/Disable-WiFi-On-Ethernet.git
cd Disable-WiFi-On-Ethernet

# Rendre le script d'installation exécutable
chmod +x install.sh

# Exécuter le script d'installation
sudo ./install.sh
```

Le script d'installation va:
1. Copier le script principal dans `/etc/NetworkManager/dispatcher.d/`
2. Définir les permissions appropriées
3. Vérifier les dépendances
4. Redémarrer le service NetworkManager

## Configuration

Le comportement du script peut être modifié en éditant les variables en haut du script. Par défaut:

- Fichier journal: `/tmp/force-wifi-off.log`
- Durée de la notification: 6000 ms

## Désinstallation

```bash
sudo ./uninstall.sh
```

## Journalisation

Les logs sont écrits dans `/tmp/force-wifi-off.log` et incluent:
- Horodatage
- Type d'événement détecté
- État des interfaces réseau
- Actions entreprises

## Contribution

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request.

## Licence

Ce projet est sous licence [MIT](LICENSE).