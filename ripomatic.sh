#!/bin/bash
# automatic TV series ripper. needed because some of my discs had a lot of short titles that weren't required.
# set some sensible defaults
INPUT_DEV=/dev/sr0
OUTPUT_FOLDER=`pwd`
SERIES=01
STARTS_FROM=01
# 900 is 15 mins
MINLENGTH="900" 
# 4200 is 1hr 10 mins
MAXLENGTH="4200"
PRESET="Normal Profile"
OVERRIDE_TRACKS=0
EJECT=0

while [[ $# > 0 ]]
do
key="$1"
   

case $key in
      -h) 
         printf "Usage: $0 \n Version 1.10\n This tool rips TV series easily from the command line. \n [-i input file (default: $INPUT_DEV)] \n [-o output folder (default: present working directory: $OUTPUT_FOLDER)] \n [-se series number (default: $SERIES)] \n [-sf episode names start from (default: $STARTS_FROM)] \n [--min min-length in seconds (default: $MINLENGTH)] \n [--max exclude titles more than max seconds (default $MAXLENGTH)] \n [-x for high profile (default: $PRESET)] \n [-e to eject after rip (default is no eject)] \n [-t only rip specific tracks- space separated list in quotes (default: rip all that satisfy min and max)] \n [--short use default times for short programme of 30 mins: min 18 mins, max 40] \n [--medium: programme is around 1hr: use defaults of min 40, max 1hr10] \n "
	 exit 1
         ;;
      -i)
	 INPUT_DEV=$2
         shift
         ;;
      --short)
	 MINLENGTH=1080
	 MAXLENGTH=2400
         shift
         ;;
      --medium)
	 MINLENGTH=2400
	 MAXLENGTH=4200
         shift
         ;;
      -e)
	 EJECT=1
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
      --min)
	 MINLENGTH=$2
         shift
         ;;
      --max)
	 MAXLENGTH=$2
         shift
         ;;
      -t)
	 OVERRIDE_TRACKS=1
	 NEW_TRACKS=$2
	 shift
         ;;
      -x)
	 PRESET="High Profile"
	 shift
         ;;
      *)
	 echo "I don't understand the parameter $1"
	 exit 0
	;;
   esac
shift
done

printf "Using the following settings:\n input device $INPUT_DEV \n output folder: $OUTPUT_FOLDER \n series number $SERIES \n ignore titles less than $MINLENGTH seconds \n episode naming starts from $STARTS_FROM \n Using preset $PRESET\n"

# convert min length to milliseconds
MINLENGTHMS="${MINLENGTH}000"
MAXLENGTHMS="${MAXLENGTH}000"

# getting the title
LSDVDOUTPUT=$(lsdvd "$INPUT_DEV")
TITLE=$(echo "$LSDVDOUTPUT" | grep -i Disc | sed 's/Disc Title: //g')

# find tracks satisfying minimum length requirements
if [ $OVERRIDE_TRACKS -eq 1 ]; then 
	tracks="$NEW_TRACKS"
else
	tracks=$(HandBrakeCLI -t 0 -i $INPUT_DEV 2>&1 |grep 'scan: duration'|grep -n '^'| sort -k 5|while read title; do if (( ${MINLENGTHMS} < $(sed 's/^.*(\([0-9]\+\) ms.*$/\1/g' <<<"$title" ) && ${MAXLENGTHMS} > $(sed 's/^.*(\([0-9]\+\) ms.*$/\1/g' <<<"$title" ) )); then echo "$title"|awk -F":" '{print $1}'; fi; done|sort -V)
fi

#tell the user which tracks we are supposed to rip
printf " We will rip tracks ${tracks//[$'\n']/,} \n"


let n=$STARTS_FROM
#cycle through the tracks to rip
for c in $tracks; do
        PREFIX=''
	# Allows for seasons on multiple DVDs
       	if [ $n -lt  10 ]; then PREFIX="0" ; fi
	OUTPUT_NAME_TITLE=$OUTPUT_FOLDER"/"${TITLE}-s${SERIES}e$PREFIX$n".m4v"
	echo "Ripping track $c, episode $n"
	echo $OUTPUT_NAME_TITLE
        HandBrakeCLI -i $INPUT_DEV -o "$OUTPUT_NAME_TITLE" -t $c --preset "$PRESET" > hb.log 2>&1
	#increment n for next real episode name rather than track name
	let n++; 
done
if [ $EJECT -eq 1 ]; then eject $INPUT_DEV
fi
