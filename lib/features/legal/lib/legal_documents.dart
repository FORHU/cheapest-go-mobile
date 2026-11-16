import 'package:cheapest_go_mobile/features/legal/components/legal_blocks.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';

/// The four legal documents, section by section. See #44.
///
/// V2 builds these by walking its locale data, so its sections are discovered. Mobile's are
/// declared: `gen-l10n` turns the ARB into static getters and nothing can iterate them. The
/// words are the same words — every line below reads a mirrored message, none is written
/// here — but the shape of each document lives in code rather than in data.
///
/// That means a section added to V2 does not appear here on its own. The copy arrives with
/// the next sync and the screen stays as it was, so this file is the one to check when a
/// document changes upstream.

enum LegalDocument { terms, privacy, cookie, refund }

/// What the screen puts at the top of each document.
({String title, String subtitle}) legalHeading(AppLocalizations t, LegalDocument doc) =>
    switch (doc) {
        LegalDocument.terms =>
            (title: t.legal_termsOfService_pageTitle, subtitle: t.legal_termsOfService_pageSubtitle),
        LegalDocument.privacy =>
            (title: t.legal_privacyPolicy_pageTitle, subtitle: t.legal_privacyPolicy_pageSubtitle),
        LegalDocument.cookie =>
            (title: t.legal_cookiePolicy_pageTitle, subtitle: t.legal_cookiePolicy_pageSubtitle),
        LegalDocument.refund =>
            (title: t.legal_refundPolicy_pageTitle, subtitle: t.legal_refundPolicy_pageSubtitle),
    };

List<LegalSection> legalSections(AppLocalizations t, LegalDocument doc) => switch (doc) {
    LegalDocument.terms => _terms(t),
    LegalDocument.privacy => _privacy(t),
    LegalDocument.cookie => _cookie(t),
    LegalDocument.refund => _refund(t),
};

// ─── Terms of Service ─────────────────────────────────────────────────────────

