#!/usr/bin/env bats

SCRIPT="$(realpath "$BATS_TEST_DIRNAME/../manage_users.sh")"

setup() {
	mkdir -p "$BATS_TMPDIR/etc" "$BATS_TMPDIR/home"
	printf 'root::0:0:::\n' > "$BATS_TMPDIR/etc/passwd"
	printf 'root:::::::\n' > "$BATS_TMPDIR/etc/shadow"
	printf 'root::0:\nwheel::1:\nportage::2:\n' > "$BATS_TMPDIR/etc/group"
	printf 'root::\nwheel::\nportage::\n' > "$BATS_TMPDIR/etc/gshadow"
}

run_isolated() {
	unshare --user --map-root-user --mount -- bash -c "
		mount -t tmpfs tmpfs /etc
		cp '$BATS_TMPDIR/etc/'* /etc/
		mount -t tmpfs tmpfs /home
		$*
	"
}

## Debug env
#@test "inspect dummy environment" {
#	run run_isolated "tree"
#	echo "$output"
#}
