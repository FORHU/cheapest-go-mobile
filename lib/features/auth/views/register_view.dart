import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/features/auth/components/auth_form_widgets.dart';
import 'package:cheapest_go_mobile/features/auth/contracts/auth_contract.dart';
import 'package:cheapest_go_mobile/features/auth/stores/auth_store.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => authStore.clearError());
    // The password checklist redraws as the password changes.
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await authStore.register(
      RegisterInput(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      ),
    );
    if (ok && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.auth_createAccount)),
      body: ListenableBuilder(
        listenable: authStore,
        builder: (context, _) {
          final loading = authStore.isLoading;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthHeader(
                        title: t.auth_createYourAccount,
                        subtitle: t.auth_registerSubtitle,
                      ),
                      const SizedBox(height: 20),
                      if (authStore.errorMessage != null) ...[
                        AuthErrorBanner(message: authStore.errorMessage!),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AuthTextField(
                              controller: _firstNameController,
                              label: t.auth_firstName,
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.givenName],
                              validator: requiredField(t.auth_firstNameRequired),
                              enabled: !loading,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AuthTextField(
                              controller: _lastNameController,
                              label: t.auth_lastName,
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.familyName],
                              // V2 asks only for a first name; a last name is optional
                              // there, which is why no required message exists for it.
                              validator: null,
                              enabled: !loading,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        controller: _emailController,
                        label: t.auth_signIn_emailLabel,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        validator: (v) => validateEmail(t, v),
                        enabled: !loading,
                      ),
                      const SizedBox(height: 16),
                      AuthPasswordField(
                        controller: _passwordController,
                        label: t.auth_strongPassword,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (v) => validateNewPassword(t, v),
                        onFieldSubmitted: (_) => _submit(),
                        enabled: !loading,
                      ),
                      const SizedBox(height: 8),
                      // The rules, live, as V2 shows them — instead of a helper line that
                      // named only one of the three.
                      PasswordRulesChecklist(password: _passwordController.text),
                      const SizedBox(height: 24),
                      AuthSubmitButton(
                        label: t.auth_createAccount,
                        isLoading: loading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
