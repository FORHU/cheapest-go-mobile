import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/features/auth/components/auth_form_widgets.dart';
import 'package:cheapest_go_mobile/features/auth/stores/auth_store.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => authStore.clearError());
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await authStore.resetPassword(_emailController.text.trim());
    if (ok && mounted) {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: ListenableBuilder(
        listenable: authStore,
        builder: (context, _) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _sent ? _buildSent(context) : _buildForm(context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSent(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: scheme.tertiaryContainer,
          child: Icon(
            Icons.mark_email_read_outlined,
            size: 32,
            color: scheme.onTertiaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        const AuthHeader(
          title: 'Check your email',
          subtitle:
              'We sent password recovery instructions to your email address.',
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => Navigator.of(context).maybePop(),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Back to Sign In'),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final loading = authStore.isLoading;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: 'Forgot your password?',
            subtitle:
                'Enter your account email and we will send you a reset link.',
          ),
          const SizedBox(height: 24),
          if (authStore.errorMessage != null) ...[
            AuthErrorBanner(message: authStore.errorMessage!),
            const SizedBox(height: 16),
          ],
          AuthTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            validator: validateEmail,
            onFieldSubmitted: (_) => _submit(),
            enabled: !loading,
          ),
          const SizedBox(height: 20),
          AuthSubmitButton(
            label: 'Send Reset Link',
            isLoading: loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
