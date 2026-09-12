import 'package:flutter/material.dart';

/// A standardized error view used across the app.
///
/// Displays a centered [Icon] with a [message] and an optional retry
/// [action]. When [fullScreen] is `true` the widget expands to fill the
/// available space, making it suitable for whole-screen error states.
/// Otherwise it sizes itself to its content, which is useful when embedded
/// inside cards or list items.
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    this.message,
    this.icon = Icons.error_outline,
    this.iconSize = 64,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.fullScreen = false,
    this.color,
  });

  /// Optional message describing the error. A generic message is shown when
  /// this is `null`.
  final String? message;

  /// Icon displayed above the [message].
  final IconData icon;

  /// Size of the [icon].
  final double iconSize;

  /// Called when the retry button is tapped. When `null`, no button is shown.
  final VoidCallback? onRetry;

  /// Label for the retry button.
  final String retryLabel;

  /// Whether the widget should expand to fill the available space.
  final bool fullScreen;

  /// Optional color override for the [icon].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = color ?? theme.colorScheme.error;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: iconColor,
        ),
        const SizedBox(height: 16),
        Text(
          message ?? 'Something went wrong.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(retryLabel),
          ),
        ],
      ],
    );

    if (fullScreen) {
      return Center(child: content);
    }

    return content;
  }
}
