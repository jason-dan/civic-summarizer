# civic-summarizer/av

This folder contains scripts for downloading audio/video files, encoding, resampling, and splitting recordings.

## Dependencies
- [**`ffmpeg`**](https://ffmpeg.org/ffmpeg.html) multipurpose tool for media encoding and resampling
- [**`sox`**](http://sox.sourceforge.net/sox.html) audio processing toolkit, used for splitting audio

## Scripts

[**`processmedia.sh`**](processmedia.sh) This script fetches a video or audio file from a provided URL or path, reencodes to ` mono A-Law wav`, resamples audio to 16kHz, then splits the audio into a series of `.wav` files ready for transcription.

Usage:
```
./processmedia.sh \
    -input http://website/media.mp4 \
    -output path/to/output/directory
```

Flags:
|Flags|Flag Type|Default Value|Flag Example Value|Description|
|-|-|-|-|-|
|`input`|string|`''`|`-input path/to/input.mov`|URL or full path to the audio or video file to process. *Required*|
|`output`|string|`.`|`-output path/to/dir`|Path to the directory where the output audio files will be saved, creates directory if needed *Required*|
|`minlength`|int|300|`-minlength 300`|Minimum length (in seconds) of the output audio files|
|`outname`|string|`audio`|`-outname kirkland`|Prefix of outputted audio file name. Example value outputs `kirkland001.wav`, `kirkland002.wav`, and so on|




