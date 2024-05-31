#!/bin/bash

# Variablen
NAS_USER="rsyncuser"
NAS_PASSWORD="passwort"
NAS_IP="123.456.789.159"
HOSTNAME=$(hostname)
NAS_PATH="/volume1/NetBackup/Server/$HOSTNAME"
SSH_PORT="123"
BACKUP_RETENTION_DAYS=1
LOG_RETENTION_COUNT=50
LOG_DIR="/pfad/zu/deinen/logs"

# Assoziatives Array für die Quellverzeichnisse
declare -A SRC_PATHS_MAP=(
    ["server1"]="
        /etc
        /var/lib/docker/bindmounts
    "
    ["server2"]="
        /etc
        /home/benutzer1
        /home/benutzer2
        /home/benutzer3
    "
)

# Funktion zum Festlegen der Quellverzeichnisse
set_src_paths() {
    if [[ -n "${SRC_PATHS_MAP[$HOSTNAME]}" ]]; then
        # Trimme führende und nachfolgende Leerzeichen und konvertiere die Verzeichnisse in ein Array
        SRC_PATHS=($(echo "${SRC_PATHS_MAP[$HOSTNAME]}" | tr -s '[:space:]' '\n'))
    else
        echo "Unbekannter Hostname: $HOSTNAME"
        exit 1
    fi
}

# Funktion zum Löschen alter Backups
delete_old_backups() {
    echo "Lösche Backups, die älter als $BACKUP_RETENTION_DAYS Tage sind..."
    sshpass -p $NAS_PASSWORD ssh -p $SSH_PORT $NAS_USER@$NAS_IP "find $NAS_PATH -type d -mtime +$BACKUP_RETENTION_DAYS -exec rm -rf {} \;"
}

# Funktion zum Erstellen eines neuen Backups
create_backup() {
    BACKUP_DIR="$NAS_PATH/backup_$(date +%d-%m-%y_%H-%M-%S)"
    echo "Erstelle neues Backup im Verzeichnis: $BACKUP_DIR"
    sshpass -p $NAS_PASSWORD ssh -p $SSH_PORT $NAS_USER@$NAS_IP "mkdir -p $BACKUP_DIR"

    # Prüfe, ob das Verzeichnis erfolgreich erstellt wurde
    sshpass -p $NAS_PASSWORD ssh -p $SSH_PORT $NAS_USER@$NAS_IP "[ -d $BACKUP_DIR ]"
    if [[ $? -ne 0 ]]; then
        echo "Fehler: Verzeichnis $BACKUP_DIR konnte nicht erstellt werden."
        exit 1
    fi

    for SRC_PATH in "${SRC_PATHS[@]}"; do
        echo "Sichere Verzeichnis: $SRC_PATH"
        sshpass -p $NAS_PASSWORD rsync -azvR -e "ssh -o StrictHostKeyChecking=no -p $SSH_PORT" "$SRC_PATH" $NAS_USER@$NAS_IP:$BACKUP_DIR
    done
}

# Funktion zum Löschen alter Logdateien
delete_old_logs() {
    LOG_FILES=($(ls -t $LOG_DIR/*.log))
    LOG_COUNT=${#LOG_FILES[@]}

    if (( LOG_COUNT > LOG_RETENTION_COUNT )); then
        echo "Lösche alte Logdateien..."
        for (( i=LOG_RETENTION_COUNT; i<LOG_COUNT; i++ )); do
            rm -f "${LOG_FILES[$i]}"
        done
    fi
}

# Hauptfunktion
main() {
    # Erstelle Log-Verzeichnis
    mkdir -p $LOG_DIR
    LOG_FILE="$LOG_DIR/backup_$(date +%d-%m-%y_%H-%M-%S).log"

    # Setze die Quellverzeichnisse
    set_src_paths

    # Lösche alte Backups und erstelle neues Backup, logge die Ausgabe
    {
        echo "Backup gestartet am: $(date)"
        delete_old_backups
        create_backup
        delete_old_logs
        echo "Backup abgeschlossen am: $(date)"
    } &> $LOG_FILE
}

# Skript ausführen
main
