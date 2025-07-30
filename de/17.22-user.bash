#!/bin/bash
if [ $# -ne 1 ]
#Pruefen ob eine Datei uebergeben wurde
then
        echo "usage: $0 <csv-Datei>"
        exit 1
fi
CSV_DATEI=$1
#Oeffnen der Datei zum lesen
exec 3< $CSV_DATEI
# Erste Zeile einlesen
HEADER=$(line <&3)
#Erste Zeile als Ueberschrift anzeigen
echo $HEADER
#Anzahl der Felder ermitteln
ARG_ANZAHL=$( echo "$HEADER" | awk -F\; '{print NF}')
#Fuer jede Zeile durchlaufen
while read LINE <&3
do
        #Alle Argumente einer Zeile in ein Array schreiben
        for((i=1; i<$ARG_ANZAHL; i++))
        do
                USER_ARRAY[$i]=$(echo $LINE | cut -d\; -f"$i")
        done
#Anlegen des Benutzers
echo samba-tool user create ${USER_ARRAY[8]} ${USER_ARRAY[9]}  --must-change-at-next-login --use-username-as-cn --userou=${USER_ARRAY[1]} --surname=${USER_ARRAY[2]} --given-name=${USER_ARRAY[3]} --home-drive=${USER_ARRAY[4]} --home-directory=${USER_ARRAY[5]} --profile-path=${USER_ARRAY[6]} --mail-address=${USER_ARRAY[7]}
done
