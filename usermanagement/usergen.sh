#!/bin/bash

# Author: Jordan Hall
# Date: 12/08/2025
# Description: This script when run with superuser (root) privileges will create a user using the first argument as the username, a department group using the second, and the remaining arguments as the comment. A one-time password will be automatically generated for the account, and the credentials will be displayed along with the host. This script also conforms to Linux program standard conventions.
# Usage: "Usage: ${0} 'USERNAME' [DEPARTMENT] '[COMMENT]'"
# Enforce execution with superuser (root) privileges
if [[ "${UID}" != 0 ]]
then
echo "Error: This script must be run with superuser (root) privileges." >&2
exit 1
fi

# Provide proper usage if arguments are not supplied
if [[ "$#" -eq 0 ]]
then
echo "Error: Usage: ${0} 'USERNAME' [DEPARTMENT] '[COMMENT]'" >&2
echo " USERNAME     - Login name for the new user" >&2
echo " DEPARTMENT   - Department group (finance, hr, it, etc.) or 'none'" >&2
echo " COMMENT      - Full name or description" >&2
exit 1
fi

# Utilize first argument for username and remaining arguments for the comment in user creation
USER_NAME="${1}"
DEPARTMENT="${2}"
shift 2
COMMENT="${@}"

# Verify department group exists (if not 'none")
if [ "${DEPARTMENT}" != "none" ]
then
if ! getent group "${DEPARTMENT}" &> /dev/null
then
echo "Error: Department group: '${DEPARTMENT}' does not exist." >&2
echo "Create it first with groupadd ${DEPARTMENT}" >&2
exit 1
fi
fi

# Create user with or without department group
if [ "${DEPARTMENT}" = "none" ]
then
useradd -m -c "${COMMENT}" "${USER_NAME}" 2> /dev/null
else
useradd -m -G "${DEPARTMENT}" -c "${COMMENT}" "${USER_NAME}" 2> /dev/null
fi

# Notify user if account creation was unsuccessful
if [[ "${?}" -ne 0 ]]
then
echo "Failed to create user account '${USER_NAME}'." >&2
exit 1
fi

# Automatically generate a randomized password
PASSWORD="$(date +%s%N${RANDOM}${RANDOM} | sha256sum | head -c28)"
SPECIAL="$(echo '!@#$%^&*()-+=' | fold -w1 | shuf | head -c1)"
PASSWORD="${PASSWORD}${SPECIAL}"
echo "${PASSWORD}" | passwd --stdin "${USER_NAME}" &> /dev/null

# Expire password so new one must be created on first login
passwd -e "${USER_NAME}" &> /dev/null

# Display account info
echo "Account successfully created."
echo
echo "INFO:"
echo
echo "username: ${USER_NAME}"
echo
echo "description: ${COMMENT}"
echo

if [ "$DEPARTMENT" != "none" ]
then
echo "department: ${DEPARTMENT}"
fi

echo
echo "password: ${PASSWORD}"
echo
echo "host: ${HOSTNAME}"
echo
