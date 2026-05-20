#!/usr/bin/env bats

SCRIPT="$(realpath "$BATS_TEST_DIRNAME/../bin/mkusers.sh")"

setup() {
	export TEST_DIR="$(mktemp -d)"
	cp "$SCRIPT" "$TEST_DIR/mkusers.sh"
	chmod +x "$TEST_DIR/mkusers.sh"
	mkdir -p "$TEST_DIR/etc/pam.d"
	printf 'root::0:\nwheel::1:\nportage::2:\nmail::3:\n' > "$TEST_DIR/etc/group"
	printf 'root:::::::\n' > "$TEST_DIR/etc/shadow"
	printf 'password requisite pam_unix.so\n' > "$TEST_DIR/etc/pam.d/chpasswd"
}

teardown() {
	rm -rf "$TEST_DIR"
}

run_isolated() {
	unshare --user --map-root-user --map-users=auto --map-groups=auto --mount -- bash -c "
		set -eo pipefail
		mount -t tmpfs tmpfs /etc
		mount -t tmpfs tmpfs /home
		mount -t tmpfs tmpfs /var/mail
		cp -r '$TEST_DIR/etc/'* /etc/
		eval \"\$@\"
	" -- "$@"
}

@test "user is created" {
	run run_isolated "$TEST_DIR/mkusers.sh -U testuser && cat /etc/passwd"
	echo "$output"
	[ "$status" -eq 0 ]
	[ "$(grep -cP '^testuser' <<< "$output")" -eq 1 ]
}

@test "user is added to default groups" {
	run run_isolated "$TEST_DIR/mkusers.sh -U testuser && cat /etc/group"
	echo "$output"
	[ "$status" -eq 0 ]
	[ "$(grep -cP '^wheel:.*testuser' <<< "$output")" -eq 1 ]
	[ "$(grep -cP '^portage:.*testuser' <<< "$output")" -eq 1 ]
}

@test "home directory is created" {
	run run_isolated "$TEST_DIR/mkusers.sh -U testuser && ls /home"
	echo "$output"
	[ "$status" -eq 0 ]
	[ "$(grep -cP '^testuser$' <<< "$output")" -eq 1 ]
}

@test "password is set" {
	run run_isolated "$TEST_DIR/mkusers.sh -U testuser && cat /etc/shadow"
	echo "$output"
	[ "$status" -eq 0 ]
	[ "$(grep -cP '^testuser:[^:!*]' <<< "$output")" -eq 1 ]
}

@test "multiple users are created" {
	run run_isolated "$TEST_DIR/mkusers.sh -U foo -U bar && cat /etc/passwd"
	echo "$output"
	[ "$status" -eq 0 ]
	[ "$(grep -cP '^foo' <<< "$output")" -eq 1 ]
	[ "$(grep -cP '^bar' <<< "$output")" -eq 1 ]
}

@test "copy files in home directory" {
	mkdir -p "$TEST_DIR/demo_files"
	touch "$TEST_DIR/demo_files/testfile"
	run run_isolated "$TEST_DIR/mkusers.sh -U testuser -c $TEST_DIR/demo_files && ls /home/testuser && ls /home/testuser/demo_files"
	echo "$output"
	[ "$status" -eq 0 ]
	[ "$(grep -cP '^demo_files$' <<< "$output")" -eq 1 ]
	[ "$(grep -cP '^testfile$' <<< "$output")" -eq 1 ]
}

@test "user and home directory are deleted" {
	run run_isolated "$TEST_DIR/mkusers.sh -U testuser && grep -qP \"^testuser\" /etc/passwd && [ -d /home/testuser ] && echo y | $TEST_DIR/mkusers.sh -R -U testuser && cat /etc/passwd && ls /home"
	echo "$output"
	[ "$status" -eq 0 ]
	[ "$(grep -cP '^testuser' <<< "$output")" -eq 0 ]
}

## Debug env
#@test "inspect dummy environment" {
#	echo "TEST_DIR: $TEST_DIR"
#	run run_isolated "bash -c 'tree /etc && tree /home'"
#	echo "$output"
#}
