#!/bin/bash

SED_COMMAND_LINE=( sed -r )

while IFS='=' read name value; do
	SED_COMMAND_LINE+=( -e "s|^$name=.*|$name=$value|" )
done < <(systemctl --user show-environment)

"${SED_COMMAND_LINE[@]}" -i "$1"
