import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cheapest_go_mobile/app/app.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/home/views/home_view.dart';
import 'package:cheapest_go_mobile/shared/auth/permissions.dart';
import 'package:cheapest_go_mobile/shared/auth/rbac.dart';
import 'package:cheapest_go_mobile/shared/auth/roles.dart';
import 'package:cheapest_go_mobile/shared/components/app_buttons.dart';
import 'package:cheapest_go_mobile/shared/components/glass_card.dart';
import 'package:cheapest_go_mobile/shared/errors/api_error.dart';
import 'package:cheapest_go_mobile/shared/errors/error_router.dart';
import 'package:cheapest_go_mobile/shared/errors/retry_policy.dart';

import 'test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('FAOS shared layer', () {
    test('retry policy matches next-template-v1 rules', () {
      expect(getRetryCount(ApiError('Net', category: ErrorCategory.network)), 3);
      expect(getRetryCount(ApiError('502', category: ErrorCategory.server, status: 502)), 2);
      expect(getRetryCount(ApiError('429', category: ErrorCategory.unknown, status: 429)), 1);
      expect(getRetryCount(ApiError('401', category: ErrorCategory.auth, status: 401)), 0);
    });

    test('error router maps categories deterministically', () {
      final authRouted = routeError(ApiError('Unauthorized', category: ErrorCategory.auth));
      expect(authRouted.action, ErrorRouteAction.logout);
      expect(authRouted.toast, 'Session expired');
    });

    test('RBAC engine enforces role permissions', () {
      expect(hasPermission(Role.admin, Permission.adminAccess), isTrue);
      expect(hasPermission(Role.user, Permission.adminAccess), isFalse);
      expect(hasPermission(Role.guest, Permission.savedManage), isTrue);
      expect(hasPermission(Role.guest, Permission.bookingsCreate), isFalse);
    });
  });

  group('v1 theme tokens', () {
    testWidgets('light theme registers the v1 blue and surface', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) {
              expect(context.colors.accent, const Color(0xFF2563EB));
              expect(context.colors.background, const Color(0xFFF9FAFB));
              return Scaffold(
                body: GlassCard(child: AppPrimaryButton(label: 'Book Now', onPressed: () {})),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Book Now'), findsOneWidget);
    });

    test('dark theme uses the v1 .dark values', () {
      final dark = AppTheme.dark;
      final colors = dark.extension<AppColors>()!;
      expect(dark.brightness, Brightness.dark);
      expect(colors.accent, const Color(0xFF3B82F6));
      expect(colors.background, const Color(0xFF0A0A0A));
      expect(colors.surface, const Color(0xFF171717));
      expect(dark.colorScheme.primary, colors.accent);
    });

    testWidgets('Home renders in dark mode without layout errors', (tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(MaterialApp(theme: AppTheme.dark, home: const Scaffold(body: HomeView())));
      await tester.pumpAndSettle();
      expect(find.textContaining('flying into'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('CheapestGoApp renders Home and the five-slot navigation', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(const CheapestGoApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('flying into'), findsOneWidget);
    for (final label in ['Home', 'Hotels', 'Golf', 'Trips']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('Flights'), findsNothing);
    expect(find.byIcon(Icons.public_rounded), findsOneWidget); // Globe dome
  });
}
