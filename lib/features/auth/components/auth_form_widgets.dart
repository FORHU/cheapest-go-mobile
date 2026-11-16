import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';

/// Shared Material 3 building blocks for the auth screens
/// (Login, Register, Forgot Password).

/// V2's own pattern, character for character, so the two products accept and reject the same
/// addresses. A stricter check here would turn somebody away that the web lets in.
final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Validates a required, well-formed email address. See #45.
///
/// Every message comes from the mirrored copy. These are the words someone screenshots when
/// they write to support, so "Enter a valid email" and "Enter a valid email address" are not
/// interchangeable — the first is V2's, and the second was mobile's own invention.
String? validateEmail(AppLocalizations t, String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return t.auth_emailRequired;
  if (!_emailPattern.hasMatch(v)) return t.auth_emailInvalid;
  return null;
}

/// V2's three password rules, shown live as somebody types and checked on submit.
///
/// api-v2 asks only for eight characters, so the upper case and the digit are the web's own
/// stricter line. Mobile holds it too: an account made on a phone and one made in a browser
/// should be the same account with the same password behind it.
class PasswordRule {
  const PasswordRule(this.label, this.test);
  final String label;
  final bool Function(String) test;
}

/// English literals, because V2's are: `PASSWORD_RULES` in `register-form.tsx` holds these
/// three labels as a constant rather than in its locale files, as it does for the sort
/// options and the booking tabs. Translating them only here would put the two products out
/// of step, which is the thing this port exists to prevent. They move when V2's move.
List<PasswordRule> passwordRules(AppLocalizations t) => [
      PasswordRule('At least 8 characters', (p) => p.length >= 8),
      PasswordRule('At least one uppercase letter', (p) => RegExp(r'[A-Z]').hasMatch(p)),
      PasswordRule('At least one number', (p) => RegExp(r'\d').hasMatch(p)),
    ];

/// The password a sign-in asks for: present, and long enough. V2's login checks only these
/// two — the three rules above are for choosing one, not for typing one you already have.
/// Its message is a literal there too.
String? validateSignInPassword(AppLocalizations t, String? value) {
  final v = value ?? '';
  if (v.isEmpty) return t.auth_passwordRequired;
  if (v.length < 8) return 'Password must be at least 8 characters';
  return null;
}

/// A new password, against all three rules.
String? validateNewPassword(AppLocalizations t, String? value) {
  final v = value ?? '';
  if (v.isEmpty) return t.auth_passwordRequired;
  if (!passwordRules(t).every((r) => r.test(v))) return t.auth_passwordWeak;
  return null;
}

/// The three rules, ticking off as they are met. See #45.
///
/// V2 shows these live under the password field on both register and reset, which is the
/// point: being told afterwards that a password "does not meet requirements" is no help
/// when the requirements were never stated.
class PasswordRulesChecklist extends StatelessWidget {
  const PasswordRulesChecklist({required this.password, super.key});

  final String password;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rule in passwordRules(t))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  rule.test(password) ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 15,
                  color: rule.test(password) ? scheme.primary : scheme.outlineVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rule.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: rule.test(password)
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A required field, named by its own label.
String? Function(String?) requiredField(String message) {
  return (value) => (value == null || value.trim().isEmpty) ? message : null;
}

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
    this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.onFieldSubmitted,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
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
        prefixIcon: icon != null ? Icon(icon) : null,
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

