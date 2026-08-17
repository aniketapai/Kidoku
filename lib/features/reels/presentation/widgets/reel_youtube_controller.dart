import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// A [YoutubePlayerController] that points the IFrame player at a page we
/// host ourselves (see `hosting/player.html`) instead of the base
/// controller's default: a local HTML string loaded via
/// `WebView.loadHtmlString(..., baseUrl: 'https://www.youtube.com')`.
///
/// That default trick makes the WebView's JS *claim* youtube.com as its
/// origin without ever making a real network request to it, so no genuine
/// `Referer` header goes out when the nested YouTube iframe loads —
/// YouTube's servers reject the embed for that (surfaces as "This video is
/// unavailable, Error code: 152 - 4" / "Error 153: Video player
/// configuration error"). A real `https://` page hosted at a real domain,
/// navigated to with a genuine [loadRequest], sends a real `Referer` that
/// YouTube accepts.
///
/// Only [load] differs from the base controller — it's a plain public
/// method invoked polymorphically from `init()`, so everything else
/// (state/error streams, mute/play/pause, iOS WebKit setup) is inherited
/// unchanged.
class ReelYoutubeController extends YoutubePlayerController {
  ReelYoutubeController({required YoutubePlayerParams params, required String videoId})
      : super(params: params, key: videoId);

  static const _hostedPlayerUrl = 'https://yomu-1a574.web.app/player.html';

  @override
  Future<void> load({
    required YoutubePlayerParams params,
    String? baseUrl,
    String id = 'player',
  }) async {
    final uri = Uri.parse(_hostedPlayerUrl).replace(
      queryParameters: {
        'playerId': id,
        'platform': defaultTargetPlatform.name.toLowerCase(),
        'playerVars': jsonEncode(params.toMap()),
      },
    );
    // youtube_player_iframe marks webViewController @internal, but exposes
    // no other way to point it at a different URL — same rationale as the
    // cookie-manager reach-past this replaces.
    // ignore: invalid_use_of_internal_member
    await webViewController.loadRequest(uri);
  }
}
