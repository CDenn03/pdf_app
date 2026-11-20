import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sefer/core/providers.dart';
import 'package:sefer/core/theme/app_spacing.dart';
import 'package:sefer/features/home/presentation/display_name_dialog.dart';

/// Time-of-day salutation used by the home greeting.
String timeGreeting([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// Home-only greeting: salutation plus the user's display name.
class GreetingHeader extends ConsumerWidget {
  const GreetingHeader({super.key, this.now});

  /// Injected in tests so the salutation is deterministic.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(appSettingsProvider.select((s) => s.displayName));
    return PageHeader(
      subtitle: timeGreeting(now),
      title: name,
      onTitleTap: () => editDisplayName(context, ref),
      titleTooltip: 'Change name',
      action: IconButton(
        icon: const Icon(Icons.edit_outlined),
        tooltip: 'Change name',
        onPressed: () => editDisplayName(context, ref),
      ),
    );
  }
}

/// Page title used on Device and Settings.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.onTitleTap,
    this.titleTooltip,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final VoidCallback? onTitleTap;
  final String? titleTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleText = Text(
      title,
      style: theme.textTheme.displayLarge?.copyWith(height: 1.1),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null)
                  Text(subtitle!, style: theme.textTheme.bodyMedium),
                if (onTitleTap == null)
                  titleText
                else
                  Tooltip(
                    message: titleTooltip ?? title,
                    child: GestureDetector(onTap: onTitleTap, child: titleText),
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
