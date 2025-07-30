#!/bin/bash

# Hier wird eine temporäre Datei erzeugt
CHANGE_DATEI=$(mktemp)
USER_DATEI=$(mktemp)

# Hier muss Ihr Suffix stehen
SUFFIX="dc=example,dc=net"

# Funktion zum Abfangen von STRG+C
CTRL_C(){
echo
echo "Signal STRG+C erhalten "
echo -n  "Skript beenden (j/n) : "
read 
if [[ $REPLY = "j"  ]]
then 
        rm $CHANGE_DATEI $USER_DATEI
        exit 9
fi
}
# Funktion für die Pausen im Skript
pause(){ echo Weiter mit RETURN; read; }

trap 'CTRL_C' 2
# Einlesen des Startpunkts der Suche
# nach Benutzern die geändert werden sollen
while [ -z "$START_OU" ]
do
        clear
        echo
        echo -n "Bitte Startpunkt der Suche eingeben (EXIT für Ende) : "
        read START_OU
done
if [ "$START_OU" = "EXIT" ]
then
        clear
        rm $CHANGE_DATEI $USER_DATEI
        exit 0
fi
START_OU=$(echo $START_OU | awk '{print tolower($START_OU)}')
# Eine Änderung ab dem Suffix würde Systembenutzer ändern
# Deshalb wird das unterbunden
if [ "$START_OU" = "$SUFFIX" ]
then
        echo --------------------------------------------
        echo "$START_OU ist gleich $SUFFIX"
        echo "Das würde auch Systembenutzer betreffen"
        echo "Dieses wird nicht unterstützt"
        echo --------------------------------------------
        pause
        rm $CHANGE_DATEI $USER_DATEI
        exit 1
fi
# Hier wird geprüft ob der Startpunkt existiert
START_OU_J=$(ldbsearch --url=/var/lib/samba/private/sam.ldb | grep -i  "dn: $START_OU$")
if [ -z "$START_OU_J" ]
then
        echo ------------------------------------------------------------
        echo "$START_OU ist nicht vorhanden oder falsch geschrieben !"
        echo ------------------------------------------------------------
  pause
        rm $CHANGE_DATEI $USER_DATEI
        exit 2
fi
echo
echo Das ist der Startpunkt der Suche:  $START_OU
echo 

#Schreiben der gefunden Benutzer in eine Datei
ldbsearch --url=/var/lib/samba/private/sam.ldb -b $START_OU objectclass=user attr dn  | grep ^dn  > $USER_DATEI
# An dieser Stelle muss eine gültige LDIF-Datei
# mit den eingetragenen Änderungen angegeben werden
while [ -z "$LDIF_DATEI" ]
do
        echo
        echo -n "Bitte LDIF-Datei angeben : "
        read LDIF_DATEI
done

if [ -e "$LDIF_DATEI" ]
then
        echo -----------------------------------------
        echo "Datei ist $CHANGE_DATEI"
  echo -----------------------------------------
#Oeffnen der Datei mit alle Benutzern zum lesen
        exec 3< $USER_DATEI
        while read LINE <&3
        do
                echo Zeile = $LINE
                echo ------------------
                #Der Benutzer wird geschrieben
                echo $LINE >> $CHANGE_DATEI
                #Jetzt wir die Änderung angehängt
                cat $LDIF_DATEI >> $CHANGE_DATEI
        done
        exec 3>&-
fi
while [ true ]
do
unset WAHL
unset LDIF_AENDERUNG
unset LDIF_UEBER
clear
cat <<EOT
---------------------------------------------------------------------------
Änderungen können direkt ins Active Directory geschrieben werden......(1)

Änderungen in eine Datei schreiben. ..................................(2)

Nichts machen und Skript verlassen....................................(3)

---------------------------------------------------------------------------
EOT
while [ -z "$WAHL" ]
do
        echo -n "Bitte wählen Sie (1/2/3) :"
        read WAHL
done
# Je nach Auswahl werden die Änderungen direkt in das AD geschrieben
# oder in einer Datei gespeichert
case "$WAHL" in
1) 
         echo ldbmodify -H /var/lib/samba/private/sam.ldb $CHANGE_DATEI
         rm $CHANGE_DATEI $USER_DATEI
         exit 0;;
2) 
   while [ -z "$LDIF_AENDERUNG" ]
         do
                 echo
         echo -n "Dateiname für die Änderungen angeben : "
                 read LDIF_AENDERUNG
# Wenn die Datei vorhanden ist wird gewarnt              
                 if [ -f "$LDIF_AENDERUNG" ]
                 then
                         while [ -z "$LDIF_UEBER" ]
                         do
                                 echo
                         echo -n "Datei $LDIF_AENDERUNG existiert! Überschreiben (j/n) : "
                                 read LDIF_UEBER
                                 LDIF_UEBER=$(echo $LDIF_UEBER | tr 'A-Z' 'a-z')
                         done
                         if [ "$LDIF_UEBER" = "n" ]
                         then
                                        echo "Datei wird nicht überschrieben"
                                        pause
                                 continue 2
                         else 
                                 if [ $LDIF_UEBER = "j" ]
                                 then
                                         cat $CHANGE_DATEI > $LDIF_AENDERUNG
                                         echo "Datei geschrieben "
                                         pause
                                         exit 0
                                 else
                                   echo "Falsche Auswahl nur j/n möglich"
                                         pause
                                         continue
                           fi
                   fi
           fi    
         done
         cat $CHANGE_DATEI > $LDIF_AENDERUNG
         echo "Datei geschrieben "
         pause
         exit 0
         ;;
3)
        rm $CHANGE_DATEI
        exit 5;; 
*)
        echo " Falsche Auswahl !"
        pause
        continue
esac
done
cat $CHANGE_DATEI
rm $CHANGE_DATEI $USER_DATEI

