# civic-summarizer

# Introduction
Civic Summarizer is an automated toolchain which tweets summaries of local Seattle area civic meetings. Publicized meeting recordings are downloaded, transcribed, summarized, and tweeted to help increase public engagement and awareness of local politics.

## Project Layout
Civic Summarizer is broken down into a few parts:

- [**`civic-summarizer/av`**](av) contains scripts for downloading recordings, media reencoding, audio resampling, and audio splitting
- [**`civic-summarizer/transcribe`**](transcribe) is the core transcription process using Facebook AI Flashlight library
- [**`civic-summarizer/summarize`**](summarize) contains scripts for summarizing meeting transcriptions
- [**`civic-summarizer/tweet`**](tweet) contains scripts for consuming the Twitter API