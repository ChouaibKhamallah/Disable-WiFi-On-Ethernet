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
if [ "$EUID" -ne 0 ]; then
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

# Suppression du script
echo -e "${YELLOW}Suppression du script...${NC}"
rm -f "$INSTALL_PATH"

# Vérification de la suppression
if [ ! -f "$INSTALL_PATH" ]; then
    echo -e "${GREEN}Script supprimé avec succès!${NC}"
else
    echo -e "${RED}Erreur: La désinstallation a échoué!${NC}"
    exit 1
fi

# Redémarrage de NetworkManager
echo -e "${YELLOW}Redémarrage de NetworkManager...${NC}"
systemctl restart NetworkManager

echo -e "${GREEN}Désinstallation terminée avec succès!${NC}"

exit 0