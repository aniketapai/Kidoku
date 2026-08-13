# Yomu — Japanese Reading & JLPT App
### Full build spec for Claude Code

---

## 0. App Identity

**Name:** Yomu (読む — "to read")
Short, easy to say, pairs with your existing vocab app naming style (Kotoba). Package/module name suggestion: `com.aniket.yomu`.

**Icon concept:** A single open-book silhouette where the right-hand page morphs into the 読 kanji stroke, inside a circular badge with a soft gradient (indigo → vermillion). Simple enough to read at 48dp launcher size. Ask Claude Code to generate this as an adaptive icon (foreground vector + solid background layer) — don't try to render fine kanji detail at small sizes, keep it to 2–3 bold strokes.

**Color theme — "Ai to Shu" (indigo & vermillion), inspired by washi paper and hanko ink:**

| Token | Light | Dark | Usage |
|---|---|---|---|
| `primary` | `#2D3E63` (ai-iro indigo) | `#8FA8D8` | app bar, primary buttons, selected nav state |
| `onPrimary` | `#FFFFFF` | `#0F1729` | text/icons on primary |
| `secondary` / accent | `#E6553D` (shu vermillion) | `#FF7A61` | CTAs, streaks, SRS "due" badges, save button |
| `background` | `#F7F3EA` (washi cream) | `#15151A` (sumi ink) | screen background |
| `surface` | `#FFFFFF` | `#1E1E24` | cards, sheets, nav bar |
| `surfaceVariant` | `#EDE7D9` | `#26262E` | filter chips, token backgrounds |
| N5 level tag | `#4C9A6E` | same | vocab/level chip |
| N4 level tag | `#5B8FD4` | same | |
| N3 level tag | `#D4A64C` | same | |
| N2 level tag | `#D47A4C` | same | |
| N1 level tag | `#C4514C` | same | |

**Typography:** Use a Japanese-capable variable font — `Noto Sans JP` for UI text/kanji, and a distinct serif/rounded companion (e.g. `Zen Maru Gothic` or `M PLUS Rounded 1c`) for headings/branding, so kanji rendering stays crisp while headings feel a bit more designed. Furigana rendered at ~0.5× the base text size via the custom `FuriganaText` composable already planned.

Feed this section to Claude Code as-is — theme tokens map directly to a Compose `Color.kt` / `Theme.kt` and a Material3 dynamic-color fallback.

---

## 1. Product Recap

Yomu lets a learner read real Japanese content (news, literature, graded stories) filtered by estimated JLPT difficulty, tap any word for reading/meaning/JLPT level, save words into SRS review, and track progress toward N5→N1.

Core loop: **browse by level → read with tap-to-lookup → save/mark known → review via SRS.**

This spec extends your existing Kotlin/Compose architecture (MVVM, Hilt, Room, Navigation Compose type-safe routes, Firebase Auth/Firestore) — it does not replace it.

---

## 2. High-Level Architecture

```
┌─────────────────────────────┐
│      Content Sources         │
│ NHK Easy · Aozora Bunko ·    │
│ Graded story providers       │
└──────────────┬───────────────┘
               ↓
┌─────────────────────────────┐
│   Ingestion Pipeline (offline/│
│   server-side, NOT on-device) │
│ tokenize → normalize →        │
│ JMdict lookup → JLPT lookup → │
│ difficulty score               │
└──────────────┬───────────────┘
               ↓
┌─────────────────────────────┐
│   Firestore (processed        │
│   articles + token metadata)  │
│   + Cloud Storage (raw text)  │
└──────────────┬───────────────┘
               ↓
┌─────────────────────────────┐
│   Android app (Kotlin/Compose)│
│   Repository → ViewModel →    │
│   StateFlow → Compose UI      │
│   Room caches: JMdict, JLPT   │
│   vocab list, user words      │
└───────────────────────────────┘
```

**Key decision carried over from your stories work:** content is tokenized and difficulty-scored *once*, offline, and shipped as structured JSON/Firestore docs — never on-device at read time. This is the same pattern you already used for the N5 story batch; this spec just generalizes it to NHK/Aozora ingestion.

---

## 3. Content Sources

