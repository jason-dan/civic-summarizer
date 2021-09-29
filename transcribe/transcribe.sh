#!/bin/bash
# transcribe.sh, Version 1
#
# This script automates the entire speech to text transcription pipeline.
# See https://github.com/jason-dan/civic-summarizer/blob/main/transcribe/README.md
# for quick start and usage examples.
#
# Copyright (c) 2021 Jason Dan
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


# Default parameters and shared variables
INPUT=""                # Path or URL to input media
OUTPUT=""               # Path to file for text output
TEMP_DIR=$(mktemp -d)   # Temp file storage for this bash script
MIN_SEG_LENGTH=300      # Minimum length (seconds) of audio segments
CODEC="pcm_alaw"        # Audio codec
DOCKER_VOL=""           # Shared docker volume name
USAGE="Usage: ./transcribe.sh input output\n
    input\t: the path or url to the media file to process\n
    output\t: optional argument for path to write transcribed text to\n"

# Generates a random unused Docker volume name
# Adapted from: https://unix.stackexchange.com/questions/230673/how-to-generate-a-random-string
function getRandomString() {
    local randomCmd="head /dev/urandom | tr -dc A-Za-z0-9 | head -c50"
    local name=$(eval "$randomCmd")
    while [[ -n "$(docker volume ls -q | grep ${name})" ]]; do
        name=$(eval "$randomCmd")
    done

    echo ${name}
}

# Check if file at URL returns a 200 HTTP request
# $1 = URL to check
# Return 0 if file is reachable, 1 if not 
function validateURL() {
    if [[ `wget -S --spider $1  2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Check if file at path or URL is a valid file
# $1 = path or URL to check
function validateFileExists() {
    local input=$1
    local isValidURL=$(validateURL ${input})
    if [[ -f ${input} ]] || [[ ${isValidURL} == "true" ]]; then    # Test for valid file or URL
        echo "true"
    else
        echo "false"
    fi
}

# Parse command line arguments
function parseArgs() {
    if [[ "$#" -eq 0 ]]; then
        >&2 echo "Error: Missing input argument."
        >&2 echo -e ${USAGE}
        exit 1
    elif [[ $(validateFileExists $1) == "false" ]]; then
        >&2 echo "Input path/URL does not contain valid file"
        exit 1
    else 
        INPUT=$1
        OUTPUT=$2
    fi
}

# Creates a Docker Volume for storing shared files, and sets
# global variable DOCKER_VOL to the name of the created volume
function initDockerVolume() {
    local volName=$(getRandomString)    # Use random name to hopefully generate a unique
    docker volume create ${volName} > /dev/null
    DOCKER_VOL=${volName}
}

initDockerVolume