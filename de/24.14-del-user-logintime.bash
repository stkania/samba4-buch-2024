#!/bin/bash
#
#
# Version 2.0 now time is calculated via UTC
# so the script will work in all timezones
#
#Name of the group that allows members to login via ssh on a DC
GROUP_NAME=sshlogin
# Read the actual time in UNIX-time format
ACTUAL_UTC=$(date -u +'%Y-%m-%d %H:%M:%S')
ACTUAL_TIME=$(date -u +%s --date "$ACTUAL_UTC")
# create a temp-file to remove the sshlogintime from user
DEL_USER_LDIF=$(mktemp)
# create an array with all members of the group GROUP_NAME
USER_LIST=$(samba-tool group listmembers $GROUP_NAME)
for i in ${USER_LIST[*]}
do
        # get the content of the attribute sshlogintime from user $i
        MAX_LOGIN_TIME=$(samba-tool user show $i | grep sshlogintime | cut -d " " -f2)
        # If value of the current time is bigger or equal to sshlogintime
        if [ $ACTUAL_TIME -ge $MAX_LOGIN_TIME ]
        then
                # create a LDIF to remove the attribute sshlogintime
                        DN_USER_NAME=$(samba-tool user show $i | grep ^dn:)
                        exec 3>$DEL_USER_LDIF
                        echo "$DN_USER_NAME" >&3
                        echo "changetype: modify" >&3
                        echo "delete: sshlogintime" >&3
                        exec 3>&-
                        #change the user
                        # remove user $i from group GROUP_NAME
                        samba-tool group removemembers $GROUP_NAME $i
                        # Modify the user -object
                        ldbmodify -H /var/lib/samba/private/sam.ldb $DEL_USER_LDIF
                        echo User $i was removed from group  $GROUP_NAME
                        echo Logintime for user $i was removed
                        rm $DEL_USER_LDIF
        fi
done
