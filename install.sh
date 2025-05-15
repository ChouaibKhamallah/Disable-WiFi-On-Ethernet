#!/bin/bash
#
# Script d'installation pour disable-wifi-on-ethernet
#

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher une bannière
show_banner() {
    echo -e "${BLUE}"
    echo "┌───────────────────────────────────────────────┐"
    echo "│ Installation de Disable-WiFi-On-Ethernet      │"
    echo "│ Un script qui désactive le WiFi quand         │"
    echo "│ une connexion Ethernet est disponible         │"
    echo "└───────────────────────────────────────────────┘"
    echo -e "${NC}"
}

# Afficher la bannière
show_banner

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
CONFIG_PATH="/etc/$SCRIPT_NAME.conf"
LOG_FILE="/var/log/$SCRIPT_NAME.log"

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

# Créer le répertoire d'installation si nécessaire
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Création du répertoire $INSTALL_DIR...${NC}"
    mkdir -p "$INSTALL_DIR"
fi

# Sauvegarde des fichiers existants si nécessaire
if [ -f "$INSTALL_PATH" ]; then
    echo -e "${YELLOW}Sauvegarde du script existant...${NC}"
    cp "$INSTALL_PATH" "$INSTALL_PATH.bak"
    # Vérifier si la sauvegarde a été créée
    if [ -f "$INSTALL_PATH.bak" ]; then
        echo -e "  ${GREEN}✓${NC} Sauvegarde créée: $INSTALL_PATH.bak"
    else
        echo -e "  ${RED}✗${NC} Échec de création de la sauvegarde: $INSTALL_PATH.bak"
    fi
fi

if [ -f "$CONFIG_PATH" ]; then
    echo -e "${YELLOW}Sauvegarde de la configuration existante...${NC}"
    cp "$CONFIG_PATH" "$CONFIG_PATH.bak"
    # Vérifier si la sauvegarde a été créée
    if [ -f "$CONFIG_PATH.bak" ]; then
        echo -e "  ${GREEN}✓${NC} Sauvegarde créée: $CONFIG_PATH.bak"
    else
        echo -e "  ${RED}✗${NC} Échec de création de la sauvegarde: $CONFIG_PATH.bak"
    fi
fi

# Copie du script et du fichier de configuration
echo -e "${YELLOW}Copie du script dans $INSTALL_DIR...${NC}"
# Renommer le script sans extension .sh lors de l'installation
cp "$SCRIPT_DIR/$SCRIPT_NAME.sh" "$INSTALL_PATH"

echo -e "${YELLOW}Copie du fichier de configuration...${NC}"
cp "$SCRIPT_DIR/$SCRIPT_NAME.conf" "$CONFIG_PATH"

# Définition des permissions
echo -e "${YELLOW}Définition des permissions...${NC}"
chmod 755 "$INSTALL_PATH"
chown root:root "$INSTALL_PATH"
chmod 644 "$CONFIG_PATH"
chown root:root "$CONFIG_PATH"

# Création et configuration du fichier de log
echo -e "${YELLOW}Création du fichier de log...${NC}"
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"
chown root:adm "$LOG_FILE"

# Configuration de logrotate
echo -e "${YELLOW}Installation de la configuration logrotate...${NC}"
LOGROTATE_CONFIG="/etc/logrotate.d/$SCRIPT_NAME"
cat > "$LOGROTATE_CONFIG" << 'EOL'
# Configuration de rotation des logs pour disable-wifi-on-ethernet
/var/log/disable-wifi-on-ethernet.log {
    # Conserve 4 versions des logs précédents
    rotate 4
    
    # Effectue une rotation hebdomadaire
    weekly
    
    # Ne génère pas d'erreur si le fichier log n'existe pas
    missingok
    
    # Ne crée pas de nouveau log vide si l'ancien était vide
    notifempty
    
    # Compresse les anciens logs avec gzip
    compress
    
    # Retarde la compression jusqu'à la prochaine rotation
    delaycompress
    
    # Permissions du nouveau fichier créé après rotation
    create 644 root adm
    
    # Taille maximale avant rotation forcée (même avant la date prévue)
    size 1M
    
    # Actions à exécuter après la rotation
    postrotate
        # Informer le service NetworkManager de la rotation
        systemctl restart NetworkManager-dispatcher >/dev/null 2>&1 || true
    endscript
}
EOL
chmod 644 "$LOGROTATE_CONFIG"

