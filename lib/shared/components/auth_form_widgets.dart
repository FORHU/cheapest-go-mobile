import 'package:flutter/material.dart';

/// Material 3 form building blocks, shared across features.
///
/// They began life in `features/auth/` and moved here when onboarding needed the same heading,
/// the same field and the same button (#62): `features/A` may not import `features/B`, and two
/// copies of a text field is how two screens start to look like different products.
///
/// Only the widgets live here. The password rules and the email pattern stayed with auth,
/// because they are V2's sign-in rules and not a thing any screen should reach for.

/// Page heading + supporting text, styled with the M3 type scale.
class AuthHeader extends StatelessWidget {
  const AuthHeader({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Error banner using the M3 `errorContainer` tonal role.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.errorContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: scheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Outlined M3 text field with consistent shape and prefix icon.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.controller,
    required this.label,
    this.hintText,
    this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.onFieldSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    super.key,
  });

  final TextEditingController controller;
  final String label;

  /// An example of what belongs here, shown while the field is empty. Used where the shape
  /// of the answer matters and the label cannot carry it — a date format, a country code.
  final String? hintText;
  final IconData? icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;

  /// Typing is refused and [onTap] is what fills the field instead — a calendar, a picker.
  /// The keyboard never opens, which is the point: a field whose answer has to be one of a
  /// known set should not accept anything else in the first place.
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: readOnly,
      onTap: enabled ? onTap : null,
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Password field with a show/hide toggle.
class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    required this.controller,
    this.label = 'Password',
    this.helperText,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.autofillHints = const [AutofillHints.password],
    this.onFieldSubmitted,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _obscured,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        prefixIcon: const Icon(Icons.lock_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          tooltip: _obscured ? 'Show password' : 'Hide password',
          icon: Icon(
            _obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ),
    );
  }
}

/// Full-width M3 filled button with an inline loading indicator.
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: scheme.onSurfaceVariant,
              ),
            )
          : Text(label),
    );
  }
}

