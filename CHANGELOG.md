# Changelog

Tous les changements notables apportés à ce projet seront documentés dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.2] - 2025-05-15

### Amélioré
- Suppression automatique des fichiers de sauvegarde après une installation réussie
- Vérification de l'existence des fichiers avant suppression pour éviter les erreurs

## [1.2.1] - 2025-05-15

### Amélioré
- Détection robuste des fichiers de sauvegarde avec liste exhaustive des emplacements possibles
- Utilisation de find avec plusieurs patterns pour garantir la suppression de tous les fichiers temporaires
- Feedback visuel pour chaque fichier de sauvegarde supprimé
- Script de désinstallation pour supprimer tous les fichiers .bak potentiels
- Recherche plus exhaustive des fichiers temporaires à nettoyer

## [1.2.0] - 2025-05-15

### Ajouté
- Script de nettoyage des logs `clean-wifi-logs` pour maintenir une taille raisonnable des fichiers journaux
- Configuration logrotate pour une gestion automatique des logs (rotation hebdomadaire)
- Filtrage des événements NetworkManager pour réduire le bruit dans les logs
- Détection intelligente des événements pertinents
- Limite de taille de 1Mo pour la rotation automatique des logs

### Modifié
- Réduction significative de la verbosité des logs pour éviter l'encombrement
- Rétrogradation de plusieurs messages de niveau INFO à DEBUG
- Messages de log plus concis et informatifs
- Restructuration de la fonction principale pour un meilleur workflow
- Scripts d'installation et désinstallation améliorés pour gérer les composants logrotate

### Optimisé
- Traitement plus efficace des événements NetworkManager
- Réduction de la taille des fichiers de log générés
- Gestion à deux niveaux des logs (automatique via logrotate et manuel via clean-wifi-logs)

## [1.1.0] - 2025-05-15

### Ajouté
- Journalisation de l'identité de l'utilisateur dans les logs
- Option de configuration pour activer/désactiver l'inclusion du nom d'utilisateur dans les logs

### Modifié
- Amélioré la robustesse du script pour éviter les erreurs de syntaxe
- Restructuré le code pour une meilleure lisibilité et maintenabilité

## [1.0.0] - 2025-05-15

### Ajouté
- Version initiale du script `disable-wifi-on-ethernet.sh`
- Script d'installation automatique (`install.sh`)
- Script de désinstallation (`uninstall.sh`)
- Documentation complète dans README.md
- Système de journalisation dans `/var/log/disable-wifi-on-ethernet.log`
- Notifications utilisateur via `notify-send`
- Détection automatique de l'utilisateur connecté en session graphique
- Fichier de configuration externe pour personnalisation
- Niveaux de journalisation configurables (DEBUG, INFO, WARN, ERROR)
- Support pour ignorer certaines interfaces Ethernet
- Option pour exiger une adresse IP avant de désactiver le WiFi

### Caractéristiques
- Désactivation automatique du Wi-Fi lorsqu'une connexion Ethernet est détectée
- Journalisation détaillée des actions pour le débogage
- Notifications système informant l'utilisateur des actions entreprises
- Installation et désinstallation simplifiées
- Configuration flexible via fichier externe