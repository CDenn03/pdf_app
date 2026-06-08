import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pdf_app/core/providers.dart';
import 'package:pdf_app/core/theme/app_colors.dart';
import 'package:pdf_app/core/theme/reading_mode.dart';
import 'package:pdf_app/core/theme/scroll_direction.dart';
import 'package:pdf_app/features/home/presentation/home_shell.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key, this.bottomPadding = 0});

  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: GreetingHeader(subtitle: 'Preferences', title: 'Settings'),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('App theme'),
                const SizedBox(height: 4),
                _OptionsCard(
                  isDark: isDark,
                  divider: divider,
                  children: [
                    _OptionRow(
                      label: 'System default',
                      selected: settings.themeMode == ThemeMode.system,
                      onTap: () => notifier.setThemeMode(ThemeMode.system),
                    ),
                    Divider(height: 1, color: divider),
                    _OptionRow(
                      label: 'Light',
                      selected: settings.themeMode == ThemeMode.light,
                      onTap: () => notifier.setThemeMode(ThemeMode.light),
                    ),
                    Divider(height: 1, color: divider),
                    _OptionRow(
                      label: 'Dark',
                      selected: settings.themeMode == ThemeMode.dark,
                      onTap: () => notifier.setThemeMode(ThemeMode.dark),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionLabel('Reading mode'),
                const SizedBox(height: 4),
                _OptionsCard(
                  isDark: isDark,
                  divider: divider,
                  children: [
                    for (int i = 0; i < ReadingMode.values.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: divider),
                      _OptionRow(
                        label: ReadingMode.values[i].label,
                        selected: settings.readingMode == ReadingMode.values[i],
                        onTap: () =>
                            notifier.setReadingMode(ReadingMode.values[i]),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                const SectionLabel('Scroll direction'),
                const SizedBox(height: 4),
                _OptionsCard(
                  isDark: isDark,
                  divider: divider,
                  children: [
                    for (int i = 0; i < ScrollDirection.values.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: divider),
                      _OptionRow(
                        label: ScrollDirection.values[i].label,
                        selected:
                            settings.scrollDirection ==
                            ScrollDirection.values[i],
                        onTap: () => notifier
                            .setScrollDirection(ScrollDirection.values[i]),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: bottomPadding + 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionsCard extends StatelessWidget {
  const _OptionsCard({
    required this.isDark,
    required this.divider,
    required this.children,
  });

  final bool isDark;
  final Color divider;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: divider),
      ),
      child: Column(children: children),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary =
        isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: primary,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, size: 20, color: AppColors.brand),
          ],
        ),
      ),
    );
  }
}
