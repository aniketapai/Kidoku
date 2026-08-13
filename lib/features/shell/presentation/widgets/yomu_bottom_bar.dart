import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/due_review_count_provider.dart';
import 'pulsing_badge.dart';

class _NavItemData {
  const _NavItemData(this.icon, this.label);
  final IconData icon;
  final String label;
}

const _kItems = [
  _NavItemData(Icons.menu_book_rounded, 'Library'),
  _NavItemData(Icons.style_rounded, 'Review'),
  _NavItemData(Icons.bookmark_rounded, 'Vocabulary'),
  _NavItemData(Icons.search_rounded, 'Dictionary'),
  _NavItemData(Icons.person_rounded, 'Profile'),
];

/// Floating pill bottom nav bar — spec section 10.
class YomuBottomBar extends ConsumerWidget {
  const YomuBottomBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueCount = ref.watch(dueReviewCountProvider).value ?? 0;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: colorScheme.surfaceContainerHighest, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slotWidth = constraints.maxWidth / _kItems.length;
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutBack,
                    left: slotWidth * currentIndex,
                    top: 8,
                    width: slotWidth,
                    height: 48,
                    child: Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < _kItems.length; i++)
                        SizedBox(
                          width: slotWidth,
                          height: 64,
                          child: _BottomBarItem(
                            icon: _kItems[i].icon,
                            label: _kItems[i].label,
                            isSelected: i == currentIndex,
                            badgeCount: i == 1 ? dueCount : null,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onSelect(i);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.badgeCount,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final int? badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.15 : 0.9,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(
                    begin: colorScheme.onSurfaceVariant,
                    end: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, color, child) => Icon(icon, color: color, size: 24),
                ),
              ),
              if (badgeCount != null && badgeCount! > 0)
                Positioned(
                  top: -6,
                  right: -10,
                  child: PulsingBadge(count: badgeCount!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
