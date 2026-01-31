#!/bin/bash

function show-env-info() {
	clear
    local OUTPUT=/tmp/${FUNCNAME[0]}_$USER.log
    echo >$OUTPUT
    # Befehlsliste als Array speichern
    local CMD_LIST=(
        "env | grep -iv 'LS_COLORS' | sort"
        "pstree -psA"
        "ps aux"
        "ls -la /run/user/$(id -u)"
        "ls -la /tmp"
        "ls ~/thinclient_drives"
        "mount | grep 'user_id='"
        # "top -n 1"
    )
    # Schleife über die Befehle und Ausführung
    for cmd in "${CMD_LIST[@]}"; do
        echo "Führe Befehl aus: $cmd --->"
        echo "Führe Befehl aus: $cmd --->" >> "$OUTPUT"
        # Befehl ausführen und Ausgabe in die Logdatei schreiben
        eval "$cmd" >> "$OUTPUT" #2>&1
        echo "<---" >> "$OUTPUT"
        echo >> "$OUTPUT"
    done

    # Ausgabe der Logdatei (optional)
    echo "Ergebnisse wurden in $OUTPUT gespeichert."
    echo
    #cat $OUTPUT
}

show-env-info &

exit 0
