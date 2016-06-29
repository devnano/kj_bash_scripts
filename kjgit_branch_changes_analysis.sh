#!/bin/bash

DEV_BRANCH="$1"
FEATURE_BRANCH="$2"
DIVERGED_FILES_DIR="git_$DEV_BRANCH"_"$FEATURE_BRANCH"_"files_changed"
SCRIPT_NAME="$0"
RENAME_THRESHOLD=30

(test -n "$DEV_BRANCH"  && test -n "$FEATURE_BRANCH") || { echo "Original and feature branch should be passed as argument: e.g. $SCRIPT_NAME development MY_NEW_FEATURE"; exit 1; }

function recreate_dir {
    DIR=$1
    test -d "$DIR" && rm -rf "$DIR"
    mkdir -v "$DIR"
}

recreate_dir "$DIVERGED_FILES_DIR" 

function get_renamed_group {
    test  "$1" = "100" && echo "100" && return

    STEP=$((100/DIVERGED_GROUPS))

    for i in `seq 0 $STEP 100`;
    do
	if [ $1 -le $i ]; then
	    echo "$((i-STEP))_$i"
	    return
	fi
    done
}

function analyze_renamed_files {
    COMPONENT=0
    DIVERGED_GROUPS=5
    NO_CHANGED_FILES="files_moved_with_no_changes.log"
    BASE_DIR_NAME="$DIVERGED_FILES_DIR/renamed_files_by_unchanged_percentage"

    recreate_dir "$BASE_DIR_NAME"

    while IFS= read -r -d '' i; do
	if [ $COMPONENT -eq 0 ]; then
	    PERCENTAGE="`echo $i | sed 's/R//g'`"
	elif [ $COMPONENT -eq 1 ]; then
	    LHS="$i"
	elif [ $COMPONENT -eq 2 ]; then
	    RHS="$i"
	    GROUP=$(get_renamed_group $PERCENTAGE)
	    DIR_NAME="$BASE_DIR_NAME/$GROUP"
	    
	    test ! -d "$DIR_NAME" && mkdir "$DIR_NAME"
	    
	    DIFF=`git diff -w -C "$DEV_BRANCH:$LHS" "$FEATURE_BRANCH:$RHS"`
	    FILE_NAME="`basename $LHS`"
	    echo "$DIFF" >> "$DIR_NAME/$FILE_NAME.diff"
	    COMPONENT=-1    
	fi
	COMPONENT=$((COMPONENT+1))
    done < <(git diff -C$RENAME_THRESHOLD -z -w --name-status --diff-filter=R $DEV_BRANCH $FEATURE_BRANCH)
}

function get_modified_group {
    PREVIOUS="00"
    GROUP="05 10 25 50 100"

    for i in `echo $GROUP` ;
    do
	if [ $1 -le $i ]; then
	    echo "$PREVIOUS"_"$i"
	    return
	fi
	PREVIOUS="$i"
    done

    echo "more_than_$PREVIOUS"
    return
}

function analyze_modified_files {
    COMPONENT=0
    BASE_DIR_NAME="$DIVERGED_FILES_DIR/modified_files_by_num_of_lines_changed"

    recreate_dir "$BASE_DIR_NAME"


    while IFS= read -r -d '|' i; do
	if [ $COMPONENT -eq 0 ]; then
	    ADDED="$i"
	elif [ $COMPONENT -eq 1 ]; then
	    DELETED="$i"
	elif [ $COMPONENT -eq 2 ]; then
	    FILE_PATH="$i"
	    TOTAL_LINES_CHANGED=$((ADDED+DELETED))
	    GROUP=$(get_modified_group $TOTAL_LINES_CHANGED)
	    DIR_NAME="$BASE_DIR_NAME/$GROUP"
		
	    test ! -d "$DIR_NAME" && mkdir "$DIR_NAME"

	    DIFF=`git diff -w $DEV_BRANCH $FEATURE_BRANCH "$FILE_PATH"`
	    FILE_NAME="`basename $FILE_PATH`"
	    echo "$DIFF" >> "$DIR_NAME/$FILE_NAME.diff"

	    COMPONENT=-1    
	fi
	COMPONENT=$((COMPONENT+1))
    done < <(git diff -C$RENAME_THRESHOLD --numstat --diff-filter=M $DEV_BRANCH $FEATURE_BRANCH | tr '\n' '|' | tr '\t' '|')
}

analyze_renamed_files
analyze_modified_files

STATS_FILE="$DIVERGED_FILES_DIR/stats.log"

test -f "$STATS_FILE" && rm -rf "$STATS_FILE"

for i in `find $DIVERGED_FILES_DIR -type d`;
do
    TITLE="`basename $i`"
    COUNT="`find $i -type f | wc -l`"

    echo "$TITLE: $COUNT" >> "$STATS_FILE"
done

cat "$STATS_FILE"
