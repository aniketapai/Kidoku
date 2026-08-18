import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../backup/presentation/restore_prompt.dart';
import 'widgets/yomu_bottom_bar.dart';

/// Root of the signed-in app. Also where a cloud-backup restore gets
/// offered (see [maybeOfferRestore]) — this is the one place guaranteed to
/// run whenever the signed-in area is entered, regardless of whether that
/// happened via an explicit sign-in or an auth session the platform
/// restored on its own.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) maybeOfferRestore(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: YomuBottomBar(
              currentIndex: navigationShell.currentIndex,
              onSelect: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
