#!/bin/bash

FILE_PATTERN="$1"
SEARCH_TEXT="$2"

echo "Finding $SEARCH_TEXT in $FILE_PATTERN files. Current directory: `pwd`"

find . -type f -iname "$FILE_PATTERN" -exec grep --color -H "$SEARCH_TEXT" {} \;
