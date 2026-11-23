import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';

// The widgets these screens are built from moved to the shared layer, so onboarding can use
// the same ones (#62) — one feature may not import another. Re-exported rather than repointed
// in every caller: an auth screen asking for "the auth form widgets" is still the right
// sentence, and the move is not something those screens need to know about.
export 'package:cheapest_go_mobile/shared/components/auth_form_widgets.dart';

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

List<PasswordRule> passwordRules(AppLocalizations t) => [
  PasswordRule(t.auth_atLeast8, (p) => p.length >= 8),
  PasswordRule(t.auth_atLeastOneUppercase, (p) => RegExp(r'[A-Z]').hasMatch(p)),
  PasswordRule(t.auth_atLeastOneNumber, (p) => RegExp(r'\d').hasMatch(p)),
];

/// The password a sign-in asks for: present, and long enough. V2's login checks only these
/// two — the three rules above are for choosing one, not for typing one you already have.
/// Its message is a literal there too.
String? validateSignInPassword(AppLocalizations t, String? value) {
  final v = value ?? '';
  if (v.isEmpty) return t.auth_passwordRequired;
  if (v.length < 8) return t.auth_atLeast8;
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
                      color: rule.test(password) ? scheme.onSurface : scheme.onSurfaceVariant,
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
