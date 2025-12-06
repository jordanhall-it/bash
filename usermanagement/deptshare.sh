#!/bin/bash

# Author: Jordan Hall
# Date: 12/07/2025
# Description: This script will create and configure network shares for new departments on the NFS server.
# Usage: ./deptshare.sh <dept1> <dept2> <dept3> ...

# Set your network here:
NETWORK="10.0.0.223/24"

# Set log file
LOGFILE="/var/log/deptshare.log"

log () {
local level="$1"
shift
local message="$(date '+%Y%m%d-%H%M%S') [$level] $*"
echo ${message}
echo ${message} >> ${LOGFILE}
}

# Check for root privileges
if [ $UID -ne 0 ]
then
echo "ERROR: This script must be run by root."
exit 1
fi

# Check for minimum arguments
if [ "$#" -lt 1 ]
then
log ERROR "Usage: $0 <dept1> <dept2> <dept3> ..."
echo
echo "Example: $0 hr finance it sales marketing"
exit 1
fi

# Store departments in array
DEPARTMENTS=("$@")

log INFO "=== Setting up NFS Server for Department Shares ==="
log INFO "Network: ${NETWORK}"
log INFO "Departments: ${DEPARTMENTS[*]}"

# Install NFS utilities
log INFO "Installing NFS server packages..."
dnf install -y nfs-utils

# Create department directories
log INFO "Installing department share directories..."
for dept in "${DEPARTMENTS[@]}"
do
log INFO "Creating /nfs/${dept}"
mkdir -p "/nfs/${dept}"
if [ $? -ne 0 ]
then
log ERROR "/nfs/${dept} could not be created."
exit 1
fi

# Create department group if it doesn't exist
if ! getent group "${dept}" > /dev/null 2>&1
then
groupadd "${dept}"
log INFO "Created group ${dept}"
else
log INFO "Group ${dept} already exists."
fi

# Set group ownership
chown :"${dept}" "/nfs/${dept}"
if [ $? -ne 0 ]
then
log ERROR "Ownership for /nfs/${dept} could not be set."
exit 1
fi

# Add special permissions for files to retain group ownership
chmod g+s "/nfs/${dept}"
if [ $? -ne 0 ]
then
log ERROR "Special permissions for /nfs/${dept} could not be set."
exit 1
fi
done

echo
log INFO "Configuring NFS exports..."

# Backup existing exports file
if [ -f /etc/exports ]
then
cp /etc/exports /etc/exports.bak.$(date +%Y%m%d-%H%M%S)
log INFO "Backed up existing /etc/exports"
fi

# Add department shares to exports
echo "" >> /etc/exports
echo "# Department NFS Shares - Created $(date)" >> /etc/exports

for dept in "${DEPARTMENTS[@]}"
do
echo "/nfs/${dept}    ${NETWORK}(rw,sync,no_root_squash,no_all_squash)" >> /etc/exports
log INFO "Added export: /nfs/${dept}"
done

# Apply the export configuration
echo
log INFO "Appplying NFS export configuration..."
exportfs -ra

# Configure firewall
log INFO "Configuring firewall for NFS..."
firewall-cmd --add-service nfs --perm
firewall-cmd --add-service rpc-bind --perm
firewall-cmd --add-service mountd --perm
firewall-cmd --reload

# Enable and start NFS server
log INFO "Enabling and starting NFS server..."
systemctl enable --now nfs-server
systemctl restart nfs-server

# Verify NFS is running
echo
echo "=== NFS Server Status ==="
systemctl status nfs-server --no-pager

echo
echo "=== Active NFS exports ==="
exportfs -v

echo
echo "=== Setup Complete ==="
log INFO "NFS shares created for departments ${DEPARTMENTS[*]}"
echo
echo "Shares available at:"
for dept in "${DEPARTMENTS[@]}"
do
echo " - /nfs/${dept}"
done

