#!/usr/bin/env python3
"""Builds a Reels video-lesson JSON (assets/reels/<level>/<id>.json) from a
YouTube video ID + a ground-truth Japanese transcript, and registers it in
assets/reels/manifest.json.

Unlike the dictionary/deck ingestion scripts, this one needs real audio:
YouTube's own captions only carry line-level timestamps, and the reels
feature wants per-word highlighting, so this script downloads the video's
audio, runs word-level ASR timestamps over it with faster-whisper, and
aligns those timestamps onto your ground-truth transcript text via a
character-level diff. The ASR output is only ever used for *timing* — the
transcript text you supply is what actually gets shown and tokenized, never
whisper's own guess at the wording.

Setup:
    cd ingestion
    pip install -r requirements.txt -r reels/requirements.txt

Also requires ffmpeg on PATH (yt-dlp uses it to extract audio).

Usage:
    python3 reels/align_reel.py \
        --id n4-reel-01-cafe --video-id XXXXXXXXXXX --level N4 \
        --title "日本のカフェ文化" --title-en "Japanese Cafe Culture" \
        --transcript reels/transcripts/n4-reel-01-cafe.txt

Or, to skip hand-authoring a transcript and pull the video's own Japanese
captions (manual if the uploader added one, else YouTube's auto-captions)
as a starting point instead, swap --transcript for --fetch-captions.

See reels/README.md for the full workflow, including the optional
--translations file.
"""

import argparse
import difflib
import json
import re
import sys
import tempfile
from pathlib import Path
from typing import Any

from janome.tokenizer import Tokenizer

_INGESTION_ROOT = Path(__file__).resolve().parent.parent
if str(_INGESTION_ROOT) not in sys.path:
    sys.path.insert(0, str(_INGESTION_ROOT))

from common.pos_mapping import janome_pos_category  # noqa: E402
from common.text_utils import katakana_to_hiragana, split_sentences  # noqa: E402

ROOT = _INGESTION_ROOT.parent
ASSETS_DIR = ROOT / "assets" / "reels"
MANIFEST_PATH = ASSETS_DIR / "manifest.json"

# Matches the CJK ideograph ranges — used to decide whether a token needs a
# furigana reading at all (pure-kana surfaces don't).
_KANJI_RE = re.compile(r"[一-鿿㐀-䶿]")


def _download_audio(video_id: str, out_dir: Path) -> tuple[Path, float]:
    """Downloads just the audio track as a 16kHz mono WAV (what
    faster-whisper wants) and returns (path, duration_seconds) from
    YouTube's own metadata — more trustworthy than deriving duration from
    ASR output, which can under-run if whisper trails off early on a noisy
    tail.
    """
    import yt_dlp

    opts = {
        "format": "bestaudio/best",
        "outtmpl": str(out_dir / "%(id)s.%(ext)s"),
        "postprocessors": [{
            "key": "FFmpegExtractAudio",
            "preferredcodec": "wav",
            "preferredquality": "0",
        }],
        "postprocessor_args": ["-ar", "16000", "-ac", "1"],
        "quiet": True,
        "no_warnings": True,
        # The default client's stream URLs have been intermittently 403ing
        # (YouTube-side signature/PO-token churn, not video-specific) —
        # the android client's URLs aren't gated the same way and reliably
        # work as of this writing.
        "extractor_args": {"youtube": {"player_client": ["android"]}},
    }
    url = f"https://www.youtube.com/watch?v={video_id}"
    with yt_dlp.YoutubeDL(opts) as ydl:
        info = ydl.extract_info(url, download=True)
    wav_path = out_dir / f"{video_id}.wav"
    if not wav_path.exists():
        raise RuntimeError(f"Expected downloaded audio at {wav_path}")
    return wav_path, float(info["duration"])


def _transcribe_words(audio_path: Path, model_size: str) -> list[tuple[str, float, float]]:
    """Runs faster-whisper with word timestamps and returns a flat
    (text, start_s, end_s) list in order. This is throwaway ASR output used
    only to anchor timing onto the real transcript — see module docstring.
    """
    from faster_whisper import WhisperModel

    model = WhisperModel(model_size, device="cpu", compute_type="int8")
    segments, _info = model.transcribe(
        str(audio_path), language="ja", word_timestamps=True, vad_filter=True,
    )
    words: list[tuple[str, float, float]] = []
    for segment in segments:
        for word in segment.words or []:
            text = word.word.strip()
            if text:
                words.append((text, word.start, word.end))
    if not words:
        raise RuntimeError("faster-whisper returned no word timestamps — check the audio")
    return words


