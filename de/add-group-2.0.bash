#!/bin/bash
#
# Version 2.0 now time is calculated via UTC
# so the script will work in all timezones
#
if [ $# -ne 2 ]
then
	echo usage: $0 sAMAccountName minutes-for-login
	exit 10
fi
#Name of the group that allows members to login via ssh on a DC
GROUP_NAME=sshlogin
# Minutes a user can login vis ssh. 
# During this time he can login and logoff as often as he like
SESSION_TIME_MIN=$2
# Calculate the tim in seconds
SESSION_TIME_SEC=$((SESSION_TIME_MIN * 60 ))
# Username must be a sAMAccountName
USER_NAME=$1
# Read the actual time in UNIX-time format
# Time will be UTC-time
ACTUAL_UTC=$(date -u +'%Y-%m-%d %H:%M:%S')
START_TIME=$(date -u +%s --date "$ACTUAL_UTC")
STOP_TIME_SUM=$(($START_TIME + $SESSION_TIME_SEC))
# calculate the end of the logintime 
STOP_TIME=$(date -d @$STOP_TIME_SUM)
# create a temp-file to add the sshlogintime to a user attribute
ADD_USER_LDIF=$(mktemp)

# Search for the user USER_NAME. 
# Only if the user exists AND is member of the group 'domain admins'
# the script will continue
samba-tool user show $USER_NAME 2>/dev/null | grep 'memberOf: CN=Domain Admins' >/dev/null
USER_OK=$?
if [ $USER_OK -ne 0 ]
then
	# If the user is not known or the user is not member of the group domain admins, the skript will exit
	echo " User $1 not known or not a member of the group  Domain Admins "
	exit 1
else
	samba-tool group listmembers "$GROUP_NAME" | grep -i "$USER_NAME"
	USER_IN_SSHLOGIN=$?
	if [ $USER_IN_SSHLOGIN -eq 0 ]
	then 
		echo User $1 is already member of the group  $GROUP_NAME
		exit 2
	else
		# If the user is known and member of the group domain admins
		# he will be added to the group GROUP_NAME
		samba-tool group addmembers $GROUP_NAME $USER_NAME >/dev/null
		ADD_USER_TO_GROUP=$?
		# Create a LDIF to add the logintime to the user-object
		if [ $ADD_USER_TO_GROUP -eq 0 ]
		then
			DN_USER_NAME=$(samba-tool user show $USER_NAME | grep ^dn:)
			exec 3>$ADD_USER_LDIF
			echo "$DN_USER_NAME" >&3
			echo "changetype: modify" >&3
			echo "replace: sshlogintime" >&3
			echo "sshlogintime: $STOP_TIME_SUM" >&3
			exec 3>&-
			#change the user
			ldbmodify -H /var/lib/samba/private/sam.ldb $ADD_USER_LDIF
			echo User $USER_NAME was added to group  $GROUP_NAME
			echo Logintime for user  $USER_NAME will end at  $STOP_TIME
			rm $ADD_USER_LDIF
		else
			echo User $USER_NAME could not be added to group  $GROUP_NAME
			exit 3
		fi
	fi
fi

