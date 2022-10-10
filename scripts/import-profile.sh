#!/bin/bash

shopt -s lastpipe

# Read initial environment to avoid importing variables that are set by the shell environment rather than the profile scripts.
declare -A ENV
env -0 | while IFS='=' read -d '' k v; do
	ENV["$k"]="$v"
done

# sometimes scripts in /etc/profile.d want to access the user bus,
# which is not yet ready by this point
# moving import-profile.sh after basic.target creates a race (naturally,
# we want environment to be set _before_ we get to launching user stuff)
# and moving dbus inside basic.target does not solve anything because
# the actual bus-activated processes will still block on basic.target.
# No good way to solve this. Let's just disable access to dbus for now.
export DBUS_SESSION_BUS_ADDRESS=

for f in /etc/profile ~/.profile; do
	. "$f"
done

# don't import an empty $DBUS_SESSION_BUS_ADDRESS
unset DBUS_SESSION_BUS_ADDRESS

# in case of UID 0, override bogus $SHELL
if (( UID == 0 )); then
	export SHELL="$(getent passwd "$UID" | cut -d: -f7)"
	if ! [[ "$SHELL" && -x "$SHELL" ]] || ! grep -q -Fx "$SHELL" /etc/shells; then
		unset SHELL
	fi
fi

# Read final environment and only mark changed variables for import.
declare -A ENV_ADD
env -0 | while IFS='=' read -d '' k v; do
	if [[ "${ENV["$k"]}" != "$v" ]]; then
		ENV_ADD["$k"]=1
	fi
done

if (( ${#ENV_ADD[@]} > 0 )); then
	echo "Importing environment modified by /etc/profile:" >&2
	printf "* %s\n" "${!ENV_ADD[@]}"
	systemctl --user import-environment "${!ENV_ADD[@]}"
fi
