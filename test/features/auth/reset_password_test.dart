import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/features/auth/views/auth_code_error_view.dart';
import 'package:cheapest_go_mobile/features/auth/views/reset_password_view.dart';

import 'package:cheapest_go_mobile/features/auth/components/auth_form_widgets.dart';

import '../../test_helpers.dart';

/// The two auth screens mobile never had. See #45.
void main() {
  group('reset password', () {
    testWidgets('without a token it says so instead of showing a form', (tester) async {
      await pumpScreen(tester, const ResetPasswordView());

      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Send reset link'), findsOneWidget);
    });

    testWidgets('with a token it asks for a password twice', (tester) async {
      await pumpScreen(tester, const ResetPasswordView(token: 'tok_1'));

      expect(find.byType(TextFormField), findsNWidgets(2));
      // All three rules are stated before anything is typed, not after it is rejected.
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(find.text('At least one uppercase letter'), findsOneWidget);
      expect(find.text('At least one number'), findsOneWidget);
    });

    testWidgets('a confirmation that does not match is refused', (tester) async {
      await pumpScreen(tester, const ResetPasswordView(token: 'tok_1'));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Password1');
      await tester.enterText(fields.at(1), 'Password2');
      await tester.tap(find.byType(AuthSubmitButton));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('a weak password is refused before anything is sent', (tester) async {
      await pumpScreen(tester, const ResetPasswordView(token: 'tok_1'));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'alllowercase1');
      await tester.enterText(fields.at(1), 'alllowercase1');
      await tester.tap(find.byType(AuthSubmitButton));
      await tester.pumpAndSettle();

      // Still on the form: the uppercase rule was not met.
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Password updated'), findsNothing);
    });
  });

  testWidgets('the auth error screen offers both ways on', (tester) async {
    await pumpScreen(tester, const AuthCodeErrorView());

    expect(find.text('Try signing in again'), findsOneWidget);
    expect(find.text('Go to homepage'), findsOneWidget);
  });
}
