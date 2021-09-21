#!/bin/bash
# processmedia, version 1
#
# This script fetches a video or audio file from a provided URL or path, reencodes 
# to mono A-Law wav, resamples audio to 16kHz, then splits the audio into a 
# series of `.wav` files ready for transcription.
#
# Usage: ./processmedia [OPTIONS]
# Options:
#   -input [URL/path]   : the path of the media to process 
#   -output [path]      : path of directory to save output files (OPTIONAL)
#   -minlength [seconds]: minimum length (in seconds) of output files (OPTIONAL)
#   -outname [name]     : prefix of output files (OPTIONAL)
#
# Jason Dan, 2021, MIT license


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