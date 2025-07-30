#!/bin/bash

# Define domain variables
DOMAIN="example.net"
ZONE="_msdcs.$DOMAIN"
SAMBA_USER="administrator"  # Define the username to execute the samba-tool command
BASE_DN="dc=example,dc=net"

# Get the PDC Emulator DC, extract server name, convert to lowercase
PDC_EMULATOR=$(samba-tool fsmo show | grep 'PdcEmulationMasterRole' |awk -F, '{print $2}' | cut -d= -f2 | tr '[:upper:]' '[:lower:]')
echo "PDC Emulator (lowercase): $PDC_EMULATOR"

# Set SAMBA_SERVER to the PDC Emulator
SAMBA_SERVER=$PDC_EMULATOR
echo "SAMBA Server (PDC Emulator): $SAMBA_SERVER"

# Check DNS SRV records specifically for the PDC emulator and format nicely
echo "Checking DNS SRV records for the PDC Emulator..."
DNS_SRV_RECORDS=$(host -t SRV _ldap._tcp.pdc.$ZONE | awk '/has SRV record/ {print $NF}' | sed 's/.$//' | tr '[:upper:]' '[:lower:]')

# Output DNS SRV entries
echo "Found DNS SRV records:"
echo "$DNS_SRV_RECORDS"

# Loop through DNS SRV records and compare hostnames with the PDC Emulator 
    for DNS_ENTRY in $DNS_SRV_RECORDS; do
    # Extract just the hostname from the DNS entry
    DNS_HOSTNAME=$(echo "$DNS_ENTRY" | cut -d. -f1)

    if [ "$DNS_HOSTNAME" != "$PDC_EMULATOR" ]; then
         echo "Incorrect DNS entry found: $DNS_ENTRY. Deleting..."

   # Use samba-tool to delete the incorrect DNS entry with the correct format
        samba-tool dns delete $SAMBA_SERVER.$DOMAIN $ZONE _ldap._tcp.pdc SRV "$DNS_ENTRY 389 0 100" -U $SAMBA_USER
        if [ $? -eq 0 ]; then
            echo "Successfully deleted incorrect DNS entry: $DNS_ENTRY"
        else
            echo "Failed to delete DNS entry: $DNS_ENTRY"
        fi
    else
        echo "Correct DNS entry: $DNS_ENTRY"
    fi
done

echo "PDC Emulator and DNS validation completed."

