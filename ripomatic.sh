#!/bin/bash
while [[ $# > 1 ]]
do
key="$1"
   
case $key in
      -h) 
         echo "Usage: $0 [-i input file] [-o output folder] [-se series number] [-sf episode names start from] [-m min-length in seconds]"
         ;;
      -i)
	 INPUT_DEV=$2
         shift
         ;;
      -o)
         OUTPUT_FOLDER=$2
         shift
         ;;
      -se)
	 SERIES=$2
         shift
         ;;
      -sf)
	 STARTS_FROM=$2
         shift
         ;;
      -m)
	 MINLENGTH=$2
         shift
         ;;
      *)
	 echo unknown option
	;;
   esac
shift
done
echo $INPUT_DEV; echo $OUTPUT_FOLDER; echo $SERIES; echo $MINLENGTH; echo $STARTS_FROM


#INPUT_DEV=$1
#OUTPUT_FOLDER=$2
OUTPUT_NAME=$(makemkvcon -r info | grep "DRV\:0" | cut -f4 -d\")
#SERIES=$3
#STARTS_FROM=$4
#MINLENGTH="900"
MINLENGTHMS="${MINLENGTH}000"

LSDVDOUTPUT=$(lsdvd "$INPUT_DEV")

# if available get the title and get the number of titles
TITLE=$(echo "$LSDVDOUTPUT" | grep -i Disc | sed 's/Disc Title: //g')
#NOMTITLES=$(echo "$LSDVDOUTPUT" | grep -i Length | wc -l)

# find tracks satisfying minimum length requirements
tracks=$(HandBrakeCLI -t 0 -i $INPUT_DEV 2>&1 |grep 'scan: duration'|grep -n '^'| sort -k 5|while read title; do if (( ${MINLENGTHMS} < $(sed 's/^.*(\([0-9]\+\) ms.*$/\1/g' <<<"$title" ) )); then echo "$title"|awk -F":" '{print $1}'; fi; done|sort -V)
echo "will rip tracks $tracks"

let n=$STARTS_FROM
echo $n
#cycle through the tracks to rip
for c in $tracks; do
        PREFIX=''
	# Allows for seasons on multiple DVDs
       if [ $n -lt  10 ]; then PREFIX="0" ; fi
	OUTPUT_NAME_TITLE=$OUTPUT_FOLDER"/"$OUTPUT_NAME-s${SERIES}e$PREFIX$n".m4v"
	echo "doing track $c"
	echo $OUTPUT_NAME_TITLE
        HandBrakeCLI -i $INPUT_DEV -o $OUTPUT_NAME_TITLE -t $c --preset "High Profile" > /dev/null 2>&1
# 	increment n for next real episode name rather than track name
	let n++; 
done