List<LegalSection> _terms(AppLocalizations t) => [
    LegalSection(t.legal_content_terms_acceptance_title, [
        Para(t.legal_content_terms_acceptance_body),
    ]),
    LegalSection(t.legal_content_terms_eligibility_title, [
        Para(t.legal_content_terms_eligibility_intro),
        Bullets([
            t.legal_content_terms_eligibility_items_1,
            t.legal_content_terms_eligibility_items_2,
            t.legal_content_terms_eligibility_items_3,
            t.legal_content_terms_eligibility_items_4,
        ]),
    ]),
    LegalSection(t.legal_content_terms_accountRegistration_title, [
        Para(t.legal_content_terms_accountRegistration_intro),
        Bullets([
            t.legal_content_terms_accountRegistration_items_1,
            t.legal_content_terms_accountRegistration_items_2,
            t.legal_content_terms_accountRegistration_items_3,
            t.legal_content_terms_accountRegistration_items_4,
        ]),
        Note(t.legal_content_terms_accountRegistration_note),
    ]),
    LegalSection(t.legal_content_terms_bookingProcess_title, [
        Para(t.legal_content_terms_bookingProcess_intro),
        Defined([
            (t.legal_content_terms_bookingProcess_items_1_label,
             t.legal_content_terms_bookingProcess_items_1_text),
            (t.legal_content_terms_bookingProcess_items_2_label,
             t.legal_content_terms_bookingProcess_items_2_text),
            (t.legal_content_terms_bookingProcess_items_3_label,
             t.legal_content_terms_bookingProcess_items_3_text),
            (t.legal_content_terms_bookingProcess_items_4_label,
             t.legal_content_terms_bookingProcess_items_4_text),
        ]),
    ]),
    LegalSection(t.legal_content_terms_pricing_title, [
        Defined([
            (t.legal_content_terms_pricing_items_1_label, t.legal_content_terms_pricing_items_1_text),
            (t.legal_content_terms_pricing_items_2_label, t.legal_content_terms_pricing_items_2_text),
            (t.legal_content_terms_pricing_items_3_label, t.legal_content_terms_pricing_items_3_text),
            (t.legal_content_terms_pricing_items_4_label, t.legal_content_terms_pricing_items_4_text),
            (t.legal_content_terms_pricing_items_5_label, t.legal_content_terms_pricing_items_5_text),
        ]),
    ]),
    LegalSection(t.legal_content_terms_cancellations_title, [
        Linked(
            before: t.legal_content_terms_cancellations_textBefore,
            linkText: t.legal_content_terms_cancellations_refundLinkText,
            route: '/refund',
            after: t.legal_content_terms_cancellations_textAfter,
        ),
    ]),
    LegalSection(t.legal_content_terms_prohibitedConduct_title, [
        Para(t.legal_content_terms_prohibitedConduct_intro),
        Bullets([
            t.legal_content_terms_prohibitedConduct_items_1,
            t.legal_content_terms_prohibitedConduct_items_2,
            t.legal_content_terms_prohibitedConduct_items_3,
            t.legal_content_terms_prohibitedConduct_items_4,
            t.legal_content_terms_prohibitedConduct_items_5,
            t.legal_content_terms_prohibitedConduct_items_6,
            t.legal_content_terms_prohibitedConduct_items_7,
            t.legal_content_terms_prohibitedConduct_items_8,
        ]),
    ]),
    LegalSection(t.legal_content_terms_intellectualProperty_title, [
        Para(t.legal_content_terms_intellectualProperty_body),
    ]),
    LegalSection(t.legal_content_terms_disclaimers_title, [
        Para(t.legal_content_terms_disclaimers_intro),
        Bullets([
            t.legal_content_terms_disclaimers_items_1,
            t.legal_content_terms_disclaimers_items_2,
            t.legal_content_terms_disclaimers_items_3,
            t.legal_content_terms_disclaimers_items_4,
        ]),
        Note(t.legal_content_terms_disclaimers_note),
    ]),
    LegalSection(t.legal_content_terms_liability_title, [
        Para(t.legal_content_terms_liability_body),
    ]),
    LegalSection(t.legal_content_terms_indemnification_title, [
        Para(t.legal_content_terms_indemnification_body),
    ]),
    LegalSection(t.legal_content_terms_governingLaw_title, [
        Para(t.legal_content_terms_governingLaw_para1),
        Para(t.legal_content_terms_governingLaw_para2),
    ]),
    LegalSection(t.legal_content_terms_changes_title, [
        Para(t.legal_content_terms_changes_body),
    ]),
    LegalSection(t.legal_content_terms_contact_title, [
        Para(t.legal_content_terms_contact_intro),
        Para(t.legal_content_terms_contact_email),
        Para(t.legal_content_terms_contact_address),
    ]),
];

// ─── Privacy Policy ───────────────────────────────────────────────────────────

