# civic-summarizer/transcribe

Welcome! This directory contains everything related to the downloading, processing, and speech to text transcription of a media file.

## Quick Start

This guide assumes that you are using a Linux operating system with a Bash shell. Before starting, make sure that Docker is installed.

Run this command to test if Docker is installed:
```
docker -v
```

Two docker containers are used, `jrottenberg/ffmpeg` for media encoding and 



## Scripts

[**`transcribe.sh`**](transcribe.sh) The main script for performing

## Usage
```
./transcribe.sh \
    --input http://website/media.mp4 \
    --output path/to/output/directory
```