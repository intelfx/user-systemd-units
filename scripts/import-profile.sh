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
# override bogus $SHELL, if set
if [[ $SHELL ]]; then
	_shell="$(getent passwd "$UID" | cut -d: -f7)"
	if [[ "$SHELL" != "$_shell" ]] && [[ -x "$_shell" ]] && grep -q -Fx "$_shell" /etc/shells; then
		echo >&2 "WARNING: bogus \$SHELL=${SHELL@Q} detected, resetting to ${_shell@Q}"
		export SHELL="$_shell"
	elif [[ "$SHELL" != "$_shell" ]]; then
		echo >&2 "WARNING: bogus \$SHELL=${SHELL@Q} detected, not resetting to ${_shell@Q} as it is also bogus"
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
	echo >&2 "Importing environment modified by /etc/profile:"
	printf >&2 "* %s\n" "${!ENV_ADD[@]}"
	systemctl --user import-environment "${!ENV_ADD[@]}"
fi