| Source | What it gives you | Constraints |
|---|---|---|
| **NHK Easy / NHK News Web** | Simplified news, some furigana already, frequently updated | No public API — ingestion means scraping, so respect robots.txt/ToS, cache only what you need, keep attribution + source link, don't bulk-mirror the archive. Treat as a lower-reliability source that may need to be pulled if terms change. |
| **Aozora Bunko** | Large public-domain-ish literature catalog (Soseki, Akutagawa, Dazai…) | Rights are per-work, not per-site — store each work's stated copyright/PD status in your DB. Old literature skews archaic; don't auto-label as beginner-friendly regardless of your difficulty score — flag pre-1950 works separately. |
| **Graded story providers (e.g. Shinobi Japanese)** | Purpose-built N5–N2 stories | Only integrate if they offer explicit API/license terms for reuse — no scraping "free to read" pages. Treat as a manual/opt-in source per provider. |
| **Your own N5 story batch** | Already-refined, already-tokenized JSON | Keep as the seed/fallback content so the app has good N5 content on day one even before ingestion pipeline is live. |

Store per source: id, url, title, published date, full text, license/PD status, source difficulty label, optional image/audio. Never assume a source gives you tokenization or JLPT metadata — that's always your own pipeline's job.

---

## 4. Tokenization & Reading Lookup

**Recommendation: don't tokenize on-device.** Sudachi's dictionaries are 100MB+ and this is a batch job that only needs to run once per article, so it belongs in the ingestion pipeline, not the APK.

Two viable ways to run it, both worth wiring up so you have a fallback:

1. **Self-hosted micro-service (preferred for reliability):** a small FastAPI/Cloud Run service wrapping SudachiPy (mode C, so compounds like 東京都 stay whole). This pattern already exists as an open-source reference (`sen-ltd/furigana-api` on GitHub, MIT license) — worth reading for the wrapper code even if you build your own. Deploy your own instance rather than depending on someone else's uptime.
2. **Free hosted API as a quick-start / dev fallback:** projects like **Yomi API** (`yomi.onrender.com/analyze`) expose a POST endpoint that tokenizes text and can return furigana/romaji directly — good for prototyping the pipeline this week, but it's a small hobby-hosted service with no uptime guarantee, so don't build production ingestion around it long-term.

Either way, the contract your app needs is the same:

```json
{
  "surface": "発表しました",
  "dictionary_form": "発表する",
  "reading": "はっぴょうする",
  "part_of_speech": "verb",
  "start": 10,
  "end": 15
}
```

Ingestion pipeline steps (Cloud Function, scheduled or triggered on new content):
1. Fetch/clean raw text → split sentences
2. Tokenize (service above)
3. Normalize inflected forms to dictionary form
4. JMdict lookup per dictionary form
5. JLPT vocab-level lookup
6. Compute difficulty score (below)
7. Write processed article + tokens to Firestore

---

## 5. Dictionary & JLPT Data Layer

- **JMdict** → pre-convert to a SQLite file at build/ingestion time, ship as a prepackaged Room database (`assets/jmdict.db`) so lookups are instant and offline. Don't hit a live dictionary API from the reader screen.
- **JLPT vocab list** (word, reading, level) → same treatment, a small prepackaged Room table. Treat every level assignment as an estimate, not ground truth — there's no official exhaustive JLPT word list.
- Cache dictionary lookups so re-reading an article never re-queries.

```kotlin
@Entity(tableName = "dictionary_entries")
data class DictionaryEntry(
    @PrimaryKey val dictionaryForm: String,
    val reading: String,
    val meanings: List<String>,
    val partOfSpeech: String,
    val jlptLevel: String?
)
```

---

## 6. Difficulty Scoring

```
difficulty_score =
    0.50 * vocabulary_score      // weighted N5..N1 coverage
  + 0.20 * unknown_word_score    // % not in JMdict/JLPT list
  + 0.15 * kanji_score           // avg kanji grade-level in article
  + 0.10 * sentence_length_score
  + 0.05 * grammar_score         // detected grammar points vs level
```

Weights live in a remote-config-style Firestore doc so you can tune them without shipping an app update.

**Filter semantics — cumulative, not exact-match:**
- Filter = N4 → show articles whose `estimated_level` is N4 *or easier*, ranked by N5+N4 vocab coverage.
- Add an optional **strict mode** toggle for users who specifically want "N4 words only."
- Later: personalize against the user's own known/learning word list instead of a flat level, so "Easy for you" vs "Challenging for you" badges become possible.

