import 'package:flutter/material.dart';

/// A standardized progress loader used across the app.
///
/// Displays a centered [CircularProgressIndicator] with an optional
/// [message] below it. When [fullScreen] is `true` the widget expands to
/// fill the available space, making it suitable for whole-screen loading
/// states. Otherwise it sizes itself to its content, which is useful when
/// embedded inside cards or list items.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 36,
    this.strokeWidth = 4,
    this.fullScreen = false,
    this.color,
  });

  /// Optional message displayed beneath the indicator.
  final String? message;

  /// Diameter of the progress indicator.
  final double size;

  /// Thickness of the progress indicator stroke.
  final double strokeWidth;

  /// Whether the widget should expand to fill the available space.
  final bool fullScreen;

  /// Optional color override for the progress indicator.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = color ?? theme.colorScheme.primary;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
