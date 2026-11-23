import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cheapest_go_mobile/app/app.dart';
import 'package:cheapest_go_mobile/app/startup.dart';
import 'package:cheapest_go_mobile/shared/components/language_picker.dart';
import 'package:cheapest_go_mobile/app/router/v2_bottom_nav.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/home/views/home_view.dart';
import 'package:cheapest_go_mobile/features/auth/components/auth_form_widgets.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
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

    test('invalid sign-in errors and password rules use the selected language', () async {
      final t = await AppLocalizations.delegate.load(const Locale('ko'));
      final invalidCredentials = routeError(
        ApiError('Invalid credentials', category: ErrorCategory.auth, code: 'INVALID_CREDENTIALS'),
        t: t,
      );

      expect(invalidCredentials.toast, '입력하신 정보와 일치하는 계정을 찾을 수 없습니다');

      // #75 asked for the login error, and a wrong password is not the only one a sign-in
      // screen shows. These three were left in English when only the credentials branch took
      // an injected message, and a tester with no signal meets the network one first.
      expect(
        routeError(ApiError('x', category: ErrorCategory.auth), t: t).toast,
        '로그인이 만료되었습니다. 다시 로그인해 주세요.',
      );
      expect(
        routeError(ApiError('x', category: ErrorCategory.forbidden), t: t).toast,
        '이 항목에 접근할 권한이 없습니다.',
      );
      expect(
        routeError(ApiError('x', category: ErrorCategory.network), t: t).toast,
        '연결 상태를 확인한 뒤 다시 시도해 주세요.',
      );
      expect(passwordRules(t).map((rule) => rule.label), ['8자 이상', '대문자를 하나 이상 포함', '숫자를 하나 이상 포함']);
    });

    test('what a traveller is shown is never the exception itself', () {
      // The screen that prompted this showed, in a red banner on the payment step:
      //   ApiError(ErrorCategory.unknown, status: 200): Hotel booking is switched off…
      // Three checkout screens printed error.toString(), which for an ApiError is a
      // diagnostic. A refusal the server worded for a person must reach them as that wording.
      final off = ApiError('Hotel booking is switched off in this environment.', status: 200);
      expect(errorMessage(off), 'Hotel booking is switched off in this environment.');
      expect(errorMessage(off), isNot(contains('ApiError')));
      expect(errorMessage(off), isNot(contains('status:')));

      // A category routeError has its own words for keeps them.
      expect(errorMessage(ApiError('Unauthorized', category: ErrorCategory.auth)), 'Session expired');

      // And anything that is not an ApiError is already a sentence: a declined card arrives
      // as Stripe's own, and routing it would replace it with "Unexpected error occurred".
      expect(errorMessage(Exception('Your card was declined.')), 'Your card was declined.');
    });
    test('RBAC engine enforces role permissions', () {
      expect(hasPermission(Role.admin, Permission.adminAccess), isTrue);
      expect(hasPermission(Role.user, Permission.adminAccess), isFalse);
      expect(hasPermission(Role.guest, Permission.savedManage), isTrue);
      expect(hasPermission(Role.guest, Permission.bookingsCreate), isFalse);
    });
  });

  group('v2-paired theme tokens', () {
    testWidgets('light theme registers the v2 blue and alabaster ground', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) {
              expect(context.colors.accent, const Color(0xFF2563EB));
              expect(context.colors.background, const Color(0xFFF8FAFC));
              return Scaffold(
                body: GlassCard(
                  child: AppPrimaryButton(label: 'Book Now', onPressed: () {}),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Book Now'), findsOneWidget);
    });

    test('dark theme uses the v2 obsidian + slate values', () {
      final dark = AppTheme.dark;
      final colors = dark.extension<AppColors>()!;
      expect(dark.brightness, Brightness.dark);
      expect(colors.accent, const Color(0xFF3B82F6));
      expect(colors.background, const Color(0xFF020617));
      expect(colors.surface, const Color(0xFF0F172A));
      expect(dark.colorScheme.primary, colors.accent);
    });

    testWidgets('Home renders in dark mode without layout errors', (tester) async {
      usePhoneViewport(tester);
      await pumpScreen(tester, const HomeView(), theme: AppTheme.dark);
      await tester.pumpAndSettle();
      expect(find.text('One search.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('CheapestGoApp opens on the sign-in wall, not on Home', (tester) async {
    // What a fresh install does since #62: there is no signed-out browsing, so the first
    // screen is the way in rather than the app. ADR-0005 says why, and says the web is not
    // expected to follow. This used to assert the opposite — if it is failing, read the ADR
    // before deciding which of the two is the bug.
    usePhoneViewport(tester);
    await tester.pumpWidget(const CheapestGoApp());
    await tester.pump();

    // The brand first, for as long as starting takes. Every route is held here until then,
    // the sign-in form included: a session being restored reads as signed out, and the form
    // is the wrong answer to "not back yet".
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('다시 오신 것을 환영합니다'), findsNothing);

    appStartup.markReady();
    await tester.pumpAndSettle();

    // Korean, not English: AirangGo opens in its market's language (UiSettingsStore._language).
    // If this fails in English, the default was changed back — decide which is intended before
    // editing the string.
    expect(find.text('다시 오신 것을 환영합니다'), findsOneWidget);
    expect(find.text('One search.'), findsNothing, reason: 'Home is behind the gate');
    expect(find.byType(V2BottomNav), findsNothing, reason: 'no bar before there is an account');

    // The way out of a language you cannot read. This screen is the only one a signed-out
    // visitor has, so without the control here they are stuck on it.
    expect(find.byType(LanguageAction), findsOneWidget);
  });

  testWidgets('inside the app, V2\'s three-slot bar', (tester) async {
    // The gate is off here: this is about the bar, not about who may see it.
    await pumpApp(tester);

    expect(find.text('One search.'), findsOneWidget);

    final bar = find.byType(V2BottomNav);
    expect(bar, findsOneWidget);

    // Icons only, as V2 draws them: the names are on the slots for screen readers, not on
    // screen. Scoped to the bar, because Home itself legitimately shows a "Flights" tab now
    // (#38) — that is the entry point #36 took away and this screen gives back.
    for (final label in ['Home', 'Stay & Play', 'Flights', 'Trips']) {
      expect(
        find.descendant(of: bar, matching: find.text(label)),
        findsNothing,
        reason: 'the bar shows no labels',
      );
    }
    expect(find.byIcon(Icons.public_rounded), findsNothing, reason: 'the globe is gone');
    for (final label in ['Home', 'Trips', 'Settings']) {
      expect(
        find.descendant(of: bar, matching: find.bySemanticsLabel(label)),
        findsOneWidget,
        reason: 'the $label slot is named for screen readers',
      );
    }
  });
}
