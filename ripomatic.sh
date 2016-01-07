#!/bin/bash
# automatic TV series ripper. needed because some of my discs had a lot of short titles that weren't required.
# set some sensible defaults
INPUT_DEV=/dev/sr0
OUTPUT_FOLDER=`pwd`
SERIES=01
STARTS_FROM=01
MINLENGTH="900"
PRESET="Normal Profile"

while [[ $# > 1 ]]
do
key="$1"
   

case $key in
      -h) 
         echo "Usage: $0 [-i input file] [-o output folder] [-se series number] [-sf episode names start from] [-m min-length in seconds] [-x for high profile]"
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
      -x)
	 PRESET="High Profile"
         ;;
      *)
	 echo "unknown option"
	;;
   esac
shift
done

printf "Using the following settings:\n input device $INPUT_DEV \n output folder: $OUTPUT_FOLDER \n series number $SERIES \n ignore titles less than $MINLENGTH seconds \n episode naming starts from $STARTS_FROM \n Using preset $PRESET\n"


OUTPUT_NAME=$(makemkvcon -r info | grep "DRV\:0" | cut -f4 -d\")
MINLENGTHMS="${MINLENGTH}000"

LSDVDOUTPUT=$(lsdvd "$INPUT_DEV")

# if available get the title and get the number of titles
TITLE=$(echo "$LSDVDOUTPUT" | grep -i Disc | sed 's/Disc Title: //g')

# find tracks satisfying minimum length requirements
tracks=$(HandBrakeCLI -t 0 -i $INPUT_DEV 2>&1 |grep 'scan: duration'|grep -n '^'| sort -k 5|while read title; do if (( ${MINLENGTHMS} < $(sed 's/^.*(\([0-9]\+\) ms.*$/\1/g' <<<"$title" ) )); then echo "$title"|awk -F":" '{print $1}'; fi; done|sort -V)

echo " We will rip tracks $tracks \n"

let n=$STARTS_FROM
#cycle through the tracks to rip
for c in $tracks; do
        PREFIX=''
	# Allows for seasons on multiple DVDs
       	if [ $n -lt  10 ]; then PREFIX="0" ; fi
	OUTPUT_NAME_TITLE=$OUTPUT_FOLDER"/"$OUTPUT_NAME-s${SERIES}e$PREFIX$n".m4v"
	echo "Ripping track $c, episode $n"
	echo $OUTPUT_NAME_TITLE
        HandBrakeCLI -i $INPUT_DEV -o $OUTPUT_NAME_TITLE -t $c --preset "$PRESET" > /dev/null 2&>1
	#increment n for next real episode name rather than track name
	let n++; 
done
eject $INPUT_DEV
