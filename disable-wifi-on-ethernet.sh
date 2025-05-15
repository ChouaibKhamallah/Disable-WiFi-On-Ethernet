#!/bin/bash
#
# disable-wifi-on-ethernet
#
# Description:
#   Script qui désactive le Wi-Fi lorsqu'une connexion Ethernet est active.
#   Cette version utilise un fichier de configuration externe.
#
# Usage:
#   Ce script est normalement appelé par NetworkManager avec deux arguments:
#   $1 = Interface (ex: eth0, wlan0)
#   $2 = État (up, down, connectivity-change)
#
# Auteur: Chouaib Khamallah
# Version: 1.2.2
# Licence: MIT

# Chemin du fichier de configuration
CONFIG_FILE="/etc/disable-wifi-on-ethernet.conf"

# Configuration par défaut
LOG_FILE="/var/log/disable-wifi-on-ethernet.log"
LOG_LEVEL="INFO"
NOTIFICATIONS_ENABLED="true"
NOTIFICATION_TIMEOUT=6000
NOTIFICATION_ICON="network-wireless-disconnected"
NOTIFICATION_TITLE="WiFi désactivé"
NOTIFICATION_MESSAGE="Une connexion Ethernet est active"
REQUIRE_IP_BEFORE_DISABLING_WIFI="false"
IGNORED_INTERFACES=""
INCLUDE_USERNAME_IN_LOGS="true"

# Charger la configuration personnalisée si elle existe
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Utiliser /tmp comme fallback si on ne peut pas écrire dans le log configuré
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/disable-wifi-ethernet.log"

# Détecter l'utilisateur actuel et le nom d'hôte
CURRENT_USER="$(whoami)"
CURRENT_HOSTNAME="$(hostname)"

# Fonction de log simplifiée avec niveaux et nom d'utilisateur
log() {
    local level="$1"
    local message="$2"
    
    # Vérifier si le niveau de log doit être affiché selon la configuration
    case "$LOG_LEVEL" in
        DEBUG)
            # Afficher tous les messages
            ;;
        INFO)
            # Ne pas afficher les messages DEBUG
            if [ "$level" = "DEBUG" ]; then return; fi
            ;;
        WARN)
            # Ne pas afficher les messages DEBUG et INFO
            if [ "$level" = "DEBUG" ] || [ "$level" = "INFO" ]; then return; fi
            ;;
        ERROR)
            # Ne pas afficher les messages DEBUG, INFO et WARN
            if [ "$level" = "DEBUG" ] || [ "$level" = "INFO" ] || [ "$level" = "WARN" ]; then return; fi
            ;;
    esac
    
    # Détecter l'utilisateur connecté en session graphique
    local gui_user=""
    if [ "$INCLUDE_USERNAME_IN_LOGS" = "true" ]; then
        gui_user="$(who | grep -E '(:0|tty[0-9])' | head -1 | awk '{print $1}')"
        if [ -z "$gui_user" ]; then gui_user="(aucun)"; fi
    fi
    
    # Format du log avec ou sans utilisateur selon la configuration
    if [ "$INCLUDE_USERNAME_IN_LOGS" = "true" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [$level] [hôte:$CURRENT_HOSTNAME] [système:$CURRENT_USER] [session:$gui_user] $message" >> "$LOG_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [$level] $message" >> "$LOG_FILE"
    fi
}

# Arguments
IFACE="$1"
STATUS="$2"

# Log initial
log "DEBUG" "Script démarré avec arguments: $IFACE $STATUS"
log "DEBUG" "Configuration chargée: LOG_FILE=$LOG_FILE, NOTIFICATIONS=$NOTIFICATIONS_ENABLED"

# États à traiter uniquement pour éviter les exécutions inutiles
EVENTS_INTERESSES=("up" "down" "connectivity-change" "dhcp4-change" "dhcp6-change")

# Vérifier si l'état doit être traité (pour éviter la sur-journalisation)
if [[ ! " ${EVENTS_INTERESSES[*]} " =~ " $STATUS " ]]; then
    log "DEBUG" "État '$STATUS' ignoré, terminaison silencieuse"
    exit 0
fi

# Vérifier si une interface est à ignorer
is_ignored_interface() {
    local iface="$1"
    
    for ignored in $IGNORED_INTERFACES; do
        if [ "$iface" = "$ignored" ]; then
            log "DEBUG" "Interface $iface ignorée (dans la liste IGNORED_INTERFACES)"
            return 0  # Vrai, l'interface est à ignorer
        fi
    done
    
    return 1  # Faux, l'interface n'est pas à ignorer
}

