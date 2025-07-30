#!/bin/bash

SAMBA_VER=$(samba -V | awk '{print $2}'| awk -F . '{print $2}')
DEL_OBJ=$(mktemp)
DEL_DNS=$(mktemp)
OBJ_SUFFIX="dc=example,dc=net"
DNS_SUFFIX="dc=DomainDnsZones,dc=example,dc=net"
COUNTER_OBJ=1
COUNTER_DNS=1
URL="/var/lib/samba/private/sam.ldb"

if [ "$SAMBA_VER" -ge 20 ]
then
        echo 'Bei einer Samba-Version größer Samba 4.19 verwenden Sie' 
        echo 'das Kommando <samba-tool domain tombstones expunge --tombstone-lifetime=0>'
        echo 'um alle als gelöcht markierten Objekte zu entfernen.'
        echo 'Wollen Sie dieses Skript nutzen, deaktivieren Sie die Prüfung'
        exit 1
fi


ldbsearch --url=$URL -b $OBJ_SUFFIX --show-deleted | grep ^dn: | grep 0ADEL > $DEL_OBJ
ldbsearch --url=$URL -b $DNS_SUFFIX --show-deleted | grep ^dn: | grep 0ADEL > $DEL_DNS
echo -----------------------------------------------
echo "Delete all as delteted marked objects from the database"
echo -----------------------------------------------
echo
exec 3< $DEL_OBJ
while read LINE <&3
do
  echo $LINE
  ldbdel --url=$URL "$LINE"
  echo "$COUNTER_OBJ objects deleted"
  COUNTER_OBJ=$((COUNTER_OBJ+1))
done
exec 3>&-
echo
echo ----------------------------------------------------
echo "Delete all as deleted marked DNS-objects from the DNS-database"
echo ----------------------------------------------------
echo
exec 3< $DEL_DNS
while read LINE <&3
do
  echo $LINE
  ldbdel --url=$URL "$LINE"
  echo "$COUNTER_DNS DNS-objects deleted"
  COUNTER_DNS=$((COUNTER_DNS+1))
done
exec 3>&-
rm $DEL_OBJ $DEL_DNS
