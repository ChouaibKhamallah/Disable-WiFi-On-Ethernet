# Disable-WiFi-On-Ethernet

Un script NetworkManager qui désactive automatiquement le Wi-Fi lorsqu'une connexion Ethernet est détectée.

## Pourquoi ce script est-il important ?

Ce script répond à plusieurs besoins importants :

1. **Économie d'énergie** - Désactiver le Wi-Fi lorsqu'il n'est pas nécessaire permet de réduire la consommation d'énergie, ce qui est particulièrement utile pour les ordinateurs portables fonctionnant sur batterie.

2. **Sécurité réseau** - Réduire les interfaces réseau actives diminue la surface d'attaque potentielle de votre système. Une interface Wi-Fi inactive ne peut pas être exploitée.

3. **Stabilité de la connexion** - Évite les problèmes de routage quand deux interfaces réseau sont actives simultanément, assurant que le trafic passe toujours par la connexion filaire plus stable et généralement plus rapide.

4. **Automatisation** - Élimine la nécessité de désactiver manuellement le Wi-Fi lorsque vous vous connectez à un réseau filaire, puis de le réactiver quand vous vous déconnectez.

5. **Simplicité d'utilisation** - Fonctionne en arrière-plan sans intervention de l'utilisateur, tout en fournissant des notifications pour informer des actions entreprises.

## Fonctionnalités

- Désactive automatiquement le Wi-Fi lorsqu'une connexion Ethernet est active
- Envoie une notification à l'utilisateur lorsque le Wi-Fi est désactivé
- Journalise les actions entreprises pour faciliter le débogage
- Fonctionne via les scripts de dispatch NetworkManager
- Configuration entièrement personnalisable via un fichier externe
- Journalisation intelligente avec différents niveaux de verbosité
- Possibilité d'ignorer certaines interfaces réseau (comme les interfaces virtuelles)
- Gestion efficace des logs avec un outil de nettoyage dédié et logrotate

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
2. Installer le fichier de configuration dans `/etc/`
3. Installer l'outil de nettoyage des logs
4. Configurer logrotate pour la rotation automatique des logs
5. Définir les permissions appropriées
6. Vérifier les dépendances
7. Créer le fichier journal
8. Redémarrer le service NetworkManager

## Configuration

Le comportement du script peut être personnalisé en modifiant le fichier de configuration situé à `/etc/disable-wifi-on-ethernet.conf`.

Principales options configurables :

```bash
# Chemin du fichier de log
LOG_FILE="/var/log/disable-wifi-on-ethernet.log"

# Niveau de journalisation (DEBUG, INFO, WARN, ERROR)
LOG_LEVEL="INFO"

# Inclure le nom d'utilisateur dans les logs
INCLUDE_USERNAME_IN_LOGS="true"

# Activer ou désactiver les notifications
NOTIFICATIONS_ENABLED="true"

# Durée d'affichage de la notification en millisecondes
NOTIFICATION_TIMEOUT=6000

# Ignorer certaines interfaces Ethernet (séparées par des espaces)
# Exemple: "docker0 virbr0"
IGNORED_INTERFACES="virbr0"

# Désactiver le WiFi uniquement si la connexion Ethernet a une adresse IP
REQUIRE_IP_BEFORE_DISABLING_WIFI="false"
```

Pour plus d'options et de détails, consultez le fichier de configuration lui-même.

## Journalisation

Les logs sont écrits dans `/var/log/disable-wifi-on-ethernet.log` et incluent:
- Horodatage
- Niveau de log (DEBUG, INFO, WARN, ERROR)
- Nom d'hôte et informations utilisateur (si activé)
- Type d'événement détecté
- Actions entreprises

### Gestion des logs

Le script utilise deux mécanismes pour gérer efficacement les fichiers de log :

1. **Logrotate** : Configuration automatique qui :
   - Effectue une rotation hebdomadaire des logs
   - Conserve 4 versions compressées des anciens logs
   - Force une rotation si le fichier dépasse 1Mo
   - Maintient les permissions correctes

2. **Outil de nettoyage manuel** : Pour un contrôle plus direct :
   ```bash
   sudo clean-wifi-logs
   ```
   Ce script conserve les 50 dernières entrées de log et supprime les anciennes.

Ces deux mécanismes assurent que vos logs ne consommeront jamais trop d'espace disque.

## Désinstallation

```bash
sudo ./uninstall.sh
```

Le script de désinstallation supprime tous les fichiers installés, y compris :
- Le script principal
- Le fichier de configuration
- Les fichiers de logs et leurs archives
- La configuration logrotate
- L'outil de nettoyage des logs
- Tous les fichiers de sauvegarde créés pendant l'installation

## Contribution

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request.

## Licence

Ce projet est sous licence [MIT](LICENSE).