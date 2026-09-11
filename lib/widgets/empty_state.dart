import 'package:flutter/material.dart';

/// A standardized empty state used across the app.
///
/// Displays a centered [Icon] with a [title] and optional [message] below
/// it. An optional [action] widget (typically a button) can be provided to
/// guide the user toward the next step. When [fullScreen] is `true` the
/// widget expands to fill the available space, making it suitable for
/// whole-screen empty states. Otherwise it sizes itself to its content,
/// which is useful when embedded inside cards or list items.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.iconSize = 64,
    this.action,
    this.fullScreen = false,
    this.color,
  });

  /// Short headline describing the empty state.
  final String title;

  /// Optional supporting message displayed beneath the [title].
  final String? message;

  /// Icon displayed above the [title].
  final IconData icon;

  /// Size of the [icon].
  final double iconSize;

  /// Optional action widget, typically a button, shown below the message.
  final Widget? action;

  /// Whether the widget should expand to fill the available space.
  final bool fullScreen;

  /// Optional color override for the [icon].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = color ?? theme.colorScheme.onSurfaceVariant;

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
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: 24),
          action!,
        ],
      ],
    );

    if (fullScreen) {
      return Center(child: content);
    }

    return content;
  }
}
