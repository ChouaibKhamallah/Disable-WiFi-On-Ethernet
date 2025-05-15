#!/bin/bash
#
# Script d'installation pour Disable-WiFi-On-Ethernet
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

# Chemins d'installation
SCRIPT_NAME="disable-wifi-on-ethernet"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/etc/NetworkManager/dispatcher.d"
INSTALL_PATH="$INSTALL_DIR/$SCRIPT_NAME"

echo -e "${YELLOW}Installation de $SCRIPT_NAME...${NC}"

# Vérification des dépendances
echo -e "${YELLOW}Vérification des dépendances...${NC}"
MISSING_DEPS=0

# Vérifier NetworkManager
if ! command -v nmcli &> /dev/null; then
    echo -e "${RED}NetworkManager n'est pas installé!${NC}"
    MISSING_DEPS=1
fi

# Vérifier notify-send
if ! command -v notify-send &> /dev/null; then
    echo -e "${RED}notify-send n'est pas installé! Veuillez installer libnotify-bin.${NC}"
    MISSING_DEPS=1
fi

# Si des dépendances sont manquantes, proposer de les installer
if [ $MISSING_DEPS -eq 1 ]; then
    echo -e "${YELLOW}Voulez-vous installer les dépendances manquantes? (o/N) ${NC}"
    read -r response
    if [[ "$response" =~ ^([oO][uU][iI]|[oO])$ ]]; then
        apt-get update
        apt-get install -y network-manager libnotify-bin
    else
        echo -e "${RED}Installation annulée: veuillez installer les dépendances manuellement.${NC}"
        exit 1
    fi
fi

# Copie du script
echo -e "${YELLOW}Copie du script dans $INSTALL_DIR...${NC}"
cp "$SCRIPT_DIR/disable-wifi-on-ethernet.sh" "$INSTALL_PATH"

# Définition des permissions
echo -e "${YELLOW}Définition des permissions...${NC}"
chmod 755 "$INSTALL_PATH"

# Vérification de la copie
if [ -f "$INSTALL_PATH" ]; then
    echo -e "${GREEN}Script installé avec succès dans $INSTALL_PATH${NC}"
else
    echo -e "${RED}Erreur: L'installation a échoué!${NC}"
    exit 1
fi

# Redémarrage de NetworkManager
echo -e "${YELLOW}Redémarrage de NetworkManager...${NC}"
systemctl restart NetworkManager

echo -e "${GREEN}Installation terminée avec succès!${NC}"
echo -e "${YELLOW}Le script commencera à fonctionner au prochain changement d'état réseau.${NC}"

exit 0