def _whisper_char_timeline(words: list[tuple[str, float, float]]) -> tuple[str, list[float]]:
    """Expands (word, start, end) triples into a flat per-character stream
    with one interpolated start timestamp per character, evenly spaced
    across each word's duration. Japanese has no spaces, so this is the
    same "characters" alphabet the ground-truth transcript is diffed
    against below.
    """
    chars: list[str] = []
    times: list[float] = []
    for text, start, end in words:
        span = max(end - start, 0.001)
        for i, ch in enumerate(text):
            chars.append(ch)
            times.append(start + span * i / len(text))
    return "".join(chars), times


def _fill_gaps(times: list[float | None]) -> list[float]:
    """Linearly interpolates every None run between its nearest known
    neighbors (or extends the nearest known value at either end of the
    sequence)."""
    n = len(times)
    i = 0
    while i < n:
        if times[i] is not None:
            i += 1
            continue
        j = i
        while j < n and times[j] is None:
            j += 1
        left = times[i - 1] if i > 0 else None
        right = times[j] if j < n else None
        left = left if left is not None else right
        right = right if right is not None else left
        span = j - i + 1
        for k in range(i, j):
            times[k] = left + (right - left) * (k - i + 1) / span
        i = j
    return times  # type: ignore[return-value]


def _align_char_timestamps(gt_text: str, whisper_text: str, whisper_times: list[float]) -> list[float]:
    """Maps every character of `gt_text` (the trusted transcript, no
    whitespace) onto a timestamp by diffing it against `whisper_text` (the
    ASR guess — possibly wrong wording, but real timing) and carrying each
    matched position's timestamp over. Characters ASR missed or misheard
    fall in a gap and get linearly interpolated between their nearest
    matched neighbors, so every character ends up with *some* timestamp,
    just a less trustworthy one the further it sits from a real match.
    """
    matcher = difflib.SequenceMatcher(a=gt_text, b=whisper_text, autojunk=False)
    gt_times: list[float | None] = [None] * len(gt_text)
    for a_start, b_start, size in matcher.get_matching_blocks():
        for i in range(size):
            gt_times[a_start + i] = whisper_times[b_start + i]

    if all(t is None for t in gt_times):
        raise RuntimeError(
            "Could not align any transcript characters to the audio — check the "
            "transcript actually matches this video's spoken content"
        )
    return _fill_gaps(gt_times)


def _tokenize_sentence(tokenizer: Tokenizer, sentence: str) -> list[dict[str, Any]]:
    """Tokenizes one sentence into the app's {s, r, d} token shape (see
    lib/features/library/domain/story.dart) — surface form always; a
    dictionary/base form for anything lookup-worthy (everything except bare
    punctuation); a hiragana reading only when the surface actually
    contains kanji (a pure-kana surface doesn't need furigana).
    """
    tokens = []
    for tok in tokenizer.tokenize(sentence):
        surface = tok.surface
        entry: dict[str, Any] = {"s": surface}
        # IPADic has no entry for half-width ASCII punctuation like "?" or
        # "!", so janome's unknown-word fallback tags it as a noun instead
        # of a symbol — checking for at least one alnum character catches
        # that case too, not just tok.part_of_speech's "symbol" category.
        is_word = janome_pos_category(tok.part_of_speech) != "symbol" and any(
            ch.isalnum() for ch in surface
        )
        if is_word:
            entry["d"] = tok.base_form if tok.base_form != "*" else surface
            if tok.reading != "*" and _KANJI_RE.search(surface):
                entry["r"] = katakana_to_hiragana(tok.reading)
        tokens.append(entry)
    return tokens


