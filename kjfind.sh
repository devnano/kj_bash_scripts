#!/bin/bash

FILE_PATTERN="$1"
SEARCH_TEXT="$2"

echo "Finding in current directory: `pwd`"

find . -iname "$FILE_PATTERN" -exec grep --color -H "$SEARCH_TEXT" {} \;
