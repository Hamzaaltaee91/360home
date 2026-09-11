import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable form text input with inline error validation.
///
/// Wraps a [TextFormField] with consistent styling, an optional label,
/// prefix/suffix icons, and inline error display. Designed to be used
/// inside a [Form] so that [validator] runs on [FormState.validate].
class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.initialValue,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.focusNode,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.borderRadius,
  });

  /// Controls the text being edited.
  final TextEditingController? controller;

  /// Optional label displayed above the field.
  final String? label;

  /// Placeholder text shown when the field is empty.
  final String? hintText;

  /// Supplementary text displayed below the field when there is no error.
  final String? helperText;

  /// Initial value when no [controller] is provided.
  final String? initialValue;

  /// The type of keyboard to display.
  final TextInputType? keyboardType;

  /// The action button on the keyboard.
  final TextInputAction? textInputAction;

  /// Whether to hide the text being edited.
  final bool obscureText;

  /// Whether the field is interactive.
  final bool enabled;

  /// Whether the field can be edited.
  final bool readOnly;

  /// Whether the field should focus itself on build.
  final bool autofocus;

  /// Maximum number of lines for the input.
  final int? maxLines;

  /// Minimum number of lines for the input.
  final int? minLines;

  /// Maximum number of characters allowed.
  final int? maxLength;

  /// Icon displayed before the input.
  final Widget? prefixIcon;

  /// Icon displayed after the input.
  final Widget? suffixIcon;

  /// Validator invoked on [FormState.validate].
  final String? Function(String?)? validator;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the field.
  final ValueChanged<String>? onFieldSubmitted;

  /// Called when the field is tapped.
  final VoidCallback? onTap;

  /// Optional focus node for the field.
  final FocusNode? focusNode;

  /// Optional input formatters.
  final List<TextInputFormatter>? inputFormatters;

  /// Text capitalization strategy.
  final TextCapitalization textCapitalization;

  /// When validation should run.
  final AutovalidateMode autovalidateMode;

  /// Optional border radius override.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = borderRadius ?? BorderRadius.circular(12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          autovalidateMode: autovalidateMode,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(borderRadius: radius),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: theme.colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