def _build_sentence_blocks(
    sentences: list[str],
    gt_char_times: list[float],
    tokenizer: Tokenizer,
    total_ms: float,
    translations: list[str] | None,
) -> list[dict[str, Any]]:
    """Tokenizes every sentence, then walks the flat token stream once,
    assigning each token's startMs from its first character's aligned
    timestamp and its endMs from the *next* token's start (chaining tokens
    contiguously, which is what makes karaoke-style highlighting look
    continuous rather than gappy). The very last token is capped by the
    audio's real total duration instead.
    """
    flat_tokens: list[tuple[int, dict[str, Any]]] = []
    cursor = 0
    for si, sentence_text in enumerate(sentences):
        for td in _tokenize_sentence(tokenizer, sentence_text):
            td["_start_char"] = cursor
            cursor += len(td["s"])
            flat_tokens.append((si, td))

    if cursor != len(gt_char_times):
        raise RuntimeError(
            f"Tokenized character count ({cursor}) doesn't match transcript character "
            f"count ({len(gt_char_times)}) — check the transcript for stray whitespace "
            "or characters split_sentences() dropped"
        )

    per_sentence: list[list[dict[str, Any]]] = [[] for _ in sentences]
    for idx, (si, td) in enumerate(flat_tokens):
        start_ms = round(gt_char_times[td["_start_char"]] * 1000)
        if idx + 1 < len(flat_tokens):
            next_start_char = flat_tokens[idx + 1][1]["_start_char"]
            end_ms = round(gt_char_times[next_start_char] * 1000)
        else:
            end_ms = round(total_ms)
        del td["_start_char"]
        td["startMs"] = start_ms
        td["endMs"] = max(end_ms, start_ms + 1)
        per_sentence[si].append(td)

    blocks = []
    for si, tokens in enumerate(per_sentence):
        if not tokens:
            continue
        block: dict[str, Any] = {
            "startMs": tokens[0]["startMs"],
            "endMs": tokens[-1]["endMs"],
            "tokens": tokens,
        }
        if translations is not None:
            block["en"] = translations[si]
        blocks.append(block)
    return blocks


def _fetch_caption_text(video_id: str, out_dir: Path) -> str | None:
    """Pulls the video's existing Japanese caption track — manual if the
    uploader provided one, else YouTube's own auto-captions — via yt-dlp as
    a fast starting transcript, so you don't have to hand-transcribe audio
    just to get *some* ground truth text. json3 is requested instead of
    vtt/srt because YouTube's auto-caption vtt/srt export duplicates text
    across overlapping "rolling" cues; json3 gives clean, non-overlapping
    segments. Returns None if the video has no Japanese captions at all.

    Caveat: this text is only as good as YouTube's own captions — auto-
    captions in particular can mishear words or drop punctuation. Read
    through the generated reel before shipping it, same as any other
    ground-truth transcript.
    """
    import yt_dlp

    opts = {
        "skip_download": True,
        "writesubtitles": True,
        "writeautomaticsub": True,
        "subtitleslangs": ["ja"],
        "subtitlesformat": "json3",
        "outtmpl": str(out_dir / "%(id)s.%(ext)s"),
        "quiet": True,
        "no_warnings": True,
    }
    url = f"https://www.youtube.com/watch?v={video_id}"
    with yt_dlp.YoutubeDL(opts) as ydl:
        ydl.download([url])

    caption_files = sorted(out_dir.glob(f"{video_id}.ja*.json3"))
    if not caption_files:
        return None

    data = json.loads(caption_files[0].read_text(encoding="utf-8"))
    lines = []
    for event in data.get("events", []):
        segs = event.get("segs")
        if not segs:
            continue
        text = "".join(seg.get("utf8", "") for seg in segs).strip()
        if text:
            lines.append(text)
    return "\n".join(lines) if lines else None


