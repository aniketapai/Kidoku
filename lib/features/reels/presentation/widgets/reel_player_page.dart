import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../reader/presentation/widgets/lookup_bottom_sheet.dart';
import '../../application/reel_providers.dart';
import '../../domain/reel.dart';
import 'reel_sentence_list.dart';
import 'reel_youtube_controller.dart';

/// A single reel: a full-width 16:9 YouTube video up top and its synced
/// transcript panel below. Owns its [YoutubePlayerController] for exactly
/// as long as this widget's State is alive — created in [initState], closed
/// in [dispose].
class ReelPlayerPage extends ConsumerStatefulWidget {
  const ReelPlayerPage({super.key, required this.meta});

  final ReelMeta meta;

  @override
  ConsumerState<ReelPlayerPage> createState() => _ReelPlayerPageState();
}

class _ReelPlayerPageState extends ConsumerState<ReelPlayerPage> {
  late final ReelYoutubeController _controller;
  final ValueNotifier<int> _positionMs = ValueNotifier(0);
  bool _unmuted = false;
  // Matches the story reader's default (lib/features/library/presentation/
  // story_reader_screen.dart) — off by default, session-only, not persisted.
  bool _showFurigana = false;

  @override
  void initState() {
    super.initState();
    _controller = ReelYoutubeController(
      videoId: widget.meta.videoId,
      params: const YoutubePlayerParams(
        showControls: false,
        showFullscreenButton: false,
        strictRelatedVideos: true,
        mute: true,
        loop: true,
        // The transcript panel below the video is the app's own caption
        // track — YouTube's baked-in CC would duplicate it (and can't be
        // styled or synced to word-level highlighting), so don't force it
        // on. cc_load_policy=0 still lets a user who has YouTube captions
        // enabled globally see them; there's no IFrame param that hard-
        // disables captions outright.
        enableCaption: false,
        // Must match hosting/player.html's real domain — see
        // ReelYoutubeController's doc comment for why.
        origin: 'https://yomu-1a574.web.app',
        // YouTube serves "video unavailable" to the stock Android WebView
        // user agent (it self-identifies as an embedded WebView via a
        // "; wv)" marker) for videos that play fine in a real browser or
        // the YouTube app — spoofing a plain Chrome-mobile UA avoids that.
        userAgent:
            'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
      ),
    );
    _controller.loadVideoById(videoId: widget.meta.videoId);
    _controller.videoStateStream.listen((state) {
      _positionMs.value = state.position.inMilliseconds;
    });
  }

  @override
  void dispose() {
    _saveProgress();
    _positionMs.dispose();
    _controller.close();
    super.dispose();
  }

  void _saveProgress() {
    final positionMs = _positionMs.value;
    if (positionMs <= 0) return;
    ref
        .read(reelProgressActionsProvider)
        .save(
          widget.meta.id,
          lastPositionMs: positionMs,
          completed: positionMs >= widget.meta.durationMs - 2000,
        );
  }

  void _toggleMute() {
    setState(() => _unmuted = !_unmuted);
    if (_unmuted) {
      _controller.unMute();
    } else {
      _controller.mute();
    }
  }

  void _toggleFurigana() => setState(() => _showFurigana = !_showFurigana);

  /// Pauses the video for the duration of a word lookup and resumes it once
  /// the popup is dismissed, so the reel doesn't keep playing (and the
  /// transcript auto-scrolling) out from under a word the viewer is reading.
  Future<void> _onTokenTap(String dictionaryForm) async {
    _controller.pauseVideo();
    await showLookupBottomSheet(context, dictionaryForm);
    if (mounted) _controller.playVideo();
  }

