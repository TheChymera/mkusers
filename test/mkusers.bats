#!/usr/bin/env bats

SCRIPT="$(realpath "$BATS_TEST_DIRNAME/../bin/mkusers.sh")"

setup() {
	cp "$SCRIPT" "$BATS_TMPDIR/mkusers.sh"
	chmod +x "$BATS_TMPDIR/mkusers.sh"
	mkdir -p "$BATS_TMPDIR/etc/pam.d"
	printf 'root::0:\nwheel::1:\nportage::2:\nmail::3:\n' > "$BATS_TMPDIR/etc/group"
	printf 'root:::::::\n' > "$BATS_TMPDIR/etc/shadow"
	printf 'password requisite pam_unix.so\n' > "$BATS_TMPDIR/etc/pam.d/chpasswd"
}

run_isolated() {
    unshare --user --map-root-user --map-users=auto --map-groups=auto --mount -- bash -c "
        set -eo pipefail
        mount -t tmpfs tmpfs /etc
        mount -t tmpfs tmpfs /home
	mount -t tmpfs tmpfs /var/mail
        cp -r '$BATS_TMPDIR/etc/'* /etc/
        eval \"\$@\"
    " -- "$@"
}

@test "user is created" {
	run run_isolated "$BATS_TMPDIR/mkusers.sh -U testuser && cat /etc/passwd"
	echo "$output"
	[ "$status" -eq 0 ]
	[ "$(grep -cP '^testuser' <<< "$output")" -eq 1 ]
}

@test "user is added to default groups" {
	run run_isolated "$BATS_TMPDIR/mkusers.sh -U testuser && cat /etc/group"
	echo "$output"
	[ "$status" -eq 0 ]
	[ "$(grep -cP '^wheel:.*testuser' <<< "$output")" -eq 1 ]
	[ "$(grep -cP '^portage:.*testuser' <<< "$output")" -eq 1 ]
}

@test "home directory is created" {
	run run_isolated "$BATS_TMPDIR/mkusers.sh -U testuser && ls /home"
	echo "$output"
	[ "$status" -eq 0 ]
	[ "$(grep -cP '^testuser$' <<< "$output")" -eq 1 ]
}

@test "password is set" {
	run run_isolated "$BATS_TMPDIR/mkusers.sh -U testuser && cat /etc/shadow"
	echo "$output"
	[ "$status" -eq 0 ]
	[ "$(grep -cP '^testuser:[^:!*]' <<< "$output")" -eq 1 ]
}

@test "multiple users are created" {
	run run_isolated "$BATS_TMPDIR/mkusers.sh -U foo -U bar && cat /etc/passwd"
	echo "$output"
	[ "$status" -eq 0 ]
	[ "$(grep -cP '^foo' <<< "$output")" -eq 1 ]
	[ "$(grep -cP '^bar' <<< "$output")" -eq 1 ]
}

@test "copy files in home directory" {
	mkdir -p "$BATS_TMPDIR/demo_files"
	touch "$BATS_TMPDIR/demo_files/testfile"
	run run_isolated "$BATS_TMPDIR/mkusers.sh -U testuser -c $BATS_TMPDIR/demo_files && ls /home/testuser && ls /home/testuser/demo_files"
	echo "$output"
	[ "$status" -eq 0 ]
	[ "$(grep -cP '^demo_files$' <<< "$output")" -eq 1 ]
	[ "$(grep -cP '^testfile$' <<< "$output")" -eq 1 ]
}

@test "user and home directory are deleted" {
	run run_isolated "$BATS_TMPDIR/mkusers.sh -U testuser && grep -qP \"^testuser\" /etc/passwd && [ -d /home/testuser ] && echo y | $BATS_TMPDIR/mkusers.sh -R -U testuser && cat /etc/passwd && ls /home"
	echo "$output"
	[ "$status" -eq 0 ]
	[ "$(grep -cP '^testuser' <<< "$output")" -eq 0 ]
}

## Debug env
#@test "inspect dummy environment" {
#    run run_isolated "bash -c 'tree /etc && tree /home'"
#    echo "$output"
#}
