#!/bin/bash
# processmedia, version 1
#
# This script fetches a video or audio file from a provided URL or path, reencodes 
# to mono A-Law wav, resamples audio to 16kHz, then splits the audio into a 
# series of `.wav` files ready for transcription.

USAGE="Usage: ./processmedia [OPTIONS]\n
Options:\n
   --input [URL/path]\t: the path of the media to process\n
   --output [path]\t: path of directory to save output files (OPTIONAL)\n
   --minlength [seconds]\t: minimum length (in seconds) of output files (OPTIONAL)\n
   --outname [name]\t: prefix of output files (OPTIONAL)\n"

# Set argument variables with their default values
INPUT=""
OUTPUT="."
MIN_LENGTH=300
OUT_NAME="audio"

# Parse command arguments
# Based on https://bl.ocks.org/magnetikonline/22c1eb412daa350eeceee76c97519da8
while [[ $# -gt 0 ]]; do
    case "$1" in
        --input)
            INPUT=$2
            shift 2
            ;;

        --output)
            OUTPUT=$2
            shift 2
            ;;

        --min_length)
            OUTPUT=$2
            shift 2
            ;;

        --outname)
            OUT_NAME=$2
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

# Encode file to mono a-Law 16kHz wav and save as temp file. At the same time, search for moments of voice inactivity
echo "Encoding file and detecting voice inactivity..."
SILENCES=$(
    ffmpeg -nostdin -nostats -i ${INPUT} -y -vn -sn -dn -ac 1 -ar 16000 -codec pcm_alaw -af silencedetect=-55dB:d=0.5 temp.wav \
    |& grep 'silence_start: ' \
    | awk '{print $5}'
)

# 
exit
