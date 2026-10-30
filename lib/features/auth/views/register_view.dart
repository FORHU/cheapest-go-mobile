import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/features/auth/components/auth_form_widgets.dart';
import 'package:cheapest_go_mobile/features/auth/contracts/auth_contract.dart';
import 'package:cheapest_go_mobile/features/auth/stores/auth_store.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  static const int _minPasswordLength = 8;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => authStore.clearError());
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a password';
    if (v.length < _minPasswordLength) {
      return 'Use at least $_minPasswordLength characters';
    }
    return null;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
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
                      const AuthHeader(title: 'Join CheapestGo'),
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
                              label: 'First Name',
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.givenName],
                              validator: requiredField('first name'),
                              enabled: !loading,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AuthTextField(
                              controller: _lastNameController,
                              label: 'Last Name',
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.familyName],
                              validator: requiredField('last name'),
                              enabled: !loading,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        validator: validateEmail,
                        enabled: !loading,
                      ),
                      const SizedBox(height: 16),
                      AuthPasswordField(
                        controller: _passwordController,
                        label: 'Password',
                        helperText: 'Minimum $_minPasswordLength characters',
                        autofillHints: const [AutofillHints.newPassword],
                        validator: _validatePassword,
                        onFieldSubmitted: (_) => _submit(),
                        enabled: !loading,
                      ),
                      const SizedBox(height: 24),
                      AuthSubmitButton(
                        label: 'Create Account',
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
