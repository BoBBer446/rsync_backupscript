## Beschreibung

Dieses Repository enthält ein Bash-Skript zur automatisierten Sicherung wichtiger Verzeichnisse von Servern auf ein NAS-Gerät oder andere remote Server. Das Skript unterstützt mehrere Server und ermöglicht die Verwaltung von Backup-Retention sowie Logdateien. 
Es ist darauf ausgelegt, tägliche Backups durchzuführen und alte Backups sowie Logdateien automatisch zu löschen, um Speicherplatz zu sparen.

## Voraussetzungen

- `sshpass`: Zum automatischen Übergeben des Passworts für SSH.
- `rsync`: Zum effizienten Kopieren und Synchronisieren von Dateien.

## Installation

1. Klone das Repository:
    ```sh
    git clone https://github.com/deinbenutzername/server-backup-script.git
    ```
2. Navigiere zum Skriptverzeichnis:
    ```sh
    cd server-backup-script
    ```

3. Stelle sicher, dass das Skript ausführbar ist:
    ```sh
    chmod +x sync_to_nas.sh
    ```

## Konfiguration

Das Skript verwendet mehrere Konfigurationsvariablen, die an den Anfang des Skripts gesetzt werden sollten:

```bash
NAS_USER="rsyncuser"
NAS_PASSWORD="dein_passwort"
NAS_IP="REMOTE-IP"
SSH_PORT="REMOTE-PORT"
BACKUP_RETENTION_DAYS=1
LOG_RETENTION_COUNT=50
LOG_DIR="/pfad/zu/deinem/logverzeichnis"
```

Zusätzlich gibt es ein assoziatives Array `SRC_PATHS_MAP`, das die Quellverzeichnisse für jeden Server definiert:

```bash
declare -A SRC_PATHS_MAP=(
    ["server1"]="
        /etc
        /var/lib/docker/
    "
    ["server2"]="
        /etc
        /home/benutzer_eins
        /home/benutzer_zwei
    "
)
```

## Verwendung

1. Passe die `Konfigurationsvariablen` und das `SRC_PATHS_MAP` an deine Bedürfnisse an.
2. Führe das Skript manuell aus, um sicherzustellen, dass es funktioniert:
    ```sh
    sudo bash sync_to_nas.sh
    ```

## Automatisierung mit Cron

Um das Skript täglich um Mitternacht automatisch auszuführen, füge es zur `crontab` hinzu:

```sh
sudo crontab -e
```

Füge folgende Zeile hinzu:

```sh
0 0 * * * /pfad/zu/deinem/script/sync_to_nas.sh
```

## Fehlerbehebung

- Stelle sicher, dass `sshpass` und `rsync` installiert sind.
- Überprüfe die Berechtigungen und den Pfad des Skripts.
- Schaue dir die Logdateien im definierten Logverzeichnis an, um detaillierte Fehlermeldungen zu erhalten.

## Lizenz

Dieses Projekt ist unter der Apache License 2.0 lizenziert.
