#!/bin/bash

# Dieses Skript erstellt inkrementelle Backups von definierten Verzeichnissen und speichert sie auf einem NAS.
# Es führt tägliche Backups durch und löscht ältere Logdateien, um Speicherplatz zu sparen.

# Variablen
NAS_USER="rsyncuser"
NAS_PASSWORD="password"
NAS_IP="ip"
HOSTNAME=$(hostname)
NAS_PATH="/volume1/NetBackup/Server/$HOSTNAME"
BACKUP_DIR="$NAS_PATH/Backup"
SSH_PORT="port"
LOG_RETENTION_COUNT=50
LOG_DIR="/home/user/rsync_scripts/logs"

# Assoziatives Array für die Quellverzeichnisse
declare -A SRC_PATHS_MAP=(
    ["host1"]="
        /dir1
        /dir2/scripts
    "
    ["host2"]="
        /etc
        /var/lib
        /var/logs
        /home
    "
)

# Funktion zum Festlegen der Quellverzeichnisse
set_src_paths() {
    if [[ -n "${SRC_PATHS_MAP[$HOSTNAME]}" ]]; then
        SRC_PATHS=($(echo "${SRC_PATHS_MAP[$HOSTNAME]}" | tr -s '[:space:]' '\n'))
    else
        echo "Unbekannter Hostname: $HOSTNAME"
        exit 1
    fi
}

# Funktion zum Erstellen eines neuen Backups
create_backup() {
    echo "Sichere in das Verzeichnis: $BACKUP_DIR"
    sshpass -p $NAS_PASSWORD ssh -p $SSH_PORT $NAS_USER@$NAS_IP "mkdir -p $BACKUP_DIR"

    if [[ $? -ne 0 ]]; then
        echo "Fehler: Verzeichnis $BACKUP_DIR konnte nicht erstellt werden."
        exit 1
    fi

    for SRC_PATH in "${SRC_PATHS[@]}"; do
        echo "Sichere Verzeichnis: $SRC_PATH"
        sshpass -p $NAS_PASSWORD rsync -aRvz -e "ssh -p $SSH_PORT" "$SRC_PATH" $NAS_USER@$NAS_IP:$BACKUP_DIR
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
    mkdir -p $LOG_DIR
    LOG_FILE="$LOG_DIR/backup_$(date +%Y-%m-%d_%H-%M-%S).log"

    set_src_paths

    {
        echo "Backup gestartet am: $(date)"
        create_backup
        delete_old_logs
        echo "Backup abgeschlossen am: $(date)"
    } &> $LOG_FILE
}

# Skript ausführen
main

# Täglich 00:00 ausführen:
# sudo crontab -e
# 0 0 * * * /home/user/rsync_scripts/inkrementelle_backups.sh
