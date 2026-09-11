import 'package:flutter/material.dart';

/// A reusable button that supports loading and disabled states.
///
/// Wraps [ElevatedButton] and shows a [CircularProgressIndicator] in place of
/// the label while [isLoading] is `true`. The button is automatically disabled
/// while loading or when [onPressed] is `null`.
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expand = true,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.padding,
    this.style,
  });

  /// The text displayed on the button.
  final String label;

  /// Called when the button is tapped. When `null`, the button is disabled.
  final VoidCallback? onPressed;

  /// When `true`, a progress indicator replaces the label and taps are ignored.
  final bool isLoading;

  /// Optional leading icon shown before the label.
  final IconData? icon;

  /// Whether the button should stretch to fill its parent's width.
  final bool expand;

  /// Optional background color override.
  final Color? backgroundColor;

  /// Optional foreground (text/icon) color override.
  final Color? foregroundColor;

  /// Optional border radius override.
  final BorderRadius? borderRadius;

  /// Optional padding override.
  final EdgeInsetsGeometry? padding;

  /// Optional full style override. Merged on top of the derived style.
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveForeground =
        foregroundColor ?? theme.colorScheme.onPrimary;
    final effectiveBackground =
        backgroundColor ?? theme.colorScheme.primary;

    final effectiveStyle = ElevatedButton.styleFrom(
      backgroundColor: effectiveBackground,
      foregroundColor: effectiveForeground,
      disabledBackgroundColor: effectiveBackground.withValues(alpha: 0.5),
      disabledForegroundColor: effectiveForeground.withValues(alpha: 0.7),
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
    ).merge(style);

    final isDisabled = onPressed == null || isLoading;

    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveForeground),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );

    final button = ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: effectiveStyle,
      child: child,
    );

    if (!expand) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}
