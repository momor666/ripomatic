#!/bin/bash
# automatic TV series ripper. needed because some of my discs had a lot of short titles that weren't required.
# set some sensible defaults
INPUT_DEV=/dev/sr0
OUTPUT_FOLDER=`pwd`
PRESET="High Profile"
LSDVDOUTPUT=$(lsdvd "$INPUT_DEV")
TITLE=$(echo "$LSDVDOUTPUT" | grep -i Disc | sed 's/Disc Title: //g')

echo " We will rip main feature: $TITLE from $INPUT_DEV to $OUTPUT_FOLDER using $PRESET"

HandBrakeCLI i--main-feature -i $INPUT_DEV -o "$TITLE" --preset "$PRESET" > /dev/null 2&>1