List<LegalSection> _privacy(AppLocalizations t) => [
    LegalSection(t.legal_content_privacy_whoWeAre_title, [
        Para(t.legal_content_privacy_whoWeAre_para1),
        // Two halves around a name V2 emphasises; mobile has no rich text, so they join.
        Para('${t.legal_content_privacy_whoWeAre_para2Before}'
            '${t.legal_content_privacy_whoWeAre_para2After}'),
    ]),
    LegalSection(t.legal_content_privacy_informationWeCollect_title, [
        Para(t.legal_content_privacy_informationWeCollect_directLabel),
        Bullets([
            t.legal_content_privacy_informationWeCollect_directItems_1,
            t.legal_content_privacy_informationWeCollect_directItems_2,
            t.legal_content_privacy_informationWeCollect_directItems_3,
            t.legal_content_privacy_informationWeCollect_directItems_4,
        ]),
        Para(t.legal_content_privacy_informationWeCollect_autoLabel),
        Bullets([
            t.legal_content_privacy_informationWeCollect_autoItems_1,
            t.legal_content_privacy_informationWeCollect_autoItems_2,
            t.legal_content_privacy_informationWeCollect_autoItems_3,
            t.legal_content_privacy_informationWeCollect_autoItems_4,
        ]),
        Para(t.legal_content_privacy_informationWeCollect_thirdPartyLabel),
        Bullets([
            t.legal_content_privacy_informationWeCollect_thirdPartyItems_1,
            t.legal_content_privacy_informationWeCollect_thirdPartyItems_2,
            t.legal_content_privacy_informationWeCollect_thirdPartyItems_3,
        ]),
    ]),
    LegalSection(t.legal_content_privacy_howWeUse_title, [
        Bullets([
            t.legal_content_privacy_howWeUse_items_1,
            t.legal_content_privacy_howWeUse_items_2,
            t.legal_content_privacy_howWeUse_items_3,
            t.legal_content_privacy_howWeUse_items_4,
            t.legal_content_privacy_howWeUse_items_5,
            t.legal_content_privacy_howWeUse_items_6,
            t.legal_content_privacy_howWeUse_items_7,
            t.legal_content_privacy_howWeUse_items_8,
        ]),
    ]),
    LegalSection(t.legal_content_privacy_howWeShare_title, [
        Para(t.legal_content_privacy_howWeShare_intro),
        Defined([
            (t.legal_content_privacy_howWeShare_items_1_label,
             t.legal_content_privacy_howWeShare_items_1_text),
            // Entry 2 carries a link of its own in V2. The address is shown rather than
            // tapped: it points off this app, and a legal page is read, not navigated.
            (t.legal_content_privacy_howWeShare_items_2_label,
             '${t.legal_content_privacy_howWeShare_items_2_text} '
             '${t.legal_content_privacy_howWeShare_items_2_linkText}'),
            (t.legal_content_privacy_howWeShare_items_3_label,
             t.legal_content_privacy_howWeShare_items_3_text),
            (t.legal_content_privacy_howWeShare_items_4_label,
             t.legal_content_privacy_howWeShare_items_4_text),
            (t.legal_content_privacy_howWeShare_items_5_label,
             t.legal_content_privacy_howWeShare_items_5_text),
        ]),
    ]),
    LegalSection(t.legal_content_privacy_cookies_title, [
        Linked(
            before: t.legal_content_privacy_cookies_textBefore,
            linkText: t.legal_content_privacy_cookies_linkText,
            route: '/cookies',
            after: t.legal_content_privacy_cookies_textAfter,
        ),
    ]),
    LegalSection(t.legal_content_privacy_dataRetention_title, [
        Para(t.legal_content_privacy_dataRetention_intro),
        Bullets([
            t.legal_content_privacy_dataRetention_items_1,
            t.legal_content_privacy_dataRetention_items_2,
            t.legal_content_privacy_dataRetention_items_3,
        ]),
        Note(t.legal_content_privacy_dataRetention_note),
    ]),
    LegalSection(t.legal_content_privacy_internationalTransfers_title, [
        Para(t.legal_content_privacy_internationalTransfers_body),
    ]),
    LegalSection(t.legal_content_privacy_yourRights_title, [
        Para(t.legal_content_privacy_yourRights_intro),
        Defined([
            (t.legal_content_privacy_yourRights_items_1_label,
             t.legal_content_privacy_yourRights_items_1_text),
            (t.legal_content_privacy_yourRights_items_2_label,
             t.legal_content_privacy_yourRights_items_2_text),
            (t.legal_content_privacy_yourRights_items_3_label,
             t.legal_content_privacy_yourRights_items_3_text),
            (t.legal_content_privacy_yourRights_items_4_label,
             t.legal_content_privacy_yourRights_items_4_text),
            (t.legal_content_privacy_yourRights_items_5_label,
             t.legal_content_privacy_yourRights_items_5_text),
            (t.legal_content_privacy_yourRights_items_6_label,
             t.legal_content_privacy_yourRights_items_6_text),
        ]),
        Para('${t.legal_content_privacy_yourRights_emailBefore}'
            '${t.legal_content_privacy_yourRights_emailAfter}'),
    ]),
    LegalSection(t.legal_content_privacy_childrensPrivacy_title, [
        Para(t.legal_content_privacy_childrensPrivacy_body),
    ]),
    LegalSection(t.legal_content_privacy_security_title, [
        Para(t.legal_content_privacy_security_body),
    ]),
    LegalSection(t.legal_content_privacy_changes_title, [
        Para(t.legal_content_privacy_changes_body),
    ]),
    LegalSection(t.legal_content_privacy_contact_title, [
        Para(t.legal_content_privacy_contact_intro),
        Para(t.legal_content_privacy_contact_email),
        Para(t.legal_content_privacy_contact_address),
    ]),
];

