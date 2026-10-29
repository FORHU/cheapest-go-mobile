import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cheapest_go_mobile/app/app.dart';
import 'package:cheapest_go_mobile/app/theme/app_theme.dart';
import 'package:cheapest_go_mobile/features/hotels/contracts/hotels_contract.dart';
import 'package:cheapest_go_mobile/shared/auth/permissions.dart';
import 'package:cheapest_go_mobile/shared/auth/rbac.dart';
import 'package:cheapest_go_mobile/shared/auth/roles.dart';
import 'package:cheapest_go_mobile/shared/components/glass_card.dart';
import 'package:cheapest_go_mobile/shared/components/app_buttons.dart';
import 'package:cheapest_go_mobile/shared/errors/api_error.dart';
import 'package:cheapest_go_mobile/shared/errors/error_router.dart';
import 'package:cheapest_go_mobile/shared/errors/retry_policy.dart';
import 'package:cheapest_go_mobile/shared/utils/currency.dart';

void main() {
  group('FAOS Shared Layer Unit Tests', () {
    test('retry policy matches next-template-v1 rules', () {
      expect(
        getRetryCount(ApiError('Net', category: ErrorCategory.network)),
        3,
      );
      expect(
        getRetryCount(
          ApiError('502', category: ErrorCategory.server, status: 502),
        ),
        2,
      );
      expect(
        getRetryCount(
          ApiError('429', category: ErrorCategory.unknown, status: 429),
        ),
        1,
      );
      expect(
        getRetryCount(ApiError('401', category: ErrorCategory.auth, status: 401)),
        0,
      );
    });

    test('error router maps categories deterministically', () {
      final authRouted = routeError(
        ApiError('Unauthorized', category: ErrorCategory.auth),
      );
      expect(authRouted.action, ErrorRouteAction.logout);
      expect(authRouted.toast, 'Session expired');
    });

    test('RBAC engine enforces role permissions', () {
      expect(hasPermission(Role.admin, Permission.adminAccess), isTrue);
      expect(hasPermission(Role.user, Permission.adminAccess), isFalse);
      expect(hasPermission(Role.guest, Permission.savedManage), isTrue);
      expect(hasPermission(Role.guest, Permission.bookingsCreate), isFalse);
    });

    test('Currency conversion matches static fallback formula', () {
      final usd = CurrencyService.convertCurrency(150000, 'KRW', 'USD');
      expect(usd, closeTo(112.5, 0.1));
    });

    test('V2 HotelSummary and PrebookQuote contracts parse API v2 payloads', () {
      final summary = HotelSummary.fromJson({
        'hotelId': 'tgx-101',
        'name': 'Seoul Grand Hotel',
        'city': 'Seoul',
        'country': 'KR',
        'lat': 37.5665,
        'lng': 126.9780,
        'price': 140.0,
        'stayTotal': 420.0,
        'nights': 3,
        'currency': 'USD',
        'offerId': 'offer-xyz',
        'refundableTag': 'RFN',
      });
      expect(summary.nightlyRate, 140.0);
      expect(summary.stayTotal, 420.0);
      expect(summary.offers, hasLength(1));
      expect(summary.offers.first.offerId, 'offer-xyz');
      expect(summary.offers.first.refundable, isTrue);

      final prebook = PrebookQuote.fromJson({
        'prebookId': 'pb-999',
        'currency': 'USD',
        'price': {'subtotal': 400.0, 'taxes': 20.0, 'total': 420.0},
        'display': {
          'currency': 'USD',
          'total': 420.0,
          'serviceFee': 18.5,
          'chargedTotal': 438.5,
        },
        'cancellationPolicies': {'refundableTag': 'RFN'},
        'boardCode': 'BB',
      });
      expect(prebook.prebookId, 'pb-999');
      expect(prebook.authoritativePrice, 420.0);
      expect(prebook.displayChargedTotal, 438.5);
      expect(prebook.serviceFee, 18.5);
      expect(prebook.refundableTag, 'RFN');
    });
  });

  group('Minimalist Design System & GlassCard Tests', () {
    testWidgets('AppTheme registers AppColors token extension', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) {
              final colors = context.colors;
              expect(colors.accent, const Color(0xFF0052FF));
              expect(colors.background, const Color(0xFFF8FAFC));
              return Scaffold(
                body: GlassCard(
                  child: AppPrimaryButton(
                    label: 'Book Now',
                    onPressed: () {},
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Book Now'), findsOneWidget);
      expect(find.byType(GlassCard), findsOneWidget);
    });
  });

  testWidgets('CheapestGoApp renders Home Shell and Minimalist Navigation', (tester) async {
    await tester.pumpWidget(const CheapestGoApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Where will you'), findsOneWidget);
    expect(find.text('Hotels'), findsWidgets);
    expect(find.text('Flights'), findsWidgets);
    expect(find.byIcon(Icons.public_rounded), findsOneWidget); // Globe dome
  });
}
