#!/bin/bash

sed -re 's|^([^ =]*=).*$|\1|' -i "$1"
