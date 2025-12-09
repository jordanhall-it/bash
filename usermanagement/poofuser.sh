#!/bin/bash

# Author: Jordan Hall
# Date: 12/07/2025
# Description: This script will provide the options to delete, disable, and optionally archive the home directory of an account.
# Usage: "${0} [-dra] USER [USERNAME]..."

ARCHIVE_DIR='/archive'

#Set usage message function
usage() {
  echo "Usage: ${0} [-dra] USER [USERNAME]..." >&2
  echo 'Disable a local linux account' >&2
  echo '-d     Delete the user account.' >&2
  echo '-r     Remove the home directory associated with the account.' >&2
  echo "-a     Creates an archive of the user's home directory, stored in /archives." >&2
  exit 1
}

# Enforce superuser privileges
if [[ ${UID} -ne 0 ]]
then
  echo "This command must be run with superuser (root) privileges." >&2
  exit 1
fi

# Set options

while getopts dra OPTION
do
  case ${OPTION} in
  d) 
    DELETE_USER='true'
    ;;
  r)
    REMOVE_OPTION='-r'
    ;;
  a)
    ARCHIVE='true'
    ;;
  *)
    usage
    ;;
  esac
done

# Remove the options while leaving remaining arguments.
shift "$(( OPTIND - 1 ))"

# If the user doesn't supply at least one argument, give them help    
if [[ "${#}" -lt 1 ]]
then
  usage
fi

# Loop through all usernames supplied as arguments.
for USERNAME in "${@}"
do
  echo "Processing user: ${USERNAME}"

  # Make sure the UID of the account is at least 1000.
  USERID=$(id -u ${USERNAME})
  if [[ "${USERID}" -lt 1000 ]]
  then
    echo "Refusing to remove the ${USERNAME} account with UID ${USERID}." >&2
    exit 1
  fi

  # Create an archive if requested to do so.
  if [[ "${ARCHIVE}" = 'true' ]]
  then
    # Make sure the ARCHIVE_DIR directory exists
    if [[ ! -d "${ARCHIVE_DIR}" ]]
    then
      echo "Creating ${ARCHIVE_DIR} directory."
      mkdir -p ${ARCHIVE_DIR}
      if [[ "${?}" -ne 0 ]]
      then
        echo "The archive directory ${ARCHIVE_DIR} could not be created." >&2
        exit 1
      fi
    fi

    # Archive the user's home directory and move it into the ARCHIVE_DIR.
    HOME_DIR=$(getent passwd "${USERNAME}" | cut -d: -f6)
    ARCHIVE_FILE="${ARCHIVE_DIR}/${USERNAME}.tgz"
    if [[ -d "${HOME_DIR}" ]]
    then
      echo "Archiving ${HOME_DIR} to ${ARCHIVE_FILE}"
      tar -zcf ${ARCHIVE_FILE} ${HOME_DIR} &> /dev/null
      if [[ "${?}" -ne 0 ]]
      then
        echo "Could not create ${ARCHIVE_FILE}." >&2
        exit 1
      fi
    else
      echo "${HOME_DIR} does not exist or is not a directory." >&2
      exit 1
    fi
  fi
  
  if [[ "${DELETE_USER}" = 'true' ]]
  then
    # Delete the user
    userdel ${REMOVE_OPTION} ${USERNAME}

    # Check to see if userdel command was successful
    if [[ "${?}" -ne 0 ]]
    then
      echo "The account ${USERNAME} was NOT deleted." >&2
      exit 1
    else
      echo "The account ${USERNAME} was deleted."
    fi
  else
    # Check to see if chage command was successful
    chage -E 0 ${USERNAME} 
    if [[ "${?}" -ne 0 ]]
    then
      echo "The account ${USERNAME} was NOT disabled." >&2
      exit 1
    else
      echo "The account ${USERNAME} was disabled."
    fi
  fi
done

exit 0 
