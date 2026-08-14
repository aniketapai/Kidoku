import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../kanji_stroke_data.dart';

/// KanjiVG's fixed drawing canvas — every bundled stroke path is authored
/// against this 109x109 viewBox, so painting just scales it to fit.
const double _kKanjiViewBoxSize = 109;
const double _kMsPerStroke = 500;

Future<void> showKanjiStrokeSheet(BuildContext context, String kanji) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (context) => KanjiStrokeSheet(kanji: kanji),
  );
}

class KanjiStrokeSheet extends ConsumerWidget {
  const KanjiStrokeSheet({super.key, required this.kanji});

  final String kanji;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(kanjiStrokeDataProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(kanji, style: textTheme.headlineMedium),
            const SizedBox(height: 12),
            dataAsync.when(
              data: (data) {
                final strokes = strokePathsFor(data, kanji);
                if (strokes == null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Stroke order not available for this character.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                }
                return _KanjiStrokeAnimation(strokes: strokes, colorScheme: colorScheme);
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => Text('Could not load stroke data: $error'),
            ),
            const SizedBox(height: 8),
            Text(
              'Stroke data © KanjiVG contributors, CC BY-SA 3.0',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KanjiStrokeAnimation extends StatefulWidget {
  const _KanjiStrokeAnimation({required this.strokes, required this.colorScheme});

  final List<Path> strokes;
  final ColorScheme colorScheme;

  @override
  State<_KanjiStrokeAnimation> createState() => _KanjiStrokeAnimationState();
}

class _KanjiStrokeAnimationState extends State<_KanjiStrokeAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_kMsPerStroke * widget.strokes.length).round()),
    );
    // The play/pause icon lives outside the progress AnimatedBuilder below,
    // so it needs its own rebuild trigger for when the animation finishes
    // on its own (not just on user-driven play/pause taps).
    _controller.addStatusListener(_onStatusChanged);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onStatusChanged(AnimationStatus status) {
    if (mounted) setState(() {});
  }

  void _replay() => _controller.forward(from: 0);

  void _togglePlayPause() {
    if (_controller.isAnimating) {
      _controller.stop();
    } else {
      if (_controller.isCompleted) {
        _controller.forward(from: 0);
      } else {
        _controller.forward();
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 240,
          height: 240,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _KanjiStrokePainter(
                  strokes: widget.strokes,
                  progress: _controller.value,
                  strokeColor: widget.colorScheme.onSurface,
                  guideColor: widget.colorScheme.onSurface.withValues(alpha: 0.15),
                ),
                size: const Size(240, 240),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _togglePlayPause,
              icon: Icon(_controller.isAnimating ? Icons.pause : Icons.play_arrow),
              tooltip: _controller.isAnimating ? 'Pause' : 'Play',
            ),
            IconButton(
              onPressed: _replay,
              icon: const Icon(Icons.replay),
              tooltip: 'Replay',
            ),
          ],
        ),
      ],
    );
  }
}

class _KanjiStrokePainter extends CustomPainter {
  _KanjiStrokePainter({
    required this.strokes,
    required this.progress,
    required this.strokeColor,
    required this.guideColor,
  });

  final List<Path> strokes;
  final double progress;
  final Color strokeColor;
  final Color guideColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _kKanjiViewBoxSize;
    canvas.save();
    canvas.scale(scale, scale);

    final guidePaint = Paint()
      ..color = guideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final stroke in strokes) {
      canvas.drawPath(stroke, guidePaint);
    }

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final totalProgress = progress * strokes.length;
    for (var i = 0; i < strokes.length; i++) {
      final strokeProgress = (totalProgress - i).clamp(0.0, 1.0);
      if (strokeProgress <= 0) break;
      final path = strokes[i];
      if (strokeProgress >= 1.0) {
        canvas.drawPath(path, strokePaint);
        continue;
      }
      for (final metric in path.computeMetrics()) {
        final extracted = metric.extractPath(0, metric.length * strokeProgress);
        canvas.drawPath(extracted, strokePaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KanjiStrokePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.strokes != strokes;
}
