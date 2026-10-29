import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/shared/lib/env.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({
    super.key,
    required this.isAuthenticated,
    this.userName,
    this.userEmail,
    this.onSignInTap,
    this.onRegisterTap,
    this.onSignOutTap,
  });

  final bool isAuthenticated;
  final String? userName;
  final String? userEmail;
  final VoidCallback? onSignInTap;
  final VoidCallback? onRegisterTap;
  final VoidCallback? onSignOutTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: uiSettingsStore,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: isAuthenticated
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                child: Icon(Icons.person),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName?.isNotEmpty == true
                                          ? userName!
                                          : 'CheapestGo Member',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (userEmail != null)
                                      Text(
                                        userEmail!,
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: onSignOutTap,
                            icon: const Icon(Icons.logout),
                            label: const Text('Sign Out'),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Sign in to sync bookings & manage your trips',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: onSignInTap,
                            child: const Text('Sign In'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: onRegisterTap,
                            child: const Text('Create Account'),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Display Preferences',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.currency_exchange),
                    title: const Text('Display Currency'),
                    subtitle: const Text('Chargeable Stripe currencies'),
                    trailing: DropdownButton<String>(
                      value: uiSettingsStore.displayCurrency,
                      underline: const SizedBox.shrink(),
                      items: const ['USD', 'PHP', 'KRW']
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) uiSettingsStore.setDisplayCurrency(v);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.brightness_6_outlined),
                    title: const Text('Theme'),
                    trailing: DropdownButton<ThemeMode>(
                      value: uiSettingsStore.themeMode,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('System'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dark'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) uiSettingsStore.setThemeMode(v);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'CheapestGo Mobile v${env.appVersion} (${env.appEnv.name})',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }
}

