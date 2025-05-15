# Changelog

Tous les changements notables apportés à ce projet seront documentés dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-05-15

### Ajouté
- Version initiale du script `disable-wifi-on-ethernet.sh`
- Script d'installation automatique (`install.sh`)
- Script de désinstallation (`uninstall.sh`)
- Documentation complète dans README.md
- Système de journalisation dans `/tmp/disable-wifi-on-ethernet.log`
- Notifications utilisateur via `notify-send`
- Détection automatique de l'utilisateur connecté en session graphique

### Caractéristiques
- Désactivation automatique du Wi-Fi lorsqu'une connexion Ethernet est détectée
- Journalisation détaillée des actions pour le débogage
- Notifications système informant l'utilisateur des actions entreprises
- Installation et désinstallation simplifiées