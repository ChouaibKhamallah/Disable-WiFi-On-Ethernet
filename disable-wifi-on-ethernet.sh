#!/bin/bash
#
# disable-wifi-on-ethernet.sh
#
# Description:
#   Script NetworkManager qui désactive automatiquement le Wi-Fi lorsqu'une 
#   connexion Ethernet est active. Ce script est conçu pour être utilisé comme 
#   un dispatch script de NetworkManager, et sera exécuté à chaque changement 
#   d'état des interfaces réseau.
#
# Usage:
#   Ce script est normalement appelé par NetworkManager avec deux arguments:
#   $1 = Interface (ex: eth0, wlan0)
#   $2 = État (up, down, connectivity-change)
#
# Dépendances:
#   - NetworkManager
#   - notify-send (libnotify-bin)
#
# Auteur: Chouaib Khamallah
# Version: 1.0.0
# Licence: MIT

# Configuration
LOG_FILE="/tmp/force-wifi-off.log"
NOTIFICATION_TIMEOUT=6000  # Durée d'affichage de la notification en ms
NOTIFICATION_ICON="network-wireless-disconnected"

# Arguments
IFACE="$1"
STATUS="$2"

# États à traiter uniquement pour éviter les exécutions inutiles
EVENTS_INTERESSES=("up" "down" "connectivity-change")
if [[ ! " ${EVENTS_INTERESSES[*]} " =~ " $STATUS " ]]; then
    exit 0
fi

# Fonction de journalisation
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Vérifie si NetworkManager est disponible
if ! command -v nmcli &> /dev/null; then
    log "ERREUR: NetworkManager (nmcli) n'est pas installé. Sortie."
    exit 1
fi

# Détection de l'utilisateur de session graphique via 'who'
get_logged_in_user() {
    who | awk '$2 ~ /tty[0-9]/ || $2 ~ /:0/ { print $1; exit }'
}

USERNAME=$(get_logged_in_user)
if [ -z "$USERNAME" ]; then
    log "Aucun utilisateur connecté en session graphique détecté."
else
    log "Utilisateur détecté: $USERNAME"
    USER_ID=$(id -u "$USERNAME" 2>/dev/null)
    USER_HOME=$(getent passwd "$USERNAME" | cut -d: -f6)
    
    # Récupération de l'adresse DBus de l'utilisateur (si disponible)
    if [ -n "$USER_ID" ]; then
        export XDG_RUNTIME_DIR="/run/user/$USER_ID"
        export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
    fi
fi

# Fonction pour envoyer une notification à l'utilisateur
notify() {
    local message="$1"
    
    if [ -n "$USERNAME" ] && [ -n "$DBUS_SESSION_BUS_ADDRESS" ]; then
        sudo -u "$USERNAME" DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS \
            notify-send \
            -u normal \
            -i "$NOTIFICATION_ICON" \
            -t "$NOTIFICATION_TIMEOUT" \
            "🔒 Activation du Wi-Fi interdite" \
            "$message"
        
        log "Notification envoyée à l'utilisateur $USERNAME"
    else
        log "Aucune session graphique détectée — notification ignorée."
    fi
}

# Vérifie si une connexion Ethernet est active
ethernet_connected() {
    nmcli -t -f DEVICE,TYPE,STATE device | grep -E '^.+:ethernet:connected$' > /dev/null
    return $?
}

# Log initial
log "Changement d'état détecté : interface=${IFACE:-(inconnue)}, état=${STATUS:-(inconnu)}, utilisateur=${USERNAME:-(inconnu)}"

# Vérification principale
if ethernet_connected; then
    log "Connexion Ethernet active détectée."
    
    # Vérifier si le Wi-Fi est activé
    if nmcli radio wifi | grep -q enabled; then
        log "Wi-Fi activé manuellement par ${USERNAME:-(inconnu)} → désactivation forcée."
        nmcli radio wifi off
        notify "Connexion filaire active – activation du Wi-Fi interdite"
    else
        log "Wi-Fi déjà désactivé. Aucune action nécessaire."
    fi
else
    log "Aucune connexion Ethernet active. Le Wi-Fi peut rester activé."
fi

exit 0