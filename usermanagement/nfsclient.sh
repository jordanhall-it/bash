#!/bin/bash
# Author: Jordan Hall
# Date: 12/07/2025
# Description: This script will automatically detect department shares on the nfs server, create mount points, and add them to the /etc/fstab for persistent mount.

NFS_SERVER="10.0.0.223"
MOUNT_BASE="/mnt"

# Check for root privileges
if [ ${UID} -ne 0 ]
then
	echo "This script must be run by root."
	exit 1
fi

# Set log file
LOGFILE="/var/log/nfsclient.log"

log () {
        local level="$1"
        shift
        local message="$(date '+%Y%m%d-%H%M%S') [$level] $*"
        echo ${message}
        echo ${message} >> ${LOGFILE}
}

echo "=== Setting up NFS Client Mounts ==="

# Install NFS client utilities
log INFO "Installing NFS client packages"
dnf install -y nfs-utils

# Test NFS server connectivity
log INFO "Testing connection to NFS server at ${NFS_SERVER}..."
if ! showmount -e "${NFS_SERVER}" > /dev/null 2>&1
then
	log ERROR "Cannot reach NFS server at ${NFS_SERVER}"
	echo "Please verify:"
	echo " - NFS server IP is correct"
	echo " - NFS server is running"
	echo " - Firewall allows NFS traffic"
	exit 1
fi

log INFO "Successfully connected to NFS server"
echo
echo "Available exports from ${NFS_SERVER}:"
showmount -e "${NFS_SERVER}"

# Get a list of available shares from the server
SHARES=$(showmount -e "${NFS_SERVER}" | grep "^/nfs/" | awk '{print $1}')

if [ -z "${SHARES}" ]
then
	log ERROR "No /nfs/* shares found on server"
	echo "Make sure the NFS server has department shares configured."
	exit 1
fi

# Store shares in array
DEPT_SHARES=()
while IFS= read -r share
do
	DEPT_SHARES+=("${share}")
done <<< "${SHARES}"

log INFO "Found ${#DEPT_SHARES[@]} department share(s):"

for share in "${DEPT_SHARES[@]}"
do
	dept_name=$(basename "${share}")
	echo " - ${share} will mount at ${MOUNT_BASE}/${dept_name}"
done

# Create mount points for each detected share
echo
log INFO "Creating mount point directories..."

mount_point="${MOUNT_BASE}/${dept_name}"

for share in "${DEPT_SHARES[@]}"
do

	dept_name=$(basename "${share}")
        mount_point="${MOUNT_BASE}/${dept_name}"

	if [ ! -d "${mount_point}" ]
	then
		mkdir -p "${mount_point}"
		log INFO " - Created ${mount_point}"
	else
		log INFO " - ${mount_point} already exists"
	fi
done

# Backup fstab
echo
log INFO "Configuring persistent mounts in /etc/fstab"
cp /etc/fstab /etc/fstab.bak.$(date +%Y%m%d-%H%M%S)

# Add entries to /etc/fstab/ for persistent mounts
for share in "${DEPT_SHARES[@]}"
do
	
	dept_name=$(basename "${share}")
        mount_point="${MOUNT_BASE}/${dept_name}"

        # Check if entry already exists
	if grep -q "${NFS_SERVER}:${share}" /etc/fstab
	then
		log WARN " - ${share} entry already in /etc/fstab"
	else
		echo "${NFS_SERVER}:${share}     ${mount_point}     nfs     defaults,_netdev     0 0" >> /etc/fstab
		log INFO " - Added ${share} to /etc/fstab"
	fi
done

# Mount all NFS shares
echo
log INFO "Mounting NFS shares..."
mount -a

# Verify mounts
echo
echo "=== Mounted NFS Shares ==="
df -h | grep nfs

echo
echo "=== Mount Status ==="
mount_success=0
mount_fail=0

for share in "${DEPT_SHARES[@]}"
do
	
	dept_name=$(basename "${share}")
        mount_point="${MOUNT_BASE}/${dept_name}"
	if mountpoint -q "${mount_point}"
	then
		log INFO "${mount_point} is mounted"
		((mount_success++))
	else
		log ERROR "${mount_point} is NOT mounted"
		((mount_fail++))
	fi
done

echo
echo "=== Setup Complete ==="
log INFO "Successfully mounted: ${mount_success}"
log INFO "Failed to mount: ${mount_fail}"
echo

if [ ${mount_success} -gt 0 ]
then
	log INFO "NFS shares mounted at:"
	for share in "${DEPT_SHARES[@]}"
	do
		
	        dept_name=$(basename "${share}")
                mount_point="${MOUNT_BASE}/${dept_name}"
		echo " - ${mount_point}"
	done
fi




