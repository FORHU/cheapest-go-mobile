import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/features/auth/components/auth_form_widgets.dart';
import 'package:cheapest_go_mobile/features/auth/stores/auth_store.dart';

/// Setting a new password from an emailed link. See #45.
///
/// Mobile never had this screen, so a reset email opened in the app had nowhere to land. The
/// token arrives in the query string, exactly as the email writes it for the web.
class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({this.token = '', super.key});

  /// From `?token=`. Empty when the screen was opened without a link, which V2 answers by
  /// saying so rather than showing a form that could never save anything.
  final String token;

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => authStore.clearError());
    // The checklist redraws as the password changes.
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await authStore.confirmPasswordReset(
      widget.token,
      _passwordController.text,
    );
    if (ok && mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.auth_resetPassword)),
      body: ListenableBuilder(
        listenable: authStore,
        builder: (context, _) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _done
                  ? _buildDone(context)
                  : widget.token.isEmpty
                      ? _buildNoToken(context)
                      : _buildForm(context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final loading = authStore.isLoading;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            title: t.auth_setNewPassword,
            subtitle: t.auth_chooseStrong,
          ),
          const SizedBox(height: 24),
          if (authStore.errorMessage != null) ...[
            AuthErrorBanner(message: authStore.errorMessage!),
            const SizedBox(height: 16),
          ],
          AuthPasswordField(
            controller: _passwordController,
            label: t.auth_strongPassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            validator: (v) => validateNewPassword(t, v),
            enabled: !loading,
          ),
          const SizedBox(height: 8),
          PasswordRulesChecklist(password: _passwordController.text),
          const SizedBox(height: 16),
          AuthPasswordField(
            controller: _confirmController,
            label: t.auth_repeatPassword,
            autofillHints: const [AutofillHints.newPassword],
            // V2's wording and V2's order: empty before mismatched. Neither message exists
            // in the locale files because V2 holds both as literals in its own form.
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passwordController.text) return 'Passwords do not match';
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
            enabled: !loading,
          ),
          const SizedBox(height: 24),
          AuthSubmitButton(
            label: t.auth_resetPassword,
            isLoading: loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildDone(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: scheme.tertiaryContainer,
          child: Icon(
            Icons.check_rounded,
            size: 32,
            color: scheme.onTertiaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        AuthHeader(title: t.auth_passwordUpdated),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go('/login'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(t.auth_backToSignIn),
          ),
        ),
      ],
    );
  }

  Widget _buildNoToken(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeader(
          title: t.auth_resetYourPassword,
          subtitle: t.auth_noResetToken,
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => context.go('/forgot-password'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(t.auth_sendResetLink),
        ),
      ],
    );
  }
}
