import 'package:flutter/material.dart';

import '../domain/reel.dart';
import 'widgets/reel_player_page.dart';

/// Which video [ReelsScreen] plays — built by the video-library browse
/// screen when the viewer taps a video.
class ReelPlayerArgs {
  const ReelPlayerArgs({required this.meta});

  final ReelMeta meta;
}

/// Single-video playback screen: the tapped video plus its synced
/// transcript. No feed and no swiping — the viewer backs out to the
/// library to pick another video.
class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key, required this.args});

  final ReelPlayerArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ReelPlayerPage(meta: args.meta),
    );
  }
}