---

## 7. Data Models

**Firestore collections** (source of truth for content, synced/cached into Room on-device):

```
articles/{articleId}
  source, sourceId, url, title, publishedAt, text,
  estimatedJlpt, difficultyScore,
  n5Coverage, n4Coverage, n3Coverage, n2Coverage, n1UnknownCoverage,
  licenseStatus, createdAt, updatedAt

articles/{articleId}/tokens/{tokenId}
  sentenceId, surface, dictionaryForm, reading,
  partOfSpeech, startPosition, endPosition, jlptLevel
```

**Room (on-device, per-user, offline-first):**

```kotlin
@Entity(tableName = "user_words")
data class UserWord(
    @PrimaryKey val dictionaryForm: String,
    val status: WordStatus,       // KNOWN, LEARNING, SAVED
    val savedAt: Long,
    val lastSeen: Long,
    val srsDueAt: Long?,
    val srsInterval: Int = 0
)

enum class WordStatus { KNOWN, LEARNING, SAVED }
```

Sync `user_words` to Firestore under `users/{uid}/words/{dictionaryForm}` so progress survives reinstalls, matching your existing Firebase Auth setup.

---

## 8. Repository / ViewModel Layer

```
ContentRepository       — Firestore article list/detail, filter by jlpt+source, local Room cache
DictionaryRepository    — Room-backed JMdict + JLPT lookups (offline)
UserWordRepository       — Room + Firestore sync for known/learning/saved words
SrsRepository            — scheduling logic (SM-2 or similar) over UserWord
```

Each screen's ViewModel exposes a single `StateFlow<UiState>` combining these, per your existing MVVM pattern.

---

## 9. Navigation (type-safe routes)

```kotlin
sealed interface Dest {
    @Serializable data object Library : Dest
    @Serializable data class Reader(val articleId: String) : Dest
    @Serializable data object Review : Dest
    @Serializable data object Vocabulary : Dest
    @Serializable data object Profile : Dest
}
```

Top-level screens live behind the bottom nav (Library, Review, Vocabulary, Profile); Reader is pushed on top full-screen (no bottom nav visible while reading, to maximize text space — bring the nav back via a swipe-down or back gesture).

---

## 10. Bottom Navigation Bar — detailed spec

Goal: a floating, pill-shaped nav bar that feels alive, not a stock Material bar.

**Structure**
- 4 destinations: **Library** (book icon), **Review** (flashcard icon, shows a small vermillion badge with due-count), **Vocabulary** (bookmark icon), **Profile** (circular avatar/person icon).
- Floating card, not edge-to-edge: `Modifier.padding(horizontal = 20.dp, vertical = 12.dp)`, height 64dp, corner radius 32dp (fully rounded pill), `surface` color with a soft elevation shadow (8dp) and a subtle 1dp border in `surfaceVariant` for definition in light mode.
- Respect gesture nav: `Modifier.navigationBarsPadding()` before applying the outer padding above, so it never collides with the system gesture bar.

**Animation**
- A single rounded "indicator" shape sits *behind* the selected icon and slides between tabs using `updateTransition` + `animateDpAsState` (spring: `dampingRatio = Spring.DampingRatioMediumBouncy`, `stiffness = Spring.StiffnessLow`) — no linear tweening, it should feel springy.
- Selected icon scales from 1.0 → 1.15 and crossfades from `onSurfaceVariant` to `onPrimary`/`accent` color over ~200ms.
- Unselected icons sit at 0.9 scale, muted color.
- On tap: trigger `LocalHapticFeedback.current.performHapticFeedback(HapticFeedbackType.TextHandleMove)` for a light tactile click alongside the visual animation.
- Review tab badge (due-count) pulses gently (scale 1→1.08→1, 1.5s loop, `Spring` or `infiniteRepeatable`) when count > 0, so it draws the eye without being obnoxious.

**Skeleton for Claude Code to build from:**

