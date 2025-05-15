#!/bin/bash
#
# Script de désinstallation pour disable-wifi-on-ethernet
#

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Vérification des privilèges d'administration
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Erreur: Ce script doit être exécuté avec les privilèges root (sudo).${NC}"
  exit 1
fi

# Chemins
SCRIPT_NAME="disable-wifi-on-ethernet"
INSTALL_DIR="/etc/NetworkManager/dispatcher.d"
INSTALL_PATH="$INSTALL_DIR/$SCRIPT_NAME"

echo -e "${YELLOW}Désinstallation de $SCRIPT_NAME...${NC}"

# Vérifier si le script est installé
if [ ! -f "$INSTALL_PATH" ]; then
    echo -e "${RED}Le script n'est pas installé dans $INSTALL_PATH.${NC}"
    exit 1
fi

# Suppression du script, du fichier de configuration, des logs et outils associés
echo -e "${YELLOW}Suppression du script, de la configuration et des fichiers associés...${NC}"
rm -f "$INSTALL_PATH"
rm -f "/etc/$SCRIPT_NAME.conf"
rm -f "/var/log/$SCRIPT_NAME.log"
rm -f "/etc/logrotate.d/$SCRIPT_NAME"
rm -f "/usr/local/bin/clean-wifi-logs"

# Nettoyage des anciennes versions de logs rotées
rm -f "/var/log/$SCRIPT_NAME.log-"*

# Nettoyage des éventuels fichiers de sauvegarde
echo -e "${YELLOW}Nettoyage des fichiers de sauvegarde...${NC}"

# Débuggage - liste tous les fichiers .bak dans les répertoires pertinents
echo -e "${YELLOW}Recherche des fichiers .bak existants...${NC}"
ls -la /etc/NetworkManager/dispatcher.d/*.bak 2>/dev/null || echo "  Aucun fichier .bak trouvé dans /etc/NetworkManager/dispatcher.d/"
ls -la /etc/*.bak 2>/dev/null || echo "  Aucun fichier .bak trouvé dans /etc/"

# Suppression directe des fichiers .bak connus
echo -e "${YELLOW}Suppression des fichiers .bak connus...${NC}"
rm -fv "$INSTALL_PATH.bak"
rm -fv "/etc/$SCRIPT_NAME.conf.bak"
rm -fv "/etc/NetworkManager/dispatcher.d/disable-wifi-on-ethernet.bak"
rm -fv "/etc/disable-wifi-on-ethernet.conf.bak"

# Recherche et suppression des fichiers .bak restants avec une commande plus explicite
echo -e "${YELLOW}Suppression de tout autre fichier .bak potentiel...${NC}"
find /etc/NetworkManager/dispatcher.d/ -name "*.bak" -type f -exec rm -fv {} \;
find /etc/ -maxdepth 1 -name "*.bak" -type f -exec rm -fv {} \;

# Vérification de la suppression
if [ ! -f "$INSTALL_PATH" ] && [ ! -f "/etc/$SCRIPT_NAME.conf" ]; then
    echo -e "${GREEN}Script et fichiers associés supprimés avec succès!${NC}"
else
    echo -e "${RED}Erreur: La désinstallation a échoué!${NC}"
    exit 1
fi

# Redémarrage de NetworkManager
echo -e "${YELLOW}Redémarrage de NetworkManager...${NC}"
systemctl restart NetworkManager

echo -e "${GREEN}Désinstallation terminée avec succès!${NC}"

exit 0