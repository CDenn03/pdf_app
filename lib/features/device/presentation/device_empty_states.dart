import 'package:flutter/material.dart';

import 'package:sefer/core/theme/app_colors.dart';
import 'package:sefer/core/theme/app_spacing.dart';

class DeviceScanningState extends StatelessWidget {
  const DeviceScanningState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator.adaptive(),
          const SizedBox(height: AppSpacing.lg),
          Text('Scanning device…', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class DeviceEmptyState extends StatelessWidget {
  const DeviceEmptyState({
    super.key,
    required this.permissionDenied,
    required this.onScan,
  });

  final bool permissionDenied;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.phone_android_outlined,
              size: 52,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              permissionDenied
                  ? 'Storage permission required'
                  : 'No PDFs found on device',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              permissionDenied
                  ? 'Allow storage access so the app can find your PDFs.'
                  : 'No PDF files were found in common storage locations.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onScan,
              icon: Icon(
                permissionDenied
                    ? Icons.lock_open_outlined
                    : Icons.refresh_outlined,
              ),
              label: Text(permissionDenied ? 'Grant Permission' : 'Scan Again'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: AppColors.onBrand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
