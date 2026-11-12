import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/shared/lib/demo.dart';
import 'package:cheapest_go_mobile/shared/lib/env.dart';
import 'package:cheapest_go_mobile/shared/lib/map_tier.dart';
import 'package:cheapest_go_mobile/shared/stores/bookings_store.dart';
import 'package:cheapest_go_mobile/shared/stores/saved_store.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';

/// Pure Material 3 Profile & Account View
///
/// Implements standard Material 3 surfaces, tonal containers, typography,
/// and display preferences for currency, themes, and 2D/3D map tiers.
class ProfileView extends StatelessWidget {
  const ProfileView({
    super.key,
    required this.isAuthenticated,
    this.userName,
    this.userEmail,
    this.onSignInTap,
    this.onRegisterTap,
    this.onSignOutTap,
    this.embedded = false,
  });

  /// True when this is shown inside the nav bar's settings sheet rather than as a screen.
  ///
  /// V2 opens that sheet onto its account surface rather than linking to a settings page, and
  /// the sheet brings its own grab handle, title and close button. Rendering the Scaffold and
  /// AppBar as well would put two headers on top of each other.
  ///
  /// A flag rather than a split widget on purpose: #46 replaces this screen with V2's account
  /// layout, and moving 450 lines now only to move them again would be churn for its own sake.
  final bool embedded;

  final bool isAuthenticated;
  final String? userName;
  final String? userEmail;
  final VoidCallback? onSignInTap;
  final VoidCallback? onRegisterTap;
  final VoidCallback? onSignOutTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (embedded) return _body(context, theme);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Profile & Account',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
        // A tab in the bottom bar: show back only when opened on top of a page.
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
      ),
      body: _body(context, theme),
    );
  }

  Widget _body(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return ListenableBuilder(
        listenable: uiSettingsStore,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // 1. Account / Authentication Hero Card
              _buildAccountCard(context, theme),
              const SizedBox(height: 24),

              // 2. Preferences Section
              _buildSectionHeader('PREFERENCES', theme),
              const SizedBox(height: 8),
              _buildPreferencesCard(context, theme),
              const SizedBox(height: 32),

              if (kDemoTools) ...[
                _buildSectionHeader('DEMO', theme),
                const SizedBox(height: 8),
                _buildDemoCard(context, theme),
                const SizedBox(height: 32),
              ],

              // 3. App Version & Build Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      'CheapestGo Mobile v${env.appVersion}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stays and golf near your arrival airport',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: isAuthenticated
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primaryContainer,
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.person,
                            size: 32,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    userName?.isNotEmpty == true
                                        ? userName!
                                        : 'CheapestGo Traveler',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'MEMBER',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userEmail ?? 'member@cheapestgo.com',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onSignOutTap,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Log Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        backgroundColor: Colors.transparent,
                        side: BorderSide(
                          color: colorScheme.error.withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary.withValues(alpha: 0.12),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.flight_takeoff,
                            color: colorScheme.primary,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Traveler Account',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Sign in to lock rates & manage bookings',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: onSignInTap,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Sign In'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onRegisterTap,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Create Account'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPreferencesCard(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          // 1. Theme Mode
          ListTile(
            leading: _buildLeadingIcon(
              Icons.brightness_6_rounded,
              const Color(0xFF6366F1),
              theme,
            ),
            title: const Text(
              'App Theme',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              '${uiSettingsStore.themeMode.name.toUpperCase()} mode',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: DropdownButton<ThemeMode>(
              value: uiSettingsStore.themeMode,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
              // Two options, as V2 offers. "System" is deliberately absent: V2 never reads the
              // browser's preference, so mobile does not read the handset's. See
              // UiSettingsStore.setThemeMode.
              items: const [
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
          Divider(
            height: 1,
            indent: 64,
            endIndent: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),

          // 2. Map View Mode (prices are always in pesos, so there is no currency setting)
          ListTile(
            leading: _buildLeadingIcon(
              Icons.public_rounded,
              const Color(0xFF0EA5E9),
              theme,
            ),
            title: const Text(
              'Map',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              uiSettingsStore.is3dSupported
                  ? (uiSettingsStore.mapTier == MapTier.standard
                      ? '3D Standard Globe'
                      : '2D Lite Map')
                  : (uiSettingsStore.no3dReasonDescription ?? '3D Globe unsupported on device'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: !uiSettingsStore.is3dSupported
                    ? const Color(0xFFF59E0B)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: DropdownButton<MapTier>(
              value: uiSettingsStore.mapTier,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
              items: [
                const DropdownMenuItem(
                  value: MapTier.lite,
                  child: Text('2D Lite'),
                ),
                DropdownMenuItem(
                  value: MapTier.standard,
                  enabled: uiSettingsStore.is3dSupported,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '3D Globe',
                        style: TextStyle(
                          color: uiSettingsStore.is3dSupported
                              ? null
                              : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      if (!uiSettingsStore.is3dSupported)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              onChanged: (v) {
                if (v != null) uiSettingsStore.setMapTier(v);
              },
            ),
          ),
        ],
      ),
    );
  }



  /// Presentation tools; only in debug builds and `DEMO=true` builds.
  Widget _buildDemoCard(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        leading: _buildLeadingIcon(Icons.restart_alt_rounded, const Color(0xFFF59E0B), theme),
        title: const Text('Reset demo data', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          'Removes test bookings and saved stays; keeps the sample past trips.',
          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        onTap: () => _resetDemoData(context),
      ),
    );
  }

  Future<void> _resetDemoData(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset demo data?'),
        content: const Text('Bookings made on this phone and saved stays will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok != true) return;
    await Future.wait([bookingsStore.resetToDemo(), savedStaysStore.clear()]);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo data reset')));
    }
  }

  Widget _buildLeadingIcon(IconData icon, Color color, ThemeData theme) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
