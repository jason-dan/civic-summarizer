# Utility Scripts

[**`processmedia.sh`**](processmedia.sh) This script fetches a video or audio file from a provided URL or path, reencodes to ` mono A-Law wav`, resamples audio to 16kHz, then splits the audio into a series of `.wav` files ready for transcription.

Usage:
```
./processmedia.sh \
    --input http://website/media.mp4 \
    --output path/to/output/directory
```

Flags:
|Flags|Flag Type|Default Value|Flag Example Value|Description|
|-|-|-|-|-|
|`input`|string|`''`|`--input path/to/input.mov`|**Required** URL or full path to the audio or video file to process.|
|`outpath`|string|`.`|`--outpath path/to/dir`|Path to the directory where the output audio files will be saved, creates directory if needed|
|`minlength`|int|300|`--minlength 600`|Minimum length (in seconds) of the output audio files|
|`filename`|string|`audio`|`--filename kirkland`|Prefix of outputted audio file name. Example value outputs `kirkland0001.wav`, `kirkland0002.wav`, and so on|