  @override
  Widget build(BuildContext context) {
    final reelAsync = ref.watch(reelProvider(widget.meta.file));

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // These are standard 16:9 landscape videos (confirmed via
                // YouTube's oEmbed). Deliberately NOT wrapped in our own
                // AspectRatio here — YoutubePlayer already applies
                // `aspectRatio` internally, but it decides *which* ratio to
                // use via an internal OrientationBuilder that checks
                // whether its own immediate box is wider than tall. Column
                // gives a plain (non-Expanded) child unbounded height, so
                // that box reads as "portrait" and it correctly uses
                // `aspectRatio: 16/9` below. Pre-constraining it ourselves
                // with an outer AspectRatio(16/9) makes that same check see
                // a landscape-shaped box instead, which YoutubePlayer takes
                // to mean "device rotated to fullscreen" — it then
                // substitutes the *phone's own* portrait aspect ratio for
                // the video, rendering it squeezed into a narrow vertical
                // strip. Confirmed live via Chrome DevTools
                // (chrome://inspect) showing the WebView laid out at
                // 273×608 instead of full width.
                // Crops out a hardcoded-caption/watermark band without
                // zooming: Align's heightFactor reports a shorter box to
                // the Stack while the player itself still lays out at its
                // full, undistorted 16:9 size — ClipRect just hides
                // whatever of it falls outside that shorter box. Cutting
                // straight to the bottom edge (vs. scaling the whole frame
                // up to fill the space back in) is what was asked for over
                // the zoomed version this replaced.
                ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 1 - widget.meta.cropBottom,
                    child: YoutubePlayer(
                      controller: _controller,
                      aspectRatio: 16 / 9,
                      enableFullScreenOnVerticalDrag: false,
                    ),
                  ),
                ),
                Expanded(
                  child: reelAsync.when(
                    data: (reel) => ReelSentenceList(
                      reel: reel,
                      positionMs: _positionMs,
                      showFurigana: _showFurigana,
                      onTokenTap: _onTokenTap,
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white70),
                    ),
                    error: (error, stackTrace) => const Center(
                      child: Text(
                        'Couldn\'t load this reel\'s transcript.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _ReelSidePanel(
                  showFurigana: _showFurigana,
                  onToggleFurigana: _toggleFurigana,
                  unmuted: _unmuted,
                  onToggleMute: _toggleMute,
                ),
              ),
            ),
            Positioned(
              left: 4,
              top: 4,
              child: _ReelIconButton(
                icon: Icons.arrow_back_rounded,
                semanticLabel: 'Back to videos',
                active: false,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small action rail pinned to the right edge of the page — furigana and
/// sound toggles. Just this one video at a time; back out (top-left) to
/// pick another from the library.
class _ReelSidePanel extends StatelessWidget {
  const _ReelSidePanel({
    required this.showFurigana,
    required this.onToggleFurigana,
    required this.unmuted,
    required this.onToggleMute,
  });

  final bool showFurigana;
  final VoidCallback onToggleFurigana;
  final bool unmuted;
  final VoidCallback onToggleMute;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FuriganaButton(shown: showFurigana, onTap: onToggleFurigana),
        const SizedBox(height: 16),
        _MuteButton(unmuted: unmuted, onTap: onToggleMute),
      ],
    );
  }
}

class _MuteButton extends StatelessWidget {
  const _MuteButton({required this.unmuted, required this.onTap});

  final bool unmuted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ReelIconButton(
      icon: unmuted ? Icons.volume_up_rounded : Icons.volume_off_rounded,
      semanticLabel: 'Sound',
      active: unmuted,
      onTap: onTap,
    );
  }
}

class _FuriganaButton extends StatelessWidget {
  const _FuriganaButton({required this.shown, required this.onTap});

  final bool shown;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ReelIconButton(
      icon: shown ? Icons.text_fields : Icons.text_fields_outlined,
      semanticLabel: 'Furigana',
      active: shown,
      onTap: onTap,
    );
  }
}

/// Bare icon circle for the video overlay controls — no text label, just
/// the icon, with a bigger/brighter active state so Furigana/Sound are
/// still easy to spot against arbitrary video content.
class _ReelIconButton extends StatelessWidget {
  const _ReelIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: Material(
          color: active ? AppColors.secondary : Colors.black.withValues(alpha: 0.6),
          shape: const CircleBorder(),
          elevation: active ? 3 : 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: active ? AppColors.onSecondary : Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
