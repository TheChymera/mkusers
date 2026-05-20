#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat >&2 <<EOF
Usage: $(basename "$0") [OPTIONS] USER [USER...]

Create or remove users en masse, adding them to default Gentoo groups and optionally dispatching a directory to the users.
This script needs to be run as root to perform user maipulations.
Deletion in particular is DANGEROUS as it is both permanent by design and forced by choice.
ALWAYS consult the prompt before confirming.

Options:
	-p <prefix>   Password prefix (password will be prefix+username)
	-c <dir>      Directory to copy into each user's home directory
	-R            Remove users instead of creating them
	-h            Show this help

Examples:
	$(basename "$0") foo bar
	$(basename "$0") -p demo_ user{0..99}
	$(basename "$0") -p demo_ -c /some/directory foo bar
	$(basename "$0") -R foo bar
EOF
	exit 0
}

# setting default variables
REMOVE=0
COPY=""
PASSWORD_PREFIX=""

# read options
while getopts ':c:p:Rh' flag; do
	case "${flag}" in
	c)
		COPY=$OPTARG
		;;
	p)
		PASSWORD_PREFIX=$OPTARG
		;;
	R)
		REMOVE=1
		;;
	h)
		usage
		;;
	\?)
		echo "Invalid option: -$OPTARG" >&2
		exit 1
		;;
	:)
		echo "Option -$OPTARG requires an argument." >&2
		exit 1
		;;
	esac
done

#checks if run as root:
if ! [[ "$EUID" -eq 0 ]]
then
	echo "$(basename "$0"): must be root."
	exit 1
fi

# shifts pointer to read mandatory user list
shift $(($OPTIND - 1))
USERS=("$@")

# are there any users to be created?
[[ ${#USERS[@]} -gt 0 ]] || { echo "$(basename "$0"): at least one user required." >&2; exit 1; }

if [ ${REMOVE} -eq 0 ]; then
	echo "Creating user list:"
	for USER in "${USERS[@]}"; do
		useradd -m -N -G portage,wheel "$USER"
		echo "$USER:$PASSWORD_PREFIX$USER" | chpasswd
		echo "Created $USER."
		if [[ -n "$COPY" ]]; then
			cp -rf "$COPY" "/home/${USER}/"
			chown -R "$USER:wheel" "/home/${USER}/"
		fi
	done
else
	echo "Preparing to delete users: '${USERS[@]}'"
	read -p "Are you sure? [y/N] " -r
	echo # move to new line
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		echo "Deleting user list:"
		for USER in "${USERS[@]}"; do
			userdel -r -f "$USER"
			echo "Deleted $USER and corresponding home directory."
		done
	fi
fi
