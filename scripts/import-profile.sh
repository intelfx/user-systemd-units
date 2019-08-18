#!/bin/sh

for f in /etc/profile ~/.profile; do
	. "$f"
done

systemctl --user import-environment