# Installation de l'outil de nettoyage des logs
echo -e "${YELLOW}Installation de l'outil de nettoyage des logs...${NC}"
CLEAN_TOOL="/usr/local/bin/clean-wifi-logs"
cat > "$CLEAN_TOOL" << 'EOL'
#!/bin/bash
#
# Script de nettoyage des logs pour disable-wifi-on-ethernet
#

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Vérification des privilèges d'administration
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Erreur: Ce script doit être exécuté avec les privilèges root (sudo).${NC}"
  exit 1
fi

# Chemin du fichier de log
LOG_FILE="/var/log/disable-wifi-on-ethernet.log"
if [ ! -f "$LOG_FILE" ]; then
    echo -e "${YELLOW}Aucun fichier de log trouvé à $LOG_FILE.${NC}"
    LOG_FILE="/tmp/disable-wifi-ethernet.log"
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${RED}Aucun fichier de log trouvé.${NC}"
        exit 1
    fi
fi

# Afficher la taille actuelle du fichier
SIZE_BEFORE=$(du -h "$LOG_FILE" | cut -f1)
echo -e "${YELLOW}Taille actuelle du fichier de log: ${BLUE}$SIZE_BEFORE${NC}"

# Demander confirmation
echo -e "${YELLOW}Voulez-vous nettoyer le fichier de log? (o/N) ${NC}"
read -r response
if [[ ! "$response" =~ ^([oO][uU][iI]|[oO])$ ]]; then
    echo -e "${YELLOW}Opération annulée.${NC}"
    exit 0
fi

# Nettoyer le fichier de log en conservant les 50 dernières lignes
echo -e "${YELLOW}Nettoyage du fichier de log...${NC}"
tail -n 50 "$LOG_FILE" > "$LOG_FILE.tmp"
mv "$LOG_FILE.tmp" "$LOG_FILE"
chmod 644 "$LOG_FILE"
chown root:adm "$LOG_FILE"

# Afficher la nouvelle taille du fichier
SIZE_AFTER=$(du -h "$LOG_FILE" | cut -f1)
echo -e "${GREEN}Nettoyage terminé!${NC}"
echo -e "${YELLOW}Nouvelle taille du fichier de log: ${BLUE}$SIZE_AFTER${NC}"
echo -e "${GREEN}Les 50 dernières entrées de log ont été conservées.${NC}"

exit 0
EOL
chmod 755 "$CLEAN_TOOL"
chown root:root "$CLEAN_TOOL"

echo -e "${GREEN}Outil de nettoyage des logs installé dans $CLEAN_TOOL${NC}"
echo -e "${GREEN}Configuration logrotate installée dans $LOGROTATE_CONFIG${NC}"

if [ -f "$INSTALL_PATH" ]; then
    # Vérifier si la sauvegarde a été créée
    if [ -f "$INSTALL_PATH.bak" ]; then
        rm -rf "$INSTALL_PATH.bak"
        echo -e "  ${GREEN}✓${NC} Fichier de sauvegarde supprimé: $INSTALL_PATH.bak"
    fi
fi


if [ -f "$CONFIG_PATH" ]; then
    # Vérifier si la sauvegarde a été créée
    if [ -f "$CONFIG_PATH.bak" ]; then
        rm -rf "$CONFIG_PATH.bak"
        echo -e "  ${GREEN}✓${NC} Fichier de sauvegarde supprimé: $CONFIG_PATH.bak"
    fi
fi

exit 0