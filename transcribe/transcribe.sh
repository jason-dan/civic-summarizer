#!bin/bash
# transcribe.sh, Version 1
#
# This script automates the entire speech to text transcription pipeline.
# See https://github.com/jason-dan/civic-summarizer/blob/main/transcribe/README.md
# for quick start and usage examples.
#
# Jason Dan

# Default parameters and shared variables
INPUT=""                # Path or URL to input media
OUTPUT=""               # Path to file for text output
TEMP_DIR=$(mktemp -d)   # Temp file storage for this bash script
MIN_SEG_LENGTH=300      # Minimum length (seconds) of audio segments
CODEC="pcm_alaw"        # Audio codec

USAGE="Usage: ./transcribe.sh input output\n
    input\t: the path or url to the media file to process\n
    output\t: optional argument for path to write transcribed text to\n"