// ─── Cookie Policy ────────────────────────────────────────────────────────────

List<LegalSection> _cookie(AppLocalizations t) => [
    LegalSection(t.legal_content_cookie_whatAreCookies_title, [
        Para(t.legal_content_cookie_whatAreCookies_body),
    ]),
    LegalSection(t.legal_content_cookie_whyWeUse_title, [
        Para(t.legal_content_cookie_whyWeUse_intro),
        Bullets([
            t.legal_content_cookie_whyWeUse_items_1,
            t.legal_content_cookie_whyWeUse_items_2,
            t.legal_content_cookie_whyWeUse_items_3,
            t.legal_content_cookie_whyWeUse_items_4,
            t.legal_content_cookie_whyWeUse_items_5,
            t.legal_content_cookie_whyWeUse_items_6,
        ]),
    ]),
    // The one section built from categories rather than items: each is a heading, a line
    // about it, and sometimes the cookies themselves.
    LegalSection(t.legal_content_cookie_types_title, [
        Defined([
            (t.legal_content_cookie_types_categories_1_heading,
             t.legal_content_cookie_types_categories_1_body),
        ]),
        Bullets([
            t.legal_content_cookie_types_categories_1_items_1,
            t.legal_content_cookie_types_categories_1_items_2,
        ]),
        Defined([
            (t.legal_content_cookie_types_categories_2_heading,
             t.legal_content_cookie_types_categories_2_body),
        ]),
        Bullets([
            t.legal_content_cookie_types_categories_2_items_1,
            t.legal_content_cookie_types_categories_2_items_2,
            t.legal_content_cookie_types_categories_2_items_3,
        ]),
        Defined([
            (t.legal_content_cookie_types_categories_3_heading,
             t.legal_content_cookie_types_categories_3_body),
        ]),
        Bullets([
            t.legal_content_cookie_types_categories_3_items_1,
            t.legal_content_cookie_types_categories_3_items_2,
            t.legal_content_cookie_types_categories_3_items_3,
        ]),
        // The fourth category names no cookies, so it is a heading and a line.
        Defined([
            (t.legal_content_cookie_types_categories_4_heading,
             t.legal_content_cookie_types_categories_4_body),
        ]),
    ]),
    LegalSection(t.legal_content_cookie_thirdParty_title, [
        Para(t.legal_content_cookie_thirdParty_intro),
        Para('${t.legal_content_cookie_thirdParty_stripeBefore}'
            '${t.legal_content_cookie_thirdParty_stripeLinkText}'),
        Para(t.legal_content_cookie_thirdParty_supabaseText),
        Para(t.legal_content_cookie_thirdParty_outro),
    ]),
    LegalSection(t.legal_content_cookie_duration_title, [
        Para(t.legal_content_cookie_duration_intro),
        Defined([
            (t.legal_content_cookie_duration_items_1_label,
             t.legal_content_cookie_duration_items_1_text),
            (t.legal_content_cookie_duration_items_2_label,
             t.legal_content_cookie_duration_items_2_text),
        ]),
    ]),
    LegalSection(t.legal_content_cookie_managing_title, [
        Para(t.legal_content_cookie_managing_intro),
        Defined([
            (t.legal_content_cookie_managing_items_1_label,
             t.legal_content_cookie_managing_items_1_text),
            (t.legal_content_cookie_managing_items_2_label,
             t.legal_content_cookie_managing_items_2_text),
            (t.legal_content_cookie_managing_items_3_label,
             t.legal_content_cookie_managing_items_3_text),
        ]),
        Note(t.legal_content_cookie_managing_note),
    ]),
    LegalSection(t.legal_content_cookie_doNotTrack_title, [
        Para(t.legal_content_cookie_doNotTrack_body),
    ]),
    LegalSection(t.legal_content_cookie_changes_title, [
        Para(t.legal_content_cookie_changes_body),
    ]),
    LegalSection(t.legal_content_cookie_contact_title, [
        Para(t.legal_content_cookie_contact_intro),
        Para(t.legal_content_cookie_contact_email),
        Para(t.legal_content_cookie_contact_address),
    ]),
];

// ─── Refund Policy ────────────────────────────────────────────────────────────

List<LegalSection> _refund(AppLocalizations t) => [
    LegalSection(t.legal_content_refund_overview_title, [
        Para(t.legal_content_refund_overview_body),
    ]),
    LegalSection(t.legal_content_refund_cancellationTypes_title, [
        Para(t.legal_content_refund_cancellationTypes_intro),
        Defined([
            (t.legal_content_refund_cancellationTypes_free_heading,
             t.legal_content_refund_cancellationTypes_free_body),
            (t.legal_content_refund_cancellationTypes_partial_heading,
             t.legal_content_refund_cancellationTypes_partial_body),
            (t.legal_content_refund_cancellationTypes_nonRefundable_heading,
             t.legal_content_refund_cancellationTypes_nonRefundable_body),
        ]),
    ]),
    LegalSection(t.legal_content_refund_howToCancel_title, [
        Para(t.legal_content_refund_howToCancel_intro),
        Bullets([
            t.legal_content_refund_howToCancel_steps_1,
            t.legal_content_refund_howToCancel_steps_2,
            t.legal_content_refund_howToCancel_steps_3,
            t.legal_content_refund_howToCancel_steps_4,
        ]),
        Para('${t.legal_content_refund_howToCancel_emailBefore}'
            '${t.legal_content_refund_howToCancel_emailAfter}'),
    ]),
    LegalSection(t.legal_content_refund_processing_title, [
        Defined([
            (t.legal_content_refund_processing_items_1_label,
             t.legal_content_refund_processing_items_1_text),
            (t.legal_content_refund_processing_items_2_label,
             t.legal_content_refund_processing_items_2_text),
            (t.legal_content_refund_processing_items_3_label,
             t.legal_content_refund_processing_items_3_text),
            (t.legal_content_refund_processing_items_4_label,
             t.legal_content_refund_processing_items_4_text),
            (t.legal_content_refund_processing_items_5_label,
             t.legal_content_refund_processing_items_5_text),
        ]),
    ]),
    LegalSection(t.legal_content_refund_noShows_title, [
        Para(t.legal_content_refund_noShows_body),
    ]),
    LegalSection(t.legal_content_refund_amendments_title, [
        Para(t.legal_content_refund_amendments_intro),
        Bullets([
            t.legal_content_refund_amendments_steps_1,
            t.legal_content_refund_amendments_steps_2,
            t.legal_content_refund_amendments_steps_3,
        ]),
        Note('${t.legal_content_refund_amendments_noteLabel} '
            '${t.legal_content_refund_amendments_noteText}'),
    ]),
    LegalSection(t.legal_content_refund_supplierCancellations_title, [
        Para(t.legal_content_refund_supplierCancellations_intro),
        Bullets([
            t.legal_content_refund_supplierCancellations_items_1,
            t.legal_content_refund_supplierCancellations_items_2,
            t.legal_content_refund_supplierCancellations_items_3,
        ]),
        Note(t.legal_content_refund_supplierCancellations_note),
    ]),
    LegalSection(t.legal_content_refund_disputes_title, [
        Para(t.legal_content_refund_disputes_body),
    ]),
    LegalSection(t.legal_content_refund_flightPackages_title, [
        Para(t.legal_content_refund_flightPackages_body),
    ]),
    LegalSection(t.legal_content_refund_contact_title, [
        Para(t.legal_content_refund_contact_intro),
        Para(t.legal_content_refund_contact_email),
        Para(t.legal_content_refund_contact_address),
        Para(t.legal_content_refund_contact_outro),
    ]),
];
