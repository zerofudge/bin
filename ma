#!/usr/bin/env sh


echo "$1" | sed 's/.*\///g'|sed 's/\?.*//g'|xsel --clipboard --input

