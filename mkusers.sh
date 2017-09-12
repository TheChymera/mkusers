#checks if run as root:
#if ! [ "`whoami`" == "root" ]
#then
#	echo "`basename $0`: must be root."
#	exit 1
#fi

# setting default variables
REMOVE=0

# read options
while getopts ':U:c:p:Rq' flag; do
	case "${flag}" in
	U)
		USERS+=("$OPTARG")
		;;
	q)
		QUIET=1
		;;
	c)
		COPY=$OPTARG
		;;
	p)
		PASSWORD_PREFIX=$OPTARG
		;;
	R)
		REMOVE=1
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

# shifts pointer to read mandatory output file specification
shift $(($OPTIND - 1))
ARCHIVE=$1


if [ ${REMOVE} -eq 0 ]; then
	echo "Creating user list:"
	for USER in "${USERS[@]}"; do
		useradd -m -N -G portage,wheel "$USER" &&
		echo "$USER:$PASSWORD_PREFIX$USER" | chpasswd &&
		echo Created "$USER".
		cp -rf $COPY "/home/${USER}/"
		cd "/home/${USER}/" && chown -R "$USER:wheel" *
	done
else
	echo "Preparing to delete users: '${USERS[@]}'"
	read -p "Are you sure? " -r
	echo    # (optional) move to a new line
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		echo "Deleting user list:"
		for USER in "${USERS[@]}"; do
			userdel -r -f "$USER" &&
			echo Deleted "$USER" and corresponding home directory.
		done
	fi
fi

