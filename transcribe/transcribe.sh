#!bin/bash
# This script performs media speech to text transcription.

USAGE="Usage: ./transcribe.sh input output\n
    input\t: the path or url to the media file to process\n
    output\t: optional argument for path to write transcribed text to\n"

INPUT=""
OUTPUT=""

function()