import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cheapest_go_mobile/shared/lib/env.dart';
import 'package:cheapest_go_mobile/features/auth/components/auth_form_widgets.dart';
import 'package:cheapest_go_mobile/features/auth/stores/auth_store.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => authStore.clearError());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await authStore.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (ok && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In to CheapestGo')),
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
                      const AuthHeader(
                        title: 'Welcome back',
                        subtitle:
                            'Sign in to manage your flight and hotel bookings.',
                      ),
                      const SizedBox(height: 24),
                      if (authStore.errorMessage != null) ...[
                        AuthErrorBanner(message: authStore.errorMessage!),
                        const SizedBox(height: 16),
                      ],
                      if (authStore.mock) ...[
                        _DemoAccountCard(
                          enabled: !loading,
                          onUse: () {
                            _emailController.text = kDemoUser.email;
                            _passwordController.text = kDemoPassword;
                            _submit();
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Above the divider, as V2's login has it: the quickest way in comes
                      // first, and the form is the alternative. Absent entirely when the
                      // build has no client id — an offer that cannot work is worse than
                      // none. See #45.
                      if (env.googleServerClientId.isNotEmpty) ...[
                        _GoogleButton(
                          enabled: !loading,
                          onPressed: () async {
                            final ok = await authStore.signInWithGoogle();
                            if (ok && context.mounted) context.go('/');
                          },
                        ),
                        const SizedBox(height: 16),
                        const _OrDivider(),
                        const SizedBox(height: 16),
                      ],
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
                        validator: requiredField('password'),
                        onFieldSubmitted: (_) => _submit(),
                        enabled: !loading,
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: loading
                              ? null
                              : () => context.push('/forgot-password'),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AuthSubmitButton(
                        label: 'Sign In',
                        isLoading: loading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 16),
                      // Wrap, not Row: the prompt and the button together overflow a handset
                      // at a larger text scale, and the translations are longer than the
                      // English. Wrapping onto a second line costs nothing and never clips.
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed:
                                loading ? null : () => context.push('/register'),
                            child: const Text('Create account'),
                          ),
                        ],
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

/// Test-build helper: shows the default account and signs in with it.
class _DemoAccountCard extends StatelessWidget {
  const _DemoAccountCard({required this.enabled, required this.onUse});

  final bool enabled;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.person_pin_rounded, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Demo account', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer)),
                Text(
                  '${kDemoUser.email}\nPassword: $kDemoPassword',
                  style: TextStyle(fontSize: 12, color: scheme.onPrimaryContainer),
                ),
              ],
            ),
          ),
          TextButton(onPressed: enabled ? onUse : null, child: const Text('Use')),
        ],
      ),
    );
  }
}

/// "Sign in with Google", as V2 draws it: a plain bordered button with the mark, not the
/// brand blue — the form's own button is the one that should carry the weight.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.dividerColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google's mark is a trademark and not ours to redraw; its four colours in a
            // simple glyph is the closest honest thing without bundling their asset.
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: const Text(
                'G',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4285F4),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Sign in with Google',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// The word "or" on a rule, between the two ways in.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Divider(color: theme.dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: theme.textTheme.bodySmall),
        ),
        Expanded(child: Divider(color: theme.dividerColor)),
      ],
    );
  }
}
