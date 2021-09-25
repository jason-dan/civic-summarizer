# civic-summarizer/transcribe

Welcome! This directory contains everything related to the downloading, processing, and speech to text transcription of a media file.

## Quick Start

This guide is for users on the Linux operating system with a Bash shell.

Before starting, make sure that Docker is installed. Run this command to test if Docker is installed:
```
docker -v
```

Two docker containers are used, [**`jrottenberg/ffmpeg`**](https://hub.docker.com/r/jrottenberg/ffmpeg/) for media encoding and [**`jasondan123/civic-summarizer:transcription-engine`**] for speech to text transcription. Run the following commands to pull the container images:
```
docker pull jrottenberg/ffmpeg
docker pull jasondan123/civic-summarizer:transcription-engine
```

Make sure that [**`transcribe.sh`**](transcribe.sh) and utility scripts have execution permissions by running the following command.
```
chmod +x ./transcribe.sh
```

**Congrats, set up is complete!**

To transcribe a media file, use the [**`transcribe.sh`**](transcribe.sh) script. Usage:
```
./transcribe.sh path/to/media.ext output/path.txt
```

## Usage
The [**`transcribe.sh`**](transcribe.sh) script accepts inputs of almost all media formats, both video and audio. Processing of a file is an expensive task...sometimes taking more than 10 minutes.

Example with input file path. No output file is specified so it will output to STDOUT:
```
./transcribe.sh path/to/media.mp4
```

Example with media file hosted on the internet.
```
./transcribe.sh http://site/media.mp3 output.txt
```