#!/bin/sh

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
systemctl --user import-environment
