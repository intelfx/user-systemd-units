#!/bin/bash

FILE="kdeinit-module@.service.in"

if ! [[ -r "$FILE" ]]; then echo "Cannot read \"$FILE\". Exiting." >&2; exit 1; fi

shopt -s nullglob
for service in kdeinit-*@.service; do
	systemctl --user disable "$service"
done
shopt -u nullglob

rm -f kdeinit-*@.service

for arg; do
	sed -re "s|@MODULE@|$arg|g" "$FILE" > "kdeinit-$arg@.service"
done

systemctl --user daemon-reload

for arg; do
	systemctl --user enable "kdeinit-$arg@.service"
done
