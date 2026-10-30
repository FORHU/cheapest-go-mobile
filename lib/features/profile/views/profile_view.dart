import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/shared/lib/env.dart';
import 'package:cheapest_go_mobile/shared/lib/map_tier.dart';
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
  });

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListenableBuilder(
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
              const SizedBox(height: 24),

              // 3. Hardware & Acceleration Status Section
              _buildSectionHeader('DEVICE HARDWARE & AVAILABILITY', theme),
              const SizedBox(height: 8),
              _buildDeviceStatusCard(context, theme),
              const SizedBox(height: 32),

              // 4. App Version & Build Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      'CheapestGo Mobile v${env.appVersion} (${env.appEnv.name})',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Universal Flight & Stay Engine • Pure Material 3',
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
      ),
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
          // 1. Display Currency
          ListTile(
            leading: _buildLeadingIcon(
              Icons.currency_exchange_rounded,
              const Color(0xFF10B981),
              theme,
            ),
            title: const Text(
              'Display Currency',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              'Real-time rates: ${uiSettingsStore.displayCurrency}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: DropdownButton<String>(
              value: uiSettingsStore.displayCurrency,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
              items: const ['USD', 'EUR', 'GBP', 'PHP', 'KRW', 'JPY', 'SGD', 'AED']
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        c,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) uiSettingsStore.setDisplayCurrency(v);
              },
            ),
          ),
          Divider(
            height: 1,
            indent: 64,
            endIndent: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),

          // 2. Theme Mode
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
          Divider(
            height: 1,
            indent: 64,
            endIndent: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),

          // 3. Map View Mode
          ListTile(
            leading: _buildLeadingIcon(
              Icons.public_rounded,
              const Color(0xFF0EA5E9),
              theme,
            ),
            title: const Text(
              'Map View Mode',
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
          Divider(
            height: 1,
            indent: 64,
            endIndent: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),

          // 4. Map Style Theme (Light vs Dark)
          ListTile(
            leading: _buildLeadingIcon(
              Icons.palette_outlined,
              const Color(0xFFEC4899),
              theme,
            ),
            title: const Text(
              'Map Theme Style',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              uiSettingsStore.mapThemeMode == MapThemeMode.light
                  ? 'Light aesthetic basemap'
                  : 'Dark slate night basemap',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: DropdownButton<MapThemeMode>(
              value: uiSettingsStore.mapThemeMode,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
              items: const [
                DropdownMenuItem(
                  value: MapThemeMode.light,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.light_mode, size: 16, color: Color(0xFFF59E0B)),
                      SizedBox(width: 8),
                      Text('Light Map'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: MapThemeMode.dark,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.dark_mode, size: 16, color: Color(0xFF6366F1)),
                      SizedBox(width: 8),
                      Text('Dark Map'),
                    ],
                  ),
                ),
              ],
              onChanged: (v) {
                if (v != null) uiSettingsStore.setMapThemeMode(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatusCard(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final caps = uiSettingsStore.deviceCapabilities;
    final ramMb = caps?.totalRamMb;
    final ramText = ramMb != null ? '${(ramMb / 1024).toStringAsFixed(1)} GB' : 'Standard Memory';
    final abiText = caps?.is64Bit == true ? '64-bit ABI' : '32-bit Legacy ABI';
    final is3dSupported = uiSettingsStore.is3dSupported;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildLeadingIcon(
          Icons.memory_rounded,
          is3dSupported ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          theme,
        ),
        title: const Text(
          'Hardware Capability',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                is3dSupported
                    ? '3D Globe Acceleration Supported'
                    : (uiSettingsStore.no3dReasonDescription ?? '3D Globe acceleration unavailable'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: is3dSupported
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Reported Hardware: $ramText • $abiText',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        trailing: Icon(
          is3dSupported ? Icons.check_circle : Icons.info_outline,
          color: is3dSupported ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
        ),
      ),
    );
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
