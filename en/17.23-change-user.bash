#!/bin/bash

# Hier wird eine temporäre Datei erzeugt
CHANGE_FILE=$(mktemp)
USER_FILE=$(mktemp)

# Hier muss Ihr Suffix stehen
SUFFIX="dc=example,dc=net"

# Funktion zum Abfangen von STRG+C
CTRL_C(){
echo
echo "Signal STRG+C  "
echo -n  "Stop script (y/n) : "
read 
if [[ $REPLY = "y"  ]]
then 
        rm $CHANGE_FILE $USER_FILE
        exit 9
fi
}
# Pause-function
pause(){ echo Continue with RETURN; read; }

trap 'CTRL_C' 2
# Read startpoint and search
# for users to change
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
# A change startin from suffix woulds change system users
# this will be prohibited
if [ "$START_OU" = "$SUFFIX" ]
then
        echo --------------------------------------------
        echo "$START_OU equals $SUFFIX"
        echo "That would also change system users"
        echo "This is not supported"
        echo --------------------------------------------
        pause
        rm $CHANGE_FILE $USER_FILE
        exit 1
fi
# chaeck if starpoint exists
START_OU_J=$(ldbsearch --url=/var/lib/samba/private/sam.ldb | grep -i  "dn: $START_OU$")
if [ -z "$START_OU_J" ]
then
        echo ------------------------------------------------------------
        echo "$START_OU not present !"
        echo ------------------------------------------------------------
  pause
        rm $CHANGE_FILE $USER_FILE
        exit 2
fi
echo
echo The search will start at:  $START_OU
echo 
# write all found users into a file
ldbsearch --url=/var/lib/samba/private/sam.ldb -b $START_OU objectclass=user attr dn  | grep ^dn  > $USER_FILE
# At this point you have to give
# a ldif-file with all the changes
while [ -z "$LDIF_FILE" ]
do
        echo
        echo -n "LDIF-files please : "
        read LDIF_FILE
done

if [ -e "$LDIF_FILE" ]
then
        echo -----------------------------------------
        echo "This is  $CHANGE_FILE"
  echo -----------------------------------------
# Open file with all users to read
        exec 3< $USER_FILE
        while read LINE <&3
        do
                echo line = $LINE
                echo ------------------
                #user will be writen to file
                echo $LINE >> $CHANGE_FILE
                #the user will be append to file
                cat $LDIF_FILE >> $CHANGE_FILE
        done
        exec 3>&-
fi
while [ true ]
do
unset WAHL
unset LDIF_CHANGE
unset LDIF_OVER
clear
cat <<EOT
---------------------------------------------------------------------------
Write all changes directly into Active Directory..................(1)

Write chages into file. ..........................................(2)

Don't do anything leave script....................................(3)

---------------------------------------------------------------------------
EOT
while [ -z "$WAHL" ]
do
        echo -n "choose  (1/2/3) :"
        read WAHL
done
case "$WAHL" in
1) 
         echo ldbmodify -H /var/lib/samba/private/sam.ldb $CHANGE_FILE
         rm $CHANGE_FILE $USER_FILE
         exit 0;;
2) 
   while [ -z "$LDIF_CHANGE" ]
         do
                 echo
         echo -n "Filename for changes : "
                 read LDIF_CHANGE
# If file allreay exists show warning                 
                 if [ -f "$LDIF_CHANGE" ]
                 then
                         while [ -z "$LDIF_OVER" ]
                         do
                                 echo
                         echo -n "FILE $LDIF_CHANGE exists! overwrite (y/n) : "
                                 read LDIF_OVER
                                 LDIF_UEBER=$(echo $LDIF_OVER | tr 'A-Z' 'a-z')
                         done
                         if [ "$LDIF_UEBER" = "n" ]
                         then
                                        echo "File will not be overwriten"
                                        pause
                                 continue 2
                         else 
                                 if [ $LDIF_OVER = "y" ]
                                 then
                                         cat $CHANGE_FILE > $LDIF_CHANGE
                                         echo "File writen"
                                         pause
                                         exit 0
                                 else
                                   echo "Wrong choice y/n possible"
                                         pause
                                         continue
                           fi
                   fi
           fi    
         done
         cat $CHANGE_FILE > $LDIF_CHANGE
         echo "File written "
         pause
         exit 0
         ;;
3)
        rm $CHANGE_FILE
        exit 5;; 
*)
        echo " Wrong choice !"
        pause
        continue
esac
done
cat $CHANGE_FILE
rm $CHANGE_FILE $USER_FILE