def _update_manifest(
    reel_id: str, video_id: str, levels: list[str], title: str, title_en: str, file_path: str, duration_ms: int,
    creator: str, crop_bottom: float,
) -> None:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8")) if MANIFEST_PATH.exists() else []

    entry = {
        "id": reel_id,
        "videoId": video_id,
        "levels": levels,
        "title": title,
        "titleEn": title_en,
        "file": file_path,
        "durationMs": duration_ms,
        "creator": creator,
    }
    if crop_bottom:
        entry["cropBottom"] = crop_bottom
    for i, existing in enumerate(manifest):
        if existing["id"] == reel_id:
            manifest[i] = entry
            break
    else:
        manifest.append(entry)

    MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    with MANIFEST_PATH.open("w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
        f.write("\n")


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--id", required=True, help="Reel id, e.g. n4-reel-01-cafe")
    parser.add_argument("--video-id", required=True, help="YouTube video id (the v= parameter)")
    parser.add_argument(
        "--level", required=True, dest="levels", action="append",
        choices=["N5", "N4", "N3", "N2", "N1"],
        help="JLPT level this video is tagged with. Repeat for videos that legitimately "
        "span two levels, e.g. --level N5 --level N4. The content file is filed under "
        "the first one given.",
    )
    parser.add_argument("--title", required=True, help="Japanese title")
    parser.add_argument("--title-en", required=True, dest="title_en", help="English title")
    parser.add_argument(
        "--creator", required=True,
        help="YouTube channel/content-creator name — the tag the video-library browse "
        "screen groups and filters by (one creator's videos == one 'playlist' there).",
    )
    parser.add_argument(
        "--transcript", type=Path, default=None,
        help="Path to a ground-truth Japanese transcript .txt (shown verbatim in the app). "
        "Omit to use --fetch-captions instead.",
    )
    parser.add_argument(
        "--fetch-captions", action="store_true",
        help="Pull the video's own Japanese captions (manual if available, else YouTube's "
        "auto-captions) via yt-dlp instead of --transcript. Fast, but only as accurate as "
        "YouTube's own captions — review the result before treating it as final.",
    )
    parser.add_argument(
        "--translations", type=Path, default=None,
        help="Optional: one English line per sentence, matching split_sentences() order",
    )
    parser.add_argument(
        "--whisper-model", default="medium",
        help="faster-whisper model size (default: medium; try small for faster iteration, "
        "large-v3 if medium mishears a specific video)",
    )
    parser.add_argument(
        "--keep-audio", action="store_true",
        help="Keep the downloaded audio (under assets/reels/_debug_audio/) instead of discarding it",
    )
    parser.add_argument(
        "--crop-bottom", type=float, default=0.0,
        help="Fraction of the video's height (0-1) to crop out of view, measured from the "
        "bottom — for source videos with hardcoded captions or a watermark baked into the "
        "picture. Check the actual footage (thumbnails are often custom and unrepresentative) "
        "before setting this; most reels don't need it.",
    )
    args = parser.parse_args()

    if not args.transcript and not args.fetch_captions:
        parser.error("Provide --transcript PATH or pass --fetch-captions")

    with tempfile.TemporaryDirectory() as tmp:
        tmp_dir = Path(tmp)

        if args.transcript:
            transcript_text = args.transcript.read_text(encoding="utf-8")
        else:
            print(f"Fetching captions for {args.video_id}...")
            transcript_text = _fetch_caption_text(args.video_id, tmp_dir)
            if transcript_text is None:
                raise SystemExit(
                    f"No Japanese captions found for {args.video_id} — supply --transcript instead"
                )

        sentences = split_sentences(transcript_text)
        if not sentences:
            raise SystemExit("No sentences found in the transcript")

        translations: list[str] | None = None
        if args.translations:
            translations = [
                line.strip()
                for line in args.translations.read_text(encoding="utf-8").splitlines()
                if line.strip()
            ]
            if len(translations) != len(sentences):
                raise SystemExit(
                    f"--translations has {len(translations)} lines but the transcript has "
                    f"{len(sentences)} sentences"
                )

        print(f"Downloading audio for {args.video_id}...")
        audio_path, duration_s = _download_audio(args.video_id, tmp_dir)

        print(f"Transcribing with faster-whisper ({args.whisper_model})...")
        whisper_words = _transcribe_words(audio_path, args.whisper_model)
        print(f"  {len(whisper_words)} ASR words")

        if args.keep_audio:
            kept = ASSETS_DIR / "_debug_audio" / f"{args.video_id}.wav"
            kept.parent.mkdir(parents=True, exist_ok=True)
            kept.write_bytes(audio_path.read_bytes())
            print(f"  kept audio at {kept}")

    gt_text = "".join(sentences)
    whisper_text, whisper_times = _whisper_char_timeline(whisper_words)
    print("Aligning transcript to audio timing...")
    gt_char_times = _align_char_timestamps(gt_text, whisper_text, whisper_times)

    print("Tokenizing with janome...")
    tokenizer = Tokenizer()
    duration_ms = round(duration_s * 1000)
    sentence_blocks = _build_sentence_blocks(sentences, gt_char_times, tokenizer, duration_ms, translations)

    primary_level = args.levels[0]
    reel = {
        "id": args.id,
        "videoId": args.video_id,
        "level": primary_level,
        "title": args.title,
        "titleEn": args.title_en,
        "durationMs": duration_ms,
        "sentences": sentence_blocks,
    }

    level_dir = ASSETS_DIR / primary_level.lower()
    level_dir.mkdir(parents=True, exist_ok=True)
    rel_file = f"{primary_level.lower()}/{args.id}.json"
    out_path = ASSETS_DIR / rel_file
    with out_path.open("w", encoding="utf-8") as f:
        json.dump(reel, f, ensure_ascii=False, separators=(",", ":"))
    print(f"Wrote {out_path} ({len(sentence_blocks)} sentences)")

    _update_manifest(
        args.id, args.video_id, args.levels, args.title, args.title_en, rel_file, duration_ms,
        args.creator, args.crop_bottom,
    )
    print(f"Updated {MANIFEST_PATH}")


if __name__ == "__main__":
    main()