```kotlin
@Composable
fun YomuBottomBar(
    items: List<NavItem>,
    selected: Dest,
    onSelect: (Dest) -> Unit,
) {
    Surface(
        modifier = Modifier
            .navigationBarsPadding()
            .padding(horizontal = 20.dp, vertical = 12.dp)
            .height(64.dp)
            .shadow(8.dp, RoundedCornerShape(32.dp)),
        shape = RoundedCornerShape(32.dp),
        color = MaterialTheme.colorScheme.surface,
    ) {
        Row(
            modifier = Modifier.fillMaxSize().padding(horizontal = 8.dp),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            items.forEach { item ->
                val isSelected = item.dest == selected
                val scale by animateFloatAsState(
                    targetValue = if (isSelected) 1.15f else 0.9f,
                    animationSpec = spring(
                        dampingRatio = Spring.DampingRatioMediumBouncy,
                        stiffness = Spring.StiffnessLow,
                    ),
                    label = "iconScale",
                )
                val tint by animateColorAsState(
                    targetValue = if (isSelected)
                        MaterialTheme.colorScheme.primary
                    else
                        MaterialTheme.colorScheme.onSurfaceVariant,
                    label = "iconTint",
                )
                val haptics = LocalHapticFeedback.current

                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .background(
                            if (isSelected)
                                MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.4f)
                            else Color.Transparent
                        )
                        .clickable {
                            haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                            onSelect(item.dest)
                        },
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        imageVector = item.icon,
                        contentDescription = item.label,
                        tint = tint,
                        modifier = Modifier.size(24.dp).scale(scale),
                    )
                    if (item.badgeCount != null && item.badgeCount > 0) {
                        PulsingBadge(
                            count = item.badgeCount,
                            modifier = Modifier.align(Alignment.TopEnd),
                        )
                    }
                }
            }
        }
    }
}
```

Let Claude Code fill in `PulsingBadge` (an `infiniteTransition` scaling a small vermillion circle with the count) and wire `NavItem` to your `Dest` sealed interface.

---

## 11. Screens

- **Library** — filter chips (All / N5 / N4 / N3 / N2 / N1 + source toggle NHK/Aozora/Stories), article cards showing title, estimated level pill, source tag, coverage sparkline.
- **Reader** — full-screen text, furigana toggle, tap any token → bottom sheet popup: reading, meaning, POS, JLPT chip, Save / Mark Known buttons, optional example sentence and audio.
- **Review (SRS)** — due-count front and center, flashcard flow over `UserWord` entries due today.
- **Vocabulary** — saved/learning/known word lists, filterable by JLPT level and status.
- **Profile** — streak, JLPT readiness estimate per level (based on known-word coverage against the JLPT list), settings link.

Unknown-word highlighting in the reader should stay subtle (e.g. a thin underline, not a colored background) so the page doesn't look like a test.

---

## 12. Legal/Licensing Notes (keep visible in the codebase, not just this doc)

- Store attribution + license/PD status per article, separate from the NLP pipeline, so a source can be pulled without touching tokenization code.
- Don't bulk-mirror NHK's archive — ingest incrementally, keep source links, respect robots.txt.
- Aozora Bunko: check the individual work's rights notice, not just "it's on Aozora."
- Any graded-story provider needs an explicit license/API grant before their text enters your DB.
- JMdict is available under a permissive license (Monash University / EDRDG) but still requires attribution — include it in an About/Licenses screen.

---

## 13. Phased Build Plan

**Phase 1 — Reader core**
Bootstrap navigation + bottom bar (section 10) → Library screen with your existing N5 story batch as seed content → Reader screen with tap-to-lookup against prepackaged JMdict Room DB → furigana rendering.

**Phase 2 — Difficulty & filtering**
JLPT vocab Room table → difficulty scoring → N5–N1 filter chips wired to real coverage numbers.

**Phase 3 — User data**
`user_words` Room + Firestore sync → save/known/mark → SRS scheduling → Review screen → unknown-word highlighting in Reader.

**Phase 4 — Content pipeline**
Stand up ingestion Cloud Function (tokenizer service from section 4) → Aozora Bunko ingestion → NHK Easy ingestion → graded-story provider(s) if/when licensed.

**Phase 5 — Polish**
Profile/progress screen, streaks, bottom-bar animation polish, audio, dark theme pass, Play Store prep.

---

## 14. Open Config Knobs (leave as constants Claude Code can tune)

- Difficulty score weights (section 6)
- Sudachi split mode (C recommended)
- SRS interval curve (SM-2 default vs custom)
- Strict-mode filter threshold (e.g. ≥95% words at-or-below selected level)