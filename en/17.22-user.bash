#!/bin/bash
if [ $# -ne 1 ]
# check if file is present
then
        echo "usage: $0 <csv-Datei>"
        exit 1
fi
CSV_FILE=$1
# Open file to read
exec 3< $CSV_FILE
# read first line
HEADER=$(line <&3)
# show first line as header
echo $HEADER
# check number of fields
ARG_NUMBER=$( echo "$HEADER" | awk -F\; '{print NF}')
# For every line do
while read LINE <&3
do
        # Each argument from a line write in an array
        for((i=1; i<$ARG_NUMBER; i++))
        do
                USER_ARRAY[$i]=$(echo $LINE | cut -d\; -f"$i")
        done
       # create users
echo samba-tool user create ${USER_ARRAY[8]} ${USER_ARRAY[9]}  --must-change-at-next-login --use-username-as-cn --userou=${USER_ARRAY[1]} --surname=${USER_ARRAY[2]} --given-name=${USER_ARRAY[3]} --home-drive=${USER_ARRAY[4]} --home-directory=${USER_ARRAY[5]} --profile-path=${USER_ARRAY[6]} --mail-address=${USER_ARRAY[7]}
done
