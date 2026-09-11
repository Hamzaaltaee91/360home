// 404 Not Found Screen

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';

/// Fallback screen shown when a route cannot be resolved.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({Key? key, this.location}) : super(key: key);

  /// The location that failed to resolve, if available.
  final String? location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('خطأ')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 72,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'الصفحة غير موجودة',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (location != null) ...[
                const SizedBox(height: 8),
                Text(
                  location!,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go(RouteNames.splash),
                icon: const Icon(Icons.home_outlined),
                label: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
