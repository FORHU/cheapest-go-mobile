import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';

/// Where a failed OAuth round trip lands. See #45.
///
/// Google sign-in can fail the ways the web's can — an expired code, one already spent —
/// and without this screen that path ended nowhere. The copy is V2's, already mirrored in
/// all four languages.
class AuthCodeErrorView extends StatelessWidget {
  const AuthCodeErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.errors_auth_title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: EmptyState(
              icon: Icons.warning_amber_rounded,
              title: t.errors_auth_title,
              message: t.errors_auth_description,
              // Two ways on, as V2 has them: back to the form, or out of the flow.
              action: Column(
                children: [
                  SizedBox(
                    width: 240,
                    child: FilledButton(
                      onPressed: () => context.go('/login'),
                      child: Text(t.errors_auth_signInAgain),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: Text(t.errors_auth_goHome),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
