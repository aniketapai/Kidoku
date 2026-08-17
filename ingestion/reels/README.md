# Reels content pipeline

Turns one YouTube video + a ground-truth Japanese transcript into a synced
reel JSON (`assets/reels/<level>/<id>.json`) with per-sentence and per-word
timing, and registers it in `assets/reels/manifest.json`. Same "offline,
commit the output" philosophy as `../build_dictionary.py` /
`../convert_apkg.py` — the app never fetches, tokenizes, or aligns anything
on-device; it only ever reads the committed JSON.

## Setup

```
cd ingestion
pip install -r requirements.txt -r reels/requirements.txt
```

Also requires `ffmpeg` on PATH (yt-dlp uses it to extract audio), e.g.
`brew install ffmpeg`.

## Usage

1. Get the ground-truth Japanese transcript for the video — clean up
   YouTube's own captions, or transcribe it yourself — and save it as a
   plain UTF-8 `.txt` file under `reels/transcripts/`. Whatever text is in
   there is shown verbatim in the app, so it needs to be *correct*, not
   just close: no stray half-width spaces (Japanese has none, and the
   aligner uses a raw character count to sanity-check itself).

   To skip this step, pass `--fetch-captions` instead of `--transcript` and
   the script will pull the video's own Japanese captions (manual if the
   uploader added one, else YouTube's auto-captions) via yt-dlp and use
   that as the transcript directly — fast, but only as accurate as
   YouTube's own captions. Fails loudly if the video has no Japanese
   captions at all.
2. Optionally write an English translation file alongside it, one line per
   sentence, in the same order `common.text_utils.split_sentences` will
   split the transcript into (blank lines and 。！？ are the boundaries).
3. Run:
   ```
   python3 reels/align_reel.py \
     --id n4-reel-01-cafe --video-id XXXXXXXXXXX --level N4 \
     --title "日本のカフェ文化" --title-en "Japanese Cafe Culture" \
     --transcript reels/transcripts/n4-reel-01-cafe.txt \
     --translations reels/transcripts/n4-reel-01-cafe.en.txt
   ```
   Or with `--fetch-captions` in place of `--transcript` to skip step 1.
4. Open the reel in the app and scrub through it before committing.

## How the timing actually works

YouTube captions only carry line-level timestamps, and reels want
per-*word* highlighting, so this script downloads the audio, runs
faster-whisper with word timestamps over it, and diffs whisper's (possibly
mis-heard) output against your ground-truth transcript character-by-
character to transplant real timestamps onto the text you actually trust.
Whisper's wording is discarded entirely — only its timing survives.

Practical consequence: **sentence-level timing is reliable; word-level
timing is only as good as that specific audio's ASR pass.** A word's
highlight landing slightly early or late is expected sometimes and isn't a
bug worth chasing for every video — spot-check by ear, and if a whole
video's alignment looks consistently off, try a bigger `--whisper-model`
(default `medium`; `large-v3` for a stubborn video, `small` for faster
iteration while you're still finalizing the transcript text itself).

## Caveat

Audio is downloaded only here, offline, purely to compute timestamps —
never on-device, never redistributed, never re-uploaded. Playback in the
shipped app goes exclusively through YouTube's own IFrame Player API. Only
build reels from videos you have the right to use this way, same
diligence the dictionary/deck ingestion already assumes for its sources.
