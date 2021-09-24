#!/bin/bash
# processmedia, version 1
#
# This script fetches a video or audio file from a provided URL or path, reencodes 
# to mono A-Law wav, resamples audio to 16kHz, then splits the audio into a 
# series of `.wav` files ready for transcription.

USAGE="Usage: ./processmedia [OPTIONS]\n
Options:\n
   --input [URL/path]\t: the path of the media to process\n
   --outpath [path]\t: path of directory to save output files (OPTIONAL)\n
   --minlength [seconds]\t: minimum length (in seconds) of output files (OPTIONAL)\n
   --filename [name]\t: prefix of output files (OPTIONAL)\n"

# Set argument variables with their default values
INPUT=""
OUTPATH="."
MIN_LENGTH=300
FILENAME="audio"
TEMPFILE=$(mktemp /tmp/XXXXXXXXXXXXXXXXXXXXXXX.wav)

function finish() {     # Cleanup function
    rm -f ${TEMPFILE}
}

# Parse command arguments
# Based on https://bl.ocks.org/magnetikonline/22c1eb412daa350eeceee76c97519da8
while [[ $# -gt 0 ]]; do
    case "$1" in
        --input)
            INPUT=$2
            shift 2
            ;;

        --outpath)
            OUTPATH=$2
            shift 2
            ;;

        --minlength)
            MIN_LENGTH=$2
            shift 2
            ;;

        --filename)
            FILENAME=$2
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

# Check for required input argument
if [[ -z ${INPUT} ]] ; then
    >&2 echo "Missing --input argument."
    >&2 echo -e ${USAGE}
    exit 1
fi

# Create output directory if needed
if [[ !(-d ${OUTPATH}) ]] ; then
    mkdir -p ${OUTPATH}
fi

# Encode file to mono a-Law 16kHz wav and save as temp file. At the same time, search for moments of voice inactivity
echo "Encoding file and finding split points..."
SILENCES=$(
    ffmpeg -nostdin -nostats -i ${INPUT} -y -vn -sn -dn -ac 1 -ar 16000 -codec pcm_alaw -af silencedetect=-55dB:d=0.3 ${TEMPFILE} \
    |& grep 'silence_start: ' \
    | awk '{print $5}'
)

# Determine split points which fulfill the minimum length condition
SPLITS=(0.0)
for split in ${SILENCES}; do
    delta=$(bc <<< "${split}-${SPLITS[-1]}")
    if [[ $(bc <<< "${delta}>=${MIN_LENGTH}") -gt 0 ]] ; then
        SPLITS+=(${split})
    fi
done

# Split audio
printf -v SPLITS "%s," "${SPLITS[@]}"   # Convert SPLITS from array to comma delimited array
SPLITS=${SPLITS%?}                      # Remove last comma

echo "Splitting audio..."
ffmpeg -nostdin -nostats -i ${TEMPFILE} -c copy -f segment -segment_times $SPLITS $OUTPATH/$FILENAME%4d.wav 2> /dev/null

trap finish exit