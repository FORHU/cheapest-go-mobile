/// The questions an empty chat opens with (ADR-0044) — V2's `QUICK_QUESTIONS` and
/// `ALWAYS_A_PERSON` from `suggestions.ts`.
///
/// Each one is a Help Centre article. Tapping it shows the article in the chat, labelled
/// automated, with "That answered it" and "Talk to a person". Nothing is stored in the
/// transcript: every row there has an author.
library;

import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';

enum QuickQuestion { confirmation, refunds, changes, priceGap, payment }

/// In the order a customer meets them.
const quickQuestions = QuickQuestion.values;

/// Only a person answers these, however well the article reads: a customer who believes they
/// have been charged twice is not asking a general question. Tapping it writes their question
/// and goes straight to the queue.
const alwaysAPerson = {QuickQuestion.payment};

extension QuickQuestionCopy on QuickQuestion {
  /// The id api-v2's suggestion counter accepts.
  String get articleId => name;

  String chip(AppLocalizations t) => switch (this) {
        QuickQuestion.confirmation => t.support_quick_confirmation,
        QuickQuestion.refunds => t.support_quick_refunds,
        QuickQuestion.changes => t.support_quick_changes,
        QuickQuestion.priceGap => t.support_quick_priceGap,
        QuickQuestion.payment => t.support_quick_payment,
      };

  String title(AppLocalizations t) => switch (this) {
        QuickQuestion.confirmation => t.help_sections_confirmation_title,
        QuickQuestion.refunds => t.help_sections_refunds_title,
        QuickQuestion.changes => t.help_sections_changes_title,
        QuickQuestion.priceGap => t.help_sections_priceGap_title,
        QuickQuestion.payment => t.help_sections_payment_title,
      };

  String body(AppLocalizations t) => switch (this) {
        QuickQuestion.confirmation => t.help_sections_confirmation_body,
        QuickQuestion.refunds => t.help_sections_refunds_body,
        QuickQuestion.changes => t.help_sections_changes_body,
        QuickQuestion.priceGap => t.help_sections_priceGap_body,
        QuickQuestion.payment => t.help_sections_payment_body,
      };
}
