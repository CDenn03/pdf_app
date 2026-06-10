import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sefer/core/theme/app_colors.dart';
import 'package:sefer/features/device/presentation/device_page.dart';
import 'package:sefer/features/library/presentation/library_page.dart';
import 'package:sefer/features/settings/presentation/settings_page.dart';

/// Height of the floating pill nav bar including its bottom margin.
const double kNavBarHeight = 72.0;

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _selectedIndex = 0;

  /// 0.0 = at top (more transparent), 1.0 = scrolled down (fully opaque).
  final _scrollProgress = ValueNotifier<double>(0.0);

  // Track per-tab scroll offset so switching tabs restores the correct opacity.
  final _tabScrollOffsets = [0.0, 0.0, 0.0];

  void _onScroll(ScrollNotification n) {
    final offset = n.metrics.pixels.clamp(0.0, 80.0);
    _tabScrollOffsets[_selectedIndex] = offset;
    _scrollProgress.value = offset / 80.0;
  }

  /// When non-null, DevicePage enters selection mode pre-filtered to this
  /// collection so the user can pick PDFs to add to it.
  String? _deviceTargetCollectionId;

  final _deviceKey = GlobalKey<DevicePageState>();

  static const _tabs = [
    _TabItem(label: 'Library', icon: Icons.collections_bookmark_outlined),
    _TabItem(label: 'Device', icon: Icons.phone_android_outlined),
    _TabItem(label: 'Settings', icon: Icons.settings_outlined),
  ];

  @override
  void dispose() {
    _scrollProgress.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    if (index != 1) {
      _deviceKey.currentState?.clearSelection();
      setState(() {
        _selectedIndex = index;
        _deviceTargetCollectionId = null;
      });
    } else {
      setState(() => _selectedIndex = index);
    }
    _scrollProgress.value = _tabScrollOffsets[index] / 80.0;
  }

  /// Navigate to Device tab with a target collection for bulk-add.
  void navigateToDeviceForCollection(String collectionId) {
    _deviceKey.currentState?.clearSelection();
    setState(() {
      _selectedIndex = 1;
      _deviceTargetCollectionId = collectionId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return PopScope(
      // Back on any non-Library tab → go to Library.
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectedIndex != 0) {
          _onTabChanged(0);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  _onScroll(n);
                  return false;
                },
                child: IndexedStack(
                index: _selectedIndex,
                children: [
                  LibraryPage(
                    bottomPadding: kNavBarHeight + bottomPadding,
                    onAddToCollection: navigateToDeviceForCollection,
                  ),
                  DevicePage(
                    key: _deviceKey,
                    bottomPadding: kNavBarHeight + bottomPadding,
                    targetCollectionId: _deviceTargetCollectionId,
                    onDone: () => _onTabChanged(0),
                  ),
                  SettingsPage(
                    bottomPadding: kNavBarHeight + bottomPadding,
                  ),
                ],
              ),
              ),
            ),
            // Floating pill nav bar above system nav.
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomPadding + 12,
              child: _FloatingNavBar(
                selectedIndex: _selectedIndex,
                tabs: _tabs,
                onTabChanged: _onTabChanged,
                scrollProgress: _scrollProgress,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Floating pill nav bar
// ---------------------------------------------------------------------------

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.selectedIndex,
    required this.tabs,
    required this.onTabChanged,
    required this.scrollProgress,
  });

  final int selectedIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTabChanged;
  final ValueNotifier<double> scrollProgress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ValueListenableBuilder<double>(
      valueListenable: scrollProgress,
      builder: (context, progress, child) {
        // At top (progress=0): alpha 0.55. Scrolled (progress=1): alpha 0.94.
        final alpha = 0.55 + 0.39 * progress;
        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: alpha)
                : Colors.white.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.07),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12 * progress),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++)
            Expanded(
              child: _NavItem(
                tab: tabs[i],
                selected: i == selectedIndex,
                onTap: () => onTabChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _TabItem tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactive =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 30,
            decoration: BoxDecoration(
              color: selected ? AppColors.brand : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              tab.icon,
              size: 19,
              color: selected ? AppColors.onBrand : inactive,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            tab.label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: selected ? AppColors.brand : inactive,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Greeting header — exported for child pages
// ---------------------------------------------------------------------------

/// Large Fraunces title with optional subtitle and trailing action widget.
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final primary =
        isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: GoogleFonts.dmSans(fontSize: 14, color: secondary),
                  ),
                Text(
                  title,
                  style: GoogleFonts.fraunces(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: primary,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label — exported for child pages
// ---------------------------------------------------------------------------

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.darkSecondaryText
              : AppColors.lightSecondaryText,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared search bar widget
// ---------------------------------------------------------------------------

class PageSearchBar extends StatelessWidget {
  const PageSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search…',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final hint =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.search, size: 18, color: hint),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: GoogleFonts.dmSans(fontSize: 15),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: GoogleFonts.dmSans(fontSize: 15, color: hint),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.close, size: 16, color: hint),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  const _TabItem({required this.label, required this.icon});
}

/// Returns a time-of-day greeting.
String get timeGreeting {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}
