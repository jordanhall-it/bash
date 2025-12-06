#!/bin/bash

# Author: Jordan Hall
# Date: 12/07/2025
# Description: This script reads a user list file and creates department groups if they don't exist.

# Check for root privileges
if [ $UID -ne 0 ]
then
echo "This script must be run as root"
exit 1
fi

# Check for file argument
if [ "$#" -ne 1 ]
then
echo "Usage: ${0} USERFILE" >&2
echo >&2
echo "File format (CSV):"
echo " username,department,full_name/description" >&2
exit 1
fi

USERFILE="${1}"

if [ ! -f "${USERFILE}" ]
then
echo "Error: File '${USERFILE}' does not exist" >&2
exit 1
fi

echo "Processing user file ${USERFILE}"
echo

# Extract unique departments from user file
DEPARTMENTS=$(cut -d ',' -f2 "${USERFILE}" | sort -u)

echo "Departments found:"
echo "${DEPARTMENTS}"
echo

# Create groups if they don't exist
for dept in ${DEPARTMENTS}
do
if getent group "$dept" &> /dev/null
then
echo "Group ${dept} already exists"
else
groupadd "${dept}"
if [ "$?" -eq 0 ]
then
echo "Created group ${dept}"
else
echo "Failed to create ${dept}" >&2
fi
fi
done

echo
echo "Group creation complete."
echo
echo "Existing department groups:"
for dept in ${DEPARTMENTS}
do
echo "${dept}: GID $(getent group "${dept}" | cut -d: -f3)"
done