# Vérifier si une interface Ethernet est connectée
check_ethernet() {
    log "DEBUG" "Vérification des connexions Ethernet..."
    
    # Méthode 1: Utiliser nmcli
    local interfaces=$(nmcli -t -f DEVICE,TYPE,STATE device | grep -E '^[^:]+:ethernet:connected$' | cut -d: -f1)
    
    if [ -z "$interfaces" ]; then
        log "DEBUG" "Aucune interface Ethernet connectée trouvée via nmcli"
        return 1
    fi
    
    log "DEBUG" "Interfaces Ethernet connectées: $interfaces"
    
    for iface in $interfaces; do
        # Vérifier si l'interface est dans la liste des interfaces à ignorer
        if is_ignored_interface "$iface"; then
            continue
        fi
        
        # Si on exige une adresse IP, vérifier que l'interface en a une
        if [ "$REQUIRE_IP_BEFORE_DISABLING_WIFI" = "true" ]; then
            if ip addr show dev "$iface" 2>/dev/null | grep -q "inet "; then
                log "DEBUG" "Interface Ethernet active avec IP: $iface"
                return 0  # Vrai, une connexion Ethernet valide est active
            else
                log "DEBUG" "Interface Ethernet sans IP: $iface"
            fi
        else
            # Pas besoin de vérifier l'adresse IP
            log "DEBUG" "Interface Ethernet active: $iface"
            return 0  # Vrai, une connexion Ethernet est active
        fi
    done
    
    log "DEBUG" "Aucune connexion Ethernet valide selon les critères définis"
    return 1
}

# Désactiver le WiFi avec plusieurs méthodes
disable_wifi() {
    log "INFO" "Tentative de désactivation du WiFi"
    
    # Méthode 1: nmcli
    if nmcli radio wifi off; then
        log "INFO" "WiFi désactivé avec nmcli"
        return 0
    fi
    
    log "WARN" "Échec avec nmcli, essai avec rfkill..."
    
    # Méthode 2: rfkill
    if command -v rfkill &> /dev/null; then
        if rfkill block wifi; then
            log "INFO" "WiFi désactivé avec rfkill"
            return 0
        fi
    fi
    
    log "WARN" "Échec avec rfkill, essai avec iwconfig..."
    
    # Méthode 3: iwconfig (obsolète mais peut fonctionner sur certains systèmes)
    if command -v iwconfig &> /dev/null; then
        for wface in $(iwconfig 2>/dev/null | grep -o "^[a-zA-Z0-9]\+"); do
            if ifconfig "$wface" down; then
                log "INFO" "WiFi désactivé avec ifconfig $wface down"
                return 0
            fi
        done
    fi
    
    log "ERROR" "Échec de la désactivation du WiFi avec toutes les méthodes"
    return 1
}

# Vérifier si le WiFi est activé
is_wifi_enabled() {
    if nmcli radio wifi | grep -q "enabled"; then
        log "DEBUG" "WiFi est actuellement activé"
        return 0
    else
        log "DEBUG" "WiFi est déjà désactivé"
        return 1
    fi
}

# Envoyer une notification
send_notification() {
    local message="$1"
    
    # Vérifier si les notifications sont activées
    if [ "$NOTIFICATIONS_ENABLED" != "true" ]; then
        log "DEBUG" "Notifications désactivées, notification ignorée"
        return
    fi
    
    # Trouver l'utilisateur de la session graphique
    USER=$(who | grep -E '(:0|tty[0-9])' | head -1 | awk '{print $1}')
    
    if [ -n "$USER" ]; then
        log "DEBUG" "Tentative d'envoi de notification à l'utilisateur $USER"
        
        # Essayer d'envoyer la notification
        su - "$USER" -c "DISPLAY=:0 notify-send -i $NOTIFICATION_ICON -t $NOTIFICATION_TIMEOUT '$NOTIFICATION_TITLE' '$message'" &> /dev/null || true
        
        # On ne vérifie pas le succès car ce n'est pas critique
    else
        log "DEBUG" "Aucun utilisateur de session graphique trouvé pour la notification"
    fi
}

# Fonction principale
main() {
    # Vérifier si une connexion Ethernet est active
    if check_ethernet; then
        log "DEBUG" "Connexion Ethernet active détectée"
        
        # Vérifier si le WiFi est activé
        if is_wifi_enabled; then
            log "INFO" "WiFi est activé, connexion Ethernet active → désactivation du WiFi"
            
            # Désactiver le WiFi
            if disable_wifi; then
                log "INFO" "WiFi désactivé avec succès"
                
                # Envoyer une notification
                send_notification "$NOTIFICATION_MESSAGE"
            else
                log "ERROR" "Échec de la désactivation du WiFi"
            fi
        else
            log "DEBUG" "WiFi déjà désactivé, aucune action nécessaire"
        fi
    else
        log "DEBUG" "Aucune connexion Ethernet active, aucune action nécessaire"
    fi
    
    log "DEBUG" "Script terminé"
}

# Exécuter la fonction principale
main

exit 0