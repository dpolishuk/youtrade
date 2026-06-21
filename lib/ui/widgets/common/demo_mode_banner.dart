import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/providers/connectivity_provider.dart';

class DemoModeBanner extends ConsumerWidget {
  const DemoModeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemoMode = ref.watch(isDemoModeProvider);

    if (!isDemoMode) return const SizedBox.shrink();

    return Material(
      color: Theme.of(context).colorScheme.error,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.offline_bolt,
                size: 16,
                color: Theme.of(context).colorScheme.onError,
              ),
              const SizedBox(width: 6),
              Text(
                'Demo / Offline mode',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onError,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
