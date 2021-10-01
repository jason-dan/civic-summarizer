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

# Generates a random unused Docker volume name
# Adapted from: https://unix.stackexchange.com/questions/230673/how-to-generate-a-random-string
function getNewVolumeName() {
    local randomCmd="head /dev/urandom | tr -dc A-Za-z0-9 | head -c50"
    local name=$(eval "$randomCmd")
    while [[ -n "$(docker volume ls -q | grep ${name})" ]]; do
        name=$(eval "$randomCmd")
    done

    echo ${name}
}

# Creates a Docker Volume for storing shared files. Returns name of newly created volume.
function initDockerVolume() {
    local volName=$(getNewVolumeName)    # Use random name to hopefully generate a unique
    docker volume create ${volName} > /dev/null
    echo ${volName}
}

# Removes the Docker specified Docker volume from the host system
# $1 = Name of Docker volume
function removeDockerVolume() {
    docker volume rm "$1" > /dev/null
}

# Launches a temporary Docker container with volume mounted and runs a command.
# The volume specified is mounted as /vol/
# $1 = Name of Docker volume to mount
# $2 = Name of Docker image which exists on the system
# $3 = String, containing command to run in Docker container. Only command args if image has ENTRYPOINT
function runDockerCommand() {
    docker run --rm \
        --mount type=volume,src=$1,dst="/vol" \
        $2 \
        $3
}

# Launches a temp Docker container with a host directory bind mounted, Docker volume mounted, and runs a command
# Docker volume is mounted as /vol
# Host Directory is mounted as /bind, in read only mode
# $1 = Name of Docker Volume
# $2 = Path of host directory
# $3 = Name of Docker image
# $4 = Command to run. Command args if image has ENTRYPOINT
function runDockerCommandWithBind() {
    docker run --rm \
        --mount type=volume,src=$1,dst="/vol" \
        --mount type=bind,src=$2,dst="/bind",readonly \
        $3 \
        $4
    
}


# Encodes media and outputs an array of locations of silences detected (in seconds from start)
# Saves encoded audio file to Docker Volume
# $1 = URL / path of the media for process
# $2 = Name of Docker Volume
# $3 = Path of the output file
function encodeAndDetectSilences() {
    local sourceFile=$1
    local dockerVolume=$2
    local outputFile=$3
    local directory=""
    local isFile="false"
    local -a silences

    if [[ -f ${sourceFile} ]]; then
        sourceFile=$(realpath ${sourceFile})
        directory=$(dirname ${sourceFile})
        sourceFile="/bind/$(basename ${sourceFile})"
        isFile="true"
    fi

    local ffmpegArgs="-nostdin -nostats -i ${sourceFile} -y -vn -sn -dn -ac 1 -ar 16000 -codec ${CODEC} -af silencedetect=-55dB:d=0.3 ${outputFile}"
    local ffmpegOutput=""

    if [ "$isFile" = "true" ]; then
        silences=$(runDockerCommandWithBind ${dockerVolume} ${directory} jrottenberg/ffmpeg "${ffmpegArgs}" |& grep 'silence_start:' | awk '{print $5}')
    else
        silences=$(runDockerCommand ${dockerVolume} jrottenberg/ffmpeg "${ffmpegArgs}" |& grep 'silence_start:' | awk '{print $5}')
    fi

    echo ${silences}
}

# Selects audio split locations from provided list of potential locations. Ensures that the interval between each split
# point is at least the provided minimum interval time.
# $1 = Minimum interval time (in seconds)
# $2... = Potential split locations (in seconds from beginning), in ascending order
function selectSplitPoints() {
    local -a selectedSplits=(0.0)
    local minInterval=$1
    shift
    
    for split in $@; do
        local delta=$(bc <<< "${split}-${selectedSplits[-1]}")
        if [[ $(bc <<< "${delta}>=${minInterval}") -gt 0 ]]; then
            selectedSplits+=(${split})
        fi
    done 

    echo ${selectedSplits[@]}
}

# Reads an audio file and saves a copy in small segments. Segments are saved in the mounted /vol/ directory
# as /vol/audio0001.wav, /vol/audio0002.wav....
# $1 = Path to source file
# $2 = Name of shared docker volume to mount
# $3... = Locations in the source file to create a segment. Locations are represented in seconds from start, and must be in ascending order
function splitAudio() {
    local source=$1
    local dockerVolume=$2
    shift 2
    splits=($@)

    printf -v splits '%s,' "${splits[@]}"   # Convert SPLITS from array to comma delimited array
    splits=${splits%?}                      # Remove last comma

    local ffmpegArgs="-nostdin -nostats -i ${source} -c copy -f segment -segment_times ${splits} /vol/audio%4d.wav"

    runDockerCommand ${dockerVolume} jrottenberg/ffmpeg "${ffmpegArgs}"
}


# Downloads media, encodes and slices into small pieces of audio. Saves audio pieces
# in the shared Docker volume.
# $1 = URL / path of media to process
# $2 = Name of Docker Volume
# function processMedia() {
#     local mediaLocation=$1
#     local dockerVolume=$2
#     local 
    
#     if [[ -f "$1" ]]; then
#         local hostDirectory=$(dirname "$1")
# }

DOCKER_VOL=$(initDockerVolume)
silences=$(encodeAndDetectSilences media.mp3 ${DOCKER_VOL} /vol/output.wav)
splitPoints=$(selectSplitPoints 10 "${silences}")
splitAudio /vol/output.wav ${DOCKER_VOL} "${splitPoints}"
