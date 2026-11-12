import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @about_builtBody.
  ///
  /// In en, this message translates to:
  /// **'We focus on travelers in Southeast Asia — local currencies, local context, and support that understands how you travel.'**
  String get about_builtBody;

  /// No description provided for @about_builtTitle.
  ///
  /// In en, this message translates to:
  /// **'Built for the region'**
  String get about_builtTitle;

  /// No description provided for @about_contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get about_contactUs;

  /// No description provided for @about_dealsBody.
  ///
  /// In en, this message translates to:
  /// **'Curated weekend getaways and travel deals, updated daily, so the best value is the first thing you see.'**
  String get about_dealsBody;

  /// No description provided for @about_dealsTitle.
  ///
  /// In en, this message translates to:
  /// **'Deals & packages'**
  String get about_dealsTitle;

  /// No description provided for @about_flightsBody.
  ///
  /// In en, this message translates to:
  /// **'Search and book flights worldwide through our airline partners, with clear pricing and no surprise fees at checkout.'**
  String get about_flightsBody;

  /// No description provided for @about_flightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Flights'**
  String get about_flightsTitle;

  /// No description provided for @about_heroBody.
  ///
  /// In en, this message translates to:
  /// **'CheapestGo is a modern travel platform that helps you discover, compare, and book flights and hotels in one place — at prices you can actually trust.'**
  String get about_heroBody;

  /// No description provided for @about_heroLabel.
  ///
  /// In en, this message translates to:
  /// **'About CheapestGo'**
  String get about_heroLabel;

  /// No description provided for @about_heroTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel that respects your time and your wallet.'**
  String get about_heroTitle;

  /// No description provided for @about_hotelsBody.
  ///
  /// In en, this message translates to:
  /// **'Millions of hotels and unique stays, sourced from leading global suppliers so you always have real availability and rates.'**
  String get about_hotelsBody;

  /// No description provided for @about_hotelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hotels & stays'**
  String get about_hotelsTitle;

  /// No description provided for @about_meta_description.
  ///
  /// In en, this message translates to:
  /// **'CheapestGo is a modern online travel agency helping travelers across Southeast Asia find and book flights, hotels, and packages at transparent prices.'**
  String get about_meta_description;

  /// No description provided for @about_meta_title.
  ///
  /// In en, this message translates to:
  /// **'About Us — CheapestGo'**
  String get about_meta_title;

  /// No description provided for @about_missionBody.
  ///
  /// In en, this message translates to:
  /// **'Booking travel should feel effortless, not adversarial. Too many platforms bury fees, inflate prices, and make you second-guess every click. We built CheapestGo to do the opposite: surface the best real prices, show exactly what you pay, and get you booked in as few steps as possible — whether you are chasing a weekend escape or planning the trip of a lifetime.'**
  String get about_missionBody;

  /// No description provided for @about_missionTitle.
  ///
  /// In en, this message translates to:
  /// **'Our mission'**
  String get about_missionTitle;

  /// No description provided for @about_partnersBody.
  ///
  /// In en, this message translates to:
  /// **'Our flight, hotel, and payment inventory comes from established global providers, so the availability and rates you see are real and bookable.'**
  String get about_partnersBody;

  /// No description provided for @about_partnersTitle.
  ///
  /// In en, this message translates to:
  /// **'Powered by trusted partners'**
  String get about_partnersTitle;

  /// No description provided for @about_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get about_privacy;

  /// No description provided for @about_refund.
  ///
  /// In en, this message translates to:
  /// **'Refund Policy'**
  String get about_refund;

  /// No description provided for @about_secureBody.
  ///
  /// In en, this message translates to:
  /// **'Payments are processed by Stripe and we never store your card details. Your data is encrypted in transit and at rest.'**
  String get about_secureBody;

  /// No description provided for @about_secureTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure by default'**
  String get about_secureTitle;

  /// No description provided for @about_startExploring.
  ///
  /// In en, this message translates to:
  /// **'Start exploring'**
  String get about_startExploring;

  /// No description provided for @about_terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get about_terms;

  /// No description provided for @about_transparentBody.
  ///
  /// In en, this message translates to:
  /// **'We apply a single, transparent service markup that is already included in the price you see. No hidden fees, ever.'**
  String get about_transparentBody;

  /// No description provided for @about_transparentTitle.
  ///
  /// In en, this message translates to:
  /// **'Transparent pricing'**
  String get about_transparentTitle;

  /// No description provided for @about_valuesTitle.
  ///
  /// In en, this message translates to:
  /// **'What makes us different'**
  String get about_valuesTitle;

  /// No description provided for @about_whatWeDoTitle.
  ///
  /// In en, this message translates to:
  /// **'What we do'**
  String get about_whatWeDoTitle;

  /// No description provided for @about_whoBody.
  ///
  /// In en, this message translates to:
  /// **'CheapestGo is operated by FORHU Inc., headquartered at 30 Wall Street, 8th Floor, New York, NY 10005, United States. Questions, feedback, or partnership ideas are always welcome.'**
  String get about_whoBody;

  /// No description provided for @about_whoTitle.
  ///
  /// In en, this message translates to:
  /// **'Who runs CheapestGo'**
  String get about_whoTitle;

  /// No description provided for @account_preferences_displayCurrency.
  ///
  /// In en, this message translates to:
  /// **'Display Currency'**
  String get account_preferences_displayCurrency;

  /// No description provided for @account_preferences_emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email notifications'**
  String get account_preferences_emailNotifications;

  /// No description provided for @account_preferences_emailNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmations, price alerts, and trip reminders'**
  String get account_preferences_emailNotificationsHint;

  /// No description provided for @account_preferences_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get account_preferences_language;

  /// No description provided for @account_preferences_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get account_preferences_notifications;

  /// No description provided for @account_preferences_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize your browsing and notification settings.'**
  String get account_preferences_subtitle;

  /// No description provided for @account_preferences_title.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get account_preferences_title;

  /// No description provided for @account_priceAlerts_alertAt.
  ///
  /// In en, this message translates to:
  /// **'Alert at'**
  String get account_priceAlerts_alertAt;

  /// No description provided for @account_priceAlerts_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete alert'**
  String get account_priceAlerts_delete;

  /// No description provided for @account_priceAlerts_emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Set up alerts from the search results page to track prices.'**
  String get account_priceAlerts_emptyBody;

  /// No description provided for @account_priceAlerts_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No price alerts'**
  String get account_priceAlerts_emptyTitle;

  /// No description provided for @account_priceAlerts_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified when prices drop for your saved routes.'**
  String get account_priceAlerts_subtitle;

  /// No description provided for @account_priceAlerts_title.
  ///
  /// In en, this message translates to:
  /// **'Price Alerts'**
  String get account_priceAlerts_title;

  /// No description provided for @account_profile_admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get account_profile_admin;

  /// No description provided for @account_profile_displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get account_profile_displayName;

  /// No description provided for @account_profile_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get account_profile_password;

  /// No description provided for @account_profile_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your personal account information.'**
  String get account_profile_subtitle;

  /// No description provided for @account_profile_title.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get account_profile_title;

  /// No description provided for @account_savedTrips_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart icon on any hotel or flight to save it here.'**
  String get account_savedTrips_hint;

  /// No description provided for @account_savedTrips_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get account_savedTrips_remove;

  /// No description provided for @account_savedTrips_title.
  ///
  /// In en, this message translates to:
  /// **'Saved Trips'**
  String get account_savedTrips_title;

  /// No description provided for @account_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your profile, preferences, and saved items.'**
  String get account_subtitle;

  /// No description provided for @account_title.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get account_title;

  /// No description provided for @ai_askAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask anything...'**
  String get ai_askAnything;

  /// No description provided for @ai_goHome.
  ///
  /// In en, this message translates to:
  /// **'Go to home'**
  String get ai_goHome;

  /// No description provided for @ai_greeting.
  ///
  /// In en, this message translates to:
  /// **'What\'s on the agenda today?'**
  String get ai_greeting;

  /// No description provided for @ai_metaTitle.
  ///
  /// In en, this message translates to:
  /// **'Cheap — AI Travel Assistant'**
  String get ai_metaTitle;

  /// No description provided for @ai_newChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get ai_newChat;

  /// No description provided for @ai_prompts_bali.
  ///
  /// In en, this message translates to:
  /// **'Find me a beachfront resort in Bali for 2 adults, Feb 14-21...'**
  String get ai_prompts_bali;

  /// No description provided for @ai_prompts_cebu.
  ///
  /// In en, this message translates to:
  /// **'Weekend getaway in Cebu for a couple, next month...'**
  String get ai_prompts_cebu;

  /// No description provided for @ai_prompts_manila.
  ///
  /// In en, this message translates to:
  /// **'Family resort near Manila, 2 adults 2 kids...'**
  String get ai_prompts_manila;

  /// No description provided for @ai_prompts_tokyo.
  ///
  /// In en, this message translates to:
  /// **'Luxury hotel in Tokyo under \$200/night with pool...'**
  String get ai_prompts_tokyo;

  /// No description provided for @ai_sendHint.
  ///
  /// In en, this message translates to:
  /// **'Enter to send · Shift+Enter for new line'**
  String get ai_sendHint;

  /// No description provided for @ai_suggestions_1.
  ///
  /// In en, this message translates to:
  /// **'Find me cheap flights to Tokyo next month'**
  String get ai_suggestions_1;

  /// No description provided for @ai_suggestions_2.
  ///
  /// In en, this message translates to:
  /// **'What hotels are available in Bali for 2 adults?'**
  String get ai_suggestions_2;

  /// No description provided for @ai_suggestions_3.
  ///
  /// In en, this message translates to:
  /// **'Plan a 5-day trip to Paris on a budget'**
  String get ai_suggestions_3;

  /// No description provided for @ai_suggestions_4.
  ///
  /// In en, this message translates to:
  /// **'What\'s the cheapest day to fly to NYC?'**
  String get ai_suggestions_4;

  /// No description provided for @appBanner_badge.
  ///
  /// In en, this message translates to:
  /// **'Mobile App'**
  String get appBanner_badge;

  /// No description provided for @appBanner_downloadBtn.
  ///
  /// In en, this message translates to:
  /// **'Download App'**
  String get appBanner_downloadBtn;

  /// No description provided for @appBanner_downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get appBanner_downloads;

  /// No description provided for @appBanner_installBtn.
  ///
  /// In en, this message translates to:
  /// **'Install App'**
  String get appBanner_installBtn;

  /// No description provided for @appBanner_learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get appBanner_learnMore;

  /// No description provided for @appBanner_rating.
  ///
  /// In en, this message translates to:
  /// **'App Rating'**
  String get appBanner_rating;

  /// No description provided for @appBanner_savings.
  ///
  /// In en, this message translates to:
  /// **'Extra Savings'**
  String get appBanner_savings;

  /// No description provided for @appBanner_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Get exclusive app-only deals, instant notifications, and manage your trips on the go.'**
  String get appBanner_subtitle;

  /// No description provided for @appBanner_title.
  ///
  /// In en, this message translates to:
  /// **'Travel smarter with our app'**
  String get appBanner_title;

  /// No description provided for @auth_agreePrefix.
  ///
  /// In en, this message translates to:
  /// **'By signing up you agree to our'**
  String get auth_agreePrefix;

  /// No description provided for @auth_atLeast8.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get auth_atLeast8;

  /// No description provided for @auth_backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get auth_backToSignIn;

  /// No description provided for @auth_checkInbox.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get auth_checkInbox;

  /// No description provided for @auth_chooseStrong.
  ///
  /// In en, this message translates to:
  /// **'Choose a strong password for your account.'**
  String get auth_chooseStrong;

  /// No description provided for @auth_clickLinkSuffix.
  ///
  /// In en, this message translates to:
  /// **'. Click the link in the email to set a new password.'**
  String get auth_clickLinkSuffix;

  /// No description provided for @auth_createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get auth_createAccount;

  /// No description provided for @auth_createOne.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get auth_createOne;

  /// No description provided for @auth_createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get auth_createYourAccount;

  /// No description provided for @auth_emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get auth_emailInvalid;

  /// No description provided for @auth_emailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get auth_emailPlaceholder;

  /// No description provided for @auth_emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get auth_emailRequired;

  /// No description provided for @auth_firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get auth_firstName;

  /// No description provided for @auth_firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get auth_firstNameRequired;

  /// No description provided for @auth_firstNameShort.
  ///
  /// In en, this message translates to:
  /// **'First'**
  String get auth_firstNameShort;

  /// No description provided for @auth_forgotBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a reset link.'**
  String get auth_forgotBody;

  /// No description provided for @auth_forgotPasswordQ.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get auth_forgotPasswordQ;

  /// No description provided for @auth_forgotPitch.
  ///
  /// In en, this message translates to:
  /// **'Locked out is temporary. Your trips are still where you left them.'**
  String get auth_forgotPitch;

  /// No description provided for @auth_forgotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We will email you a link to set a new one'**
  String get auth_forgotSubtitle;

  /// No description provided for @auth_haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get auth_haveAccount;

  /// No description provided for @auth_hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get auth_hidePassword;

  /// No description provided for @auth_lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get auth_lastName;

  /// No description provided for @auth_lastNameShort.
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get auth_lastNameShort;

  /// No description provided for @auth_loginPitch.
  ///
  /// In en, this message translates to:
  /// **'Your trips, your saved searches, and every booking in one place.'**
  String get auth_loginPitch;

  /// No description provided for @auth_noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get auth_noAccount;

  /// No description provided for @auth_noResetToken.
  ///
  /// In en, this message translates to:
  /// **'No reset token found. Please use the link sent to your email.'**
  String get auth_noResetToken;

  /// No description provided for @auth_notUsedBefore.
  ///
  /// In en, this message translates to:
  /// **'Choose something you have not used here before'**
  String get auth_notUsedBefore;

  /// No description provided for @auth_passwordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get auth_passwordPlaceholder;

  /// No description provided for @auth_passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get auth_passwordRequired;

  /// No description provided for @auth_passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get auth_passwordUpdated;

  /// No description provided for @auth_passwordWeak.
  ///
  /// In en, this message translates to:
  /// **'Password does not meet requirements'**
  String get auth_passwordWeak;

  /// No description provided for @auth_registerPitch.
  ///
  /// In en, this message translates to:
  /// **'One account. Every fare we can find, on every route we cover.'**
  String get auth_registerPitch;

  /// No description provided for @auth_registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start finding the cheapest fares worldwide'**
  String get auth_registerSubtitle;

  /// No description provided for @auth_repeatPassword.
  ///
  /// In en, this message translates to:
  /// **'Repeat your password'**
  String get auth_repeatPassword;

  /// No description provided for @auth_resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get auth_resetPassword;

  /// No description provided for @auth_resetYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get auth_resetYourPassword;

  /// No description provided for @auth_sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get auth_sendResetLink;

  /// No description provided for @auth_setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get auth_setNewPassword;

  /// No description provided for @auth_showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get auth_showPassword;

  /// No description provided for @auth_signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account to continue'**
  String get auth_signInToContinue;

  /// No description provided for @auth_signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get auth_signInWithGoogle;

  /// No description provided for @auth_signIn_continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get auth_signIn_continueWithApple;

  /// No description provided for @auth_signIn_continueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get auth_signIn_continueWithEmail;

  /// No description provided for @auth_signIn_continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get auth_signIn_continueWithGoogle;

  /// No description provided for @auth_signIn_emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get auth_signIn_emailLabel;

  /// No description provided for @auth_signIn_emailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get auth_signIn_emailPlaceholder;

  /// No description provided for @auth_signIn_orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get auth_signIn_orDivider;

  /// No description provided for @auth_signIn_privacyLink.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get auth_signIn_privacyLink;

  /// No description provided for @auth_signIn_terms.
  ///
  /// In en, this message translates to:
  /// **'By signing in you agree to our {terms} and {privacy}.'**
  String auth_signIn_terms(Object terms, Object privacy);

  /// No description provided for @auth_signIn_termsLink.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get auth_signIn_termsLink;

  /// No description provided for @auth_signIn_title.
  ///
  /// In en, this message translates to:
  /// **'Sign in to CheapestGo'**
  String get auth_signIn_title;

  /// No description provided for @auth_signUpWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get auth_signUpWithGoogle;

  /// No description provided for @auth_staff_pitch.
  ///
  /// In en, this message translates to:
  /// **'The same account you use everywhere else. This door just knows where to put you.'**
  String get auth_staff_pitch;

  /// No description provided for @auth_staff_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Support and administration for CheapestGo'**
  String get auth_staff_subtitle;

  /// No description provided for @auth_staff_title.
  ///
  /// In en, this message translates to:
  /// **'Staff sign in'**
  String get auth_staff_title;

  /// No description provided for @auth_strongPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a strong password'**
  String get auth_strongPassword;

  /// No description provided for @auth_tryAgain.
  ///
  /// In en, this message translates to:
  /// **'try again'**
  String get auth_tryAgain;

  /// No description provided for @auth_welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get auth_welcomeBack;

  /// No description provided for @checkout_agreePrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our'**
  String get checkout_agreePrefix;

  /// No description provided for @checkout_alert_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get checkout_alert_close;

  /// No description provided for @checkout_alert_fareChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'The fare changed'**
  String get checkout_alert_fareChangedTitle;

  /// No description provided for @checkout_alert_fareGoneTitle.
  ///
  /// In en, this message translates to:
  /// **'This fare is no longer available'**
  String get checkout_alert_fareGoneTitle;

  /// No description provided for @checkout_alert_paymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Your payment didn\'t go through'**
  String get checkout_alert_paymentTitle;

  /// No description provided for @checkout_alert_searchAgain.
  ///
  /// In en, this message translates to:
  /// **'Search again'**
  String get checkout_alert_searchAgain;

  /// No description provided for @checkout_allSet.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get checkout_allSet;

  /// No description provided for @checkout_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get checkout_back;

  /// No description provided for @checkout_backToBookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Back to booking details'**
  String get checkout_backToBookingDetails;

  /// No description provided for @checkout_booked.
  ///
  /// In en, this message translates to:
  /// **'BOOKED'**
  String get checkout_booked;

  /// No description provided for @checkout_bookingErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking error'**
  String get checkout_bookingErrorTitle;

  /// No description provided for @checkout_bookingFor_guestFirstName.
  ///
  /// In en, this message translates to:
  /// **'Guest First Name *'**
  String get checkout_bookingFor_guestFirstName;

  /// No description provided for @checkout_bookingFor_guestLastName.
  ///
  /// In en, this message translates to:
  /// **'Guest Last Name *'**
  String get checkout_bookingFor_guestLastName;

  /// No description provided for @checkout_bookingFor_myself.
  ///
  /// In en, this message translates to:
  /// **'Myself'**
  String get checkout_bookingFor_myself;

  /// No description provided for @checkout_bookingFor_someoneElse.
  ///
  /// In en, this message translates to:
  /// **'Someone else'**
  String get checkout_bookingFor_someoneElse;

  /// No description provided for @checkout_bookingFor_whoIsBooking.
  ///
  /// In en, this message translates to:
  /// **'Who is the booking for?'**
  String get checkout_bookingFor_whoIsBooking;

  /// No description provided for @checkout_bookingPage_loading.
  ///
  /// In en, this message translates to:
  /// **'Checking your booking…'**
  String get checkout_bookingPage_loading;

  /// No description provided for @checkout_bookingPage_notFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that booking'**
  String get checkout_bookingPage_notFound;

  /// No description provided for @checkout_bookingPage_notFoundDescription.
  ///
  /// In en, this message translates to:
  /// **'It may belong to a different account. Sign in with the account you booked with.'**
  String get checkout_bookingPage_notFoundDescription;

  /// No description provided for @checkout_bookingPage_reference.
  ///
  /// In en, this message translates to:
  /// **'Booking reference'**
  String get checkout_bookingPage_reference;

  /// No description provided for @checkout_bookingPage_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get checkout_bookingPage_refresh;

  /// No description provided for @checkout_bookingPage_stillWorking.
  ///
  /// In en, this message translates to:
  /// **'Still working on it — this page updates by itself.'**
  String get checkout_bookingPage_stillWorking;

  /// No description provided for @checkout_bookingPage_viewTrips.
  ///
  /// In en, this message translates to:
  /// **'View my trips'**
  String get checkout_bookingPage_viewTrips;

  /// No description provided for @checkout_bookingReference.
  ///
  /// In en, this message translates to:
  /// **'Booking Reference'**
  String get checkout_bookingReference;

  /// No description provided for @checkout_cancellation_cancelAfter.
  ///
  /// In en, this message translates to:
  /// **'Cancel after'**
  String get checkout_cancellation_cancelAfter;

  /// No description provided for @checkout_cancellation_cancelBy.
  ///
  /// In en, this message translates to:
  /// **'Cancel by'**
  String get checkout_cancellation_cancelBy;

  /// No description provided for @checkout_cancellation_description.
  ///
  /// In en, this message translates to:
  /// **'How much will it cost to cancel the rooms?'**
  String get checkout_cancellation_description;

  /// No description provided for @checkout_cancellation_earlyDepartureFee.
  ///
  /// In en, this message translates to:
  /// **'Early Departure Fee: {amount} if you check out before your scheduled date.'**
  String checkout_cancellation_earlyDepartureFee(Object amount);

  /// No description provided for @checkout_cancellation_footer.
  ///
  /// In en, this message translates to:
  /// **'Cancellation costs are based on the total booking value. All dates and times are mentioned in GMT.'**
  String get checkout_cancellation_footer;

  /// No description provided for @checkout_cancellation_freeCancellation.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation available — see deadlines below'**
  String get checkout_cancellation_freeCancellation;

  /// No description provided for @checkout_cancellation_freeCancellationLabel.
  ///
  /// In en, this message translates to:
  /// **'Free Cancellation'**
  String get checkout_cancellation_freeCancellationLabel;

  /// No description provided for @checkout_cancellation_fullRefund.
  ///
  /// In en, this message translates to:
  /// **'(Full refund)'**
  String get checkout_cancellation_fullRefund;

  /// No description provided for @checkout_cancellation_noShowPenalty.
  ///
  /// In en, this message translates to:
  /// **'No-Show Penalty: {amount} if you don’t check in without cancelling.'**
  String checkout_cancellation_noShowPenalty(Object amount);

  /// No description provided for @checkout_cancellation_nonRefundable.
  ///
  /// In en, this message translates to:
  /// **'Non-refundable — this booking cannot be cancelled for a refund'**
  String get checkout_cancellation_nonRefundable;

  /// No description provided for @checkout_cancellation_refund.
  ///
  /// In en, this message translates to:
  /// **'{amount} Refund'**
  String checkout_cancellation_refund(Object amount);

  /// No description provided for @checkout_cancellation_title.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Policy'**
  String get checkout_cancellation_title;

  /// No description provided for @checkout_cardNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get checkout_cardNamePlaceholder;

  /// No description provided for @checkout_checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get checkout_checkIn;

  /// No description provided for @checkout_checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get checkout_checkOut;

  /// No description provided for @checkout_chooseYourDates.
  ///
  /// In en, this message translates to:
  /// **'Choose your dates'**
  String get checkout_chooseYourDates;

  /// No description provided for @checkout_completeYourBooking.
  ///
  /// In en, this message translates to:
  /// **'Complete your booking'**
  String get checkout_completeYourBooking;

  /// No description provided for @checkout_confirmingBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirming your booking'**
  String get checkout_confirmingBooking;

  /// No description provided for @checkout_confirmingFinalPrice.
  ///
  /// In en, this message translates to:
  /// **'Confirming the final price…'**
  String get checkout_confirmingFinalPrice;

  /// No description provided for @checkout_confirmingWithHotel.
  ///
  /// In en, this message translates to:
  /// **'Confirming with the hotel...'**
  String get checkout_confirmingWithHotel;

  /// No description provided for @checkout_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get checkout_continue;

  /// No description provided for @checkout_continueToPayment.
  ///
  /// In en, this message translates to:
  /// **'Continue to payment'**
  String get checkout_continueToPayment;

  /// No description provided for @checkout_datePicker_chooseMonth.
  ///
  /// In en, this message translates to:
  /// **'Choose year and month'**
  String get checkout_datePicker_chooseMonth;

  /// No description provided for @checkout_datePicker_chooseYear.
  ///
  /// In en, this message translates to:
  /// **'Choose year'**
  String get checkout_datePicker_chooseYear;

  /// No description provided for @checkout_datePicker_nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get checkout_datePicker_nextMonth;

  /// No description provided for @checkout_datePicker_nextYear.
  ///
  /// In en, this message translates to:
  /// **'Next year'**
  String get checkout_datePicker_nextYear;

  /// No description provided for @checkout_datePicker_nextYears.
  ///
  /// In en, this message translates to:
  /// **'Later years'**
  String get checkout_datePicker_nextYears;

  /// No description provided for @checkout_datePicker_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get checkout_datePicker_placeholder;

  /// No description provided for @checkout_datePicker_previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get checkout_datePicker_previousMonth;

  /// No description provided for @checkout_datePicker_previousYear.
  ///
  /// In en, this message translates to:
  /// **'Previous year'**
  String get checkout_datePicker_previousYear;

  /// No description provided for @checkout_datePicker_previousYears.
  ///
  /// In en, this message translates to:
  /// **'Earlier years'**
  String get checkout_datePicker_previousYears;

  /// No description provided for @checkout_dontClosePage.
  ///
  /// In en, this message translates to:
  /// **'Please don\'t close this page'**
  String get checkout_dontClosePage;

  /// No description provided for @checkout_duplicateBookingDesc.
  ///
  /// In en, this message translates to:
  /// **'Cancel your existing booking first, or go back and keep it.'**
  String get checkout_duplicateBookingDesc;

  /// No description provided for @checkout_duplicateBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'You already have a booking at {hotel} for overlapping dates.'**
  String checkout_duplicateBookingTitle(Object hotel);

  /// No description provided for @checkout_errors_paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed. Please try again.'**
  String get checkout_errors_paymentFailed;

  /// No description provided for @checkout_errors_paymentProcessing.
  ///
  /// In en, this message translates to:
  /// **'Payment is processing. Check your trips shortly.'**
  String get checkout_errors_paymentProcessing;

  /// No description provided for @checkout_example.
  ///
  /// In en, this message translates to:
  /// **'e.g. {value}'**
  String checkout_example(Object value);

  /// No description provided for @checkout_failed_released.
  ///
  /// In en, this message translates to:
  /// **'You have not been charged — the hold on your card has been released.'**
  String get checkout_failed_released;

  /// No description provided for @checkout_failed_title.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t complete your booking'**
  String get checkout_failed_title;

  /// No description provided for @checkout_failed_tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get checkout_failed_tryAgain;

  /// No description provided for @checkout_failed_unknown.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t confirm whether your payment was taken. Check your trips or contact support before trying again.'**
  String get checkout_failed_unknown;

  /// No description provided for @checkout_finalizingDetails.
  ///
  /// In en, this message translates to:
  /// **'Finalizing booking details...'**
  String get checkout_finalizingDetails;

  /// No description provided for @checkout_flight_adultN.
  ///
  /// In en, this message translates to:
  /// **'ADULT {n}'**
  String checkout_flight_adultN(Object n);

  /// No description provided for @checkout_flight_cardHeld.
  ///
  /// In en, this message translates to:
  /// **'Your card is authorised now and charged only once the airline confirms your ticket. If it can\'t, the hold is released and you pay nothing.'**
  String get checkout_flight_cardHeld;

  /// No description provided for @checkout_flight_contactHint.
  ///
  /// In en, this message translates to:
  /// **'Your e-ticket is sent here, and the airline uses this number for flight changes.'**
  String get checkout_flight_contactHint;

  /// No description provided for @checkout_flight_contactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact details'**
  String get checkout_flight_contactTitle;

  /// No description provided for @checkout_flight_countryNoResults.
  ///
  /// In en, this message translates to:
  /// **'No countries found'**
  String get checkout_flight_countryNoResults;

  /// No description provided for @checkout_flight_countryPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select country'**
  String get checkout_flight_countryPlaceholder;

  /// No description provided for @checkout_flight_duplicateBody.
  ///
  /// In en, this message translates to:
  /// **'Your booking departing {route} on {date} is still active.'**
  String checkout_flight_duplicateBody(Object route, Object date);

  /// No description provided for @checkout_flight_duplicateClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get checkout_flight_duplicateClose;

  /// No description provided for @checkout_flight_duplicateHint.
  ///
  /// In en, this message translates to:
  /// **'Check it before you book another flight on the same date.'**
  String get checkout_flight_duplicateHint;

  /// No description provided for @checkout_flight_duplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'You already have a flight that day'**
  String get checkout_flight_duplicateTitle;

  /// No description provided for @checkout_flight_genderPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select gender'**
  String get checkout_flight_genderPlaceholder;

  /// No description provided for @checkout_flight_infantN.
  ///
  /// In en, this message translates to:
  /// **'INFANT {n}'**
  String checkout_flight_infantN(Object n);

  /// No description provided for @checkout_flight_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter names exactly as they appear on the passport.'**
  String get checkout_flight_nameHint;

  /// No description provided for @checkout_flight_needsReview_description.
  ///
  /// In en, this message translates to:
  /// **'Our team is finishing this booking with the airline. We\'ll email you as soon as your ticket is confirmed.'**
  String get checkout_flight_needsReview_description;

  /// No description provided for @checkout_flight_needsReview_title.
  ///
  /// In en, this message translates to:
  /// **'We\'re confirming this with the airline'**
  String get checkout_flight_needsReview_title;

  /// No description provided for @checkout_flight_offerExpired.
  ///
  /// In en, this message translates to:
  /// **'This fare sold out before the airline could confirm it. You have not been charged — the hold on your card has been released. Please search again.'**
  String get checkout_flight_offerExpired;

  /// No description provided for @checkout_flight_passportPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. P1234567A'**
  String get checkout_flight_passportPlaceholder;

  /// No description provided for @checkout_flight_passportTitle.
  ///
  /// In en, this message translates to:
  /// **'Passport details'**
  String get checkout_flight_passportTitle;

  /// No description provided for @checkout_flight_priceChanged.
  ///
  /// In en, this message translates to:
  /// **'The fare changed from {was} to {now} before the airline could confirm it. You have not been charged — the hold on your card has been released. Submit your details again to book at the new fare.'**
  String checkout_flight_priceChanged(Object was, Object now);

  /// No description provided for @checkout_flight_receipt_allSet.
  ///
  /// In en, this message translates to:
  /// **'You’re all set'**
  String get checkout_flight_receipt_allSet;

  /// No description provided for @checkout_flight_receipt_approxTotal.
  ///
  /// In en, this message translates to:
  /// **'Approx. in {currency}'**
  String checkout_flight_receipt_approxTotal(Object currency);

  /// No description provided for @checkout_flight_receipt_arriveAt.
  ///
  /// In en, this message translates to:
  /// **'Arrive At'**
  String get checkout_flight_receipt_arriveAt;

  /// No description provided for @checkout_flight_receipt_carryOnBag.
  ///
  /// In en, this message translates to:
  /// **'1 carry-on bag'**
  String get checkout_flight_receipt_carryOnBag;

  /// No description provided for @checkout_flight_receipt_checkedBagsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# checked bag} other {# checked bags}}'**
  String checkout_flight_receipt_checkedBagsCount(num count);

  /// No description provided for @checkout_flight_receipt_confirmedBadge.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get checkout_flight_receipt_confirmedBadge;

  /// No description provided for @checkout_flight_receipt_confirmedSentTo.
  ///
  /// In en, this message translates to:
  /// **'Your flight to {destination} is confirmed, flight details and receipt has been sent to {email}'**
  String checkout_flight_receipt_confirmedSentTo(
    Object destination,
    Object email,
  );

  /// No description provided for @checkout_flight_receipt_confirmedToDestination.
  ///
  /// In en, this message translates to:
  /// **'Your flight to {destination} is confirmed.'**
  String checkout_flight_receipt_confirmedToDestination(Object destination);

  /// No description provided for @checkout_flight_receipt_contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get checkout_flight_receipt_contact;

  /// No description provided for @checkout_flight_receipt_copyReference.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get checkout_flight_receipt_copyReference;

  /// No description provided for @checkout_flight_receipt_copyReferenceDone.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get checkout_flight_receipt_copyReferenceDone;

  /// No description provided for @checkout_flight_receipt_departFrom.
  ///
  /// In en, this message translates to:
  /// **'Depart From'**
  String get checkout_flight_receipt_departFrom;

  /// No description provided for @checkout_flight_receipt_fareLine.
  ///
  /// In en, this message translates to:
  /// **'Fare · {count, plural, one {# passenger} other {# passengers}}'**
  String checkout_flight_receipt_fareLine(num count);

  /// No description provided for @checkout_flight_receipt_includedLabel.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get checkout_flight_receipt_includedLabel;

  /// No description provided for @checkout_flight_receipt_loadingItinerary.
  ///
  /// In en, this message translates to:
  /// **'Loading your flight details…'**
  String get checkout_flight_receipt_loadingItinerary;

  /// No description provided for @checkout_flight_receipt_next_hotel.
  ///
  /// In en, this message translates to:
  /// **'Book a hotel'**
  String get checkout_flight_receipt_next_hotel;

  /// No description provided for @checkout_flight_receipt_next_hotelLine.
  ///
  /// In en, this message translates to:
  /// **'Stays in {city} · {dates}'**
  String checkout_flight_receipt_next_hotelLine(Object city, Object dates);

  /// No description provided for @checkout_flight_receipt_next_teeTime.
  ///
  /// In en, this message translates to:
  /// **'Book a tee time'**
  String get checkout_flight_receipt_next_teeTime;

  /// No description provided for @checkout_flight_receipt_next_teeTimeAnywhere.
  ///
  /// In en, this message translates to:
  /// **'Browse our golf courses'**
  String get checkout_flight_receipt_next_teeTimeAnywhere;

  /// No description provided for @checkout_flight_receipt_next_teeTimeLine.
  ///
  /// In en, this message translates to:
  /// **'Golf courses in {city}'**
  String checkout_flight_receipt_next_teeTimeLine(Object city);

  /// No description provided for @checkout_flight_receipt_next_title.
  ///
  /// In en, this message translates to:
  /// **'Complete your trip'**
  String get checkout_flight_receipt_next_title;

  /// No description provided for @checkout_flight_receipt_outbound.
  ///
  /// In en, this message translates to:
  /// **'Outbound'**
  String get checkout_flight_receipt_outbound;

  /// No description provided for @checkout_flight_receipt_paidBadge.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get checkout_flight_receipt_paidBadge;

  /// No description provided for @checkout_flight_receipt_passengerSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Passengers'**
  String get checkout_flight_receipt_passengerSectionTitle;

  /// No description provided for @checkout_flight_receipt_passengersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# passenger} other {# passengers}}'**
  String checkout_flight_receipt_passengersCount(num count);

  /// No description provided for @checkout_flight_receipt_paymentProcessedSecurely.
  ///
  /// In en, this message translates to:
  /// **'Payment processed securely by Stripe.'**
  String get checkout_flight_receipt_paymentProcessedSecurely;

  /// No description provided for @checkout_flight_receipt_paymentSummary.
  ///
  /// In en, this message translates to:
  /// **'Payment Summary'**
  String get checkout_flight_receipt_paymentSummary;

  /// No description provided for @checkout_flight_receipt_refundable.
  ///
  /// In en, this message translates to:
  /// **'Refundable (fees may apply)'**
  String get checkout_flight_receipt_refundable;

  /// No description provided for @checkout_flight_receipt_return.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get checkout_flight_receipt_return;

  /// No description provided for @checkout_flight_receipt_taxesAndFees.
  ///
  /// In en, this message translates to:
  /// **'Taxes & fees'**
  String get checkout_flight_receipt_taxesAndFees;

  /// No description provided for @checkout_flight_receipt_terminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get checkout_flight_receipt_terminal;

  /// No description provided for @checkout_flight_receipt_viewBookings.
  ///
  /// In en, this message translates to:
  /// **'View Bookings'**
  String get checkout_flight_receipt_viewBookings;

  /// No description provided for @checkout_flight_settling_description.
  ///
  /// In en, this message translates to:
  /// **'The airline is confirming your ticket. This can take a few minutes — it will appear in your trips as soon as it\'s issued.'**
  String get checkout_flight_settling_description;

  /// No description provided for @checkout_flight_summary_arrivingAt.
  ///
  /// In en, this message translates to:
  /// **'Arriving at'**
  String get checkout_flight_summary_arrivingAt;

  /// No description provided for @checkout_flight_summary_departing.
  ///
  /// In en, this message translates to:
  /// **'Departing'**
  String get checkout_flight_summary_departing;

  /// No description provided for @checkout_flight_summary_fareDetails.
  ///
  /// In en, this message translates to:
  /// **'Fare details'**
  String get checkout_flight_summary_fareDetails;

  /// No description provided for @checkout_flight_summary_hideItineraries.
  ///
  /// In en, this message translates to:
  /// **'Hide flight itineraries'**
  String get checkout_flight_summary_hideItineraries;

  /// No description provided for @checkout_flight_summary_noCarryOnBag.
  ///
  /// In en, this message translates to:
  /// **'No carry-on bag'**
  String get checkout_flight_summary_noCarryOnBag;

  /// No description provided for @checkout_flight_summary_noCheckedBag.
  ///
  /// In en, this message translates to:
  /// **'No checked bag'**
  String get checkout_flight_summary_noCheckedBag;

  /// No description provided for @checkout_flight_summary_showItineraries.
  ///
  /// In en, this message translates to:
  /// **'Show flight itineraries'**
  String get checkout_flight_summary_showItineraries;

  /// No description provided for @checkout_flight_summary_totalPrice.
  ///
  /// In en, this message translates to:
  /// **'total price'**
  String get checkout_flight_summary_totalPrice;

  /// No description provided for @checkout_flight_whosFlying.
  ///
  /// In en, this message translates to:
  /// **'Who\'s flying?'**
  String get checkout_flight_whosFlying;

  /// No description provided for @checkout_goBack.
  ///
  /// In en, this message translates to:
  /// **'← Go back'**
  String get checkout_goBack;

  /// No description provided for @checkout_goBackBtn.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get checkout_goBackBtn;

  /// No description provided for @checkout_guestDetails.
  ///
  /// In en, this message translates to:
  /// **'Guest details'**
  String get checkout_guestDetails;

  /// No description provided for @checkout_guestLabel.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get checkout_guestLabel;

  /// No description provided for @checkout_guestsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# guest} other {# guests}}'**
  String checkout_guestsCount(num count);

  /// No description provided for @checkout_keepExistingBooking.
  ///
  /// In en, this message translates to:
  /// **'Keep existing booking'**
  String get checkout_keepExistingBooking;

  /// No description provided for @checkout_loadingPaymentForm.
  ///
  /// In en, this message translates to:
  /// **'Loading payment form...'**
  String get checkout_loadingPaymentForm;

  /// No description provided for @checkout_modifyBooking.
  ///
  /// In en, this message translates to:
  /// **'Modify booking'**
  String get checkout_modifyBooking;

  /// No description provided for @checkout_multiRoom_description.
  ///
  /// In en, this message translates to:
  /// **'Booking several rooms at once isn\'t available yet — this checkout is for a single room for your whole party. Please book rooms separately for now.'**
  String get checkout_multiRoom_description;

  /// No description provided for @checkout_multiRoom_title.
  ///
  /// In en, this message translates to:
  /// **'One room at a time'**
  String get checkout_multiRoom_title;

  /// No description provided for @checkout_needsReview_description.
  ///
  /// In en, this message translates to:
  /// **'Your payment hasn\'t been taken yet. We\'ll email you as soon as it\'s confirmed, or release the hold on your card if it isn\'t.'**
  String get checkout_needsReview_description;

  /// No description provided for @checkout_needsReview_title.
  ///
  /// In en, this message translates to:
  /// **'We\'re confirming this with the hotel'**
  String get checkout_needsReview_title;

  /// No description provided for @checkout_nightsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# night} other {# nights}}'**
  String checkout_nightsCount(num count);

  /// No description provided for @checkout_notPayableOnline_chooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose another room'**
  String get checkout_notPayableOnline_chooseAnother;

  /// No description provided for @checkout_notPayableOnline_description.
  ///
  /// In en, this message translates to:
  /// **'The hotel collects payment for this rate itself. Choose a different room to book and pay here.'**
  String get checkout_notPayableOnline_description;

  /// No description provided for @checkout_notPayableOnline_title.
  ///
  /// In en, this message translates to:
  /// **'This room can\'t be paid for online'**
  String get checkout_notPayableOnline_title;

  /// No description provided for @checkout_payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String checkout_payNow(Object amount);

  /// No description provided for @checkout_paymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Payment details'**
  String get checkout_paymentDetails;

  /// No description provided for @checkout_paymentDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Details'**
  String get checkout_paymentDetailsTitle;

  /// No description provided for @checkout_paymentInfo.
  ///
  /// In en, this message translates to:
  /// **'Payment info'**
  String get checkout_paymentInfo;

  /// No description provided for @checkout_paymentSecure.
  ///
  /// In en, this message translates to:
  /// **'Your payment information is encrypted and never stored on our servers.'**
  String get checkout_paymentSecure;

  /// No description provided for @checkout_payment_card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get checkout_payment_card;

  /// No description provided for @checkout_payment_cardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card number'**
  String get checkout_payment_cardNumber;

  /// No description provided for @checkout_payment_countries_ID.
  ///
  /// In en, this message translates to:
  /// **'Indonesia'**
  String get checkout_payment_countries_ID;

  /// No description provided for @checkout_payment_countries_JP.
  ///
  /// In en, this message translates to:
  /// **'Japan'**
  String get checkout_payment_countries_JP;

  /// No description provided for @checkout_payment_countries_KR.
  ///
  /// In en, this message translates to:
  /// **'South Korea'**
  String get checkout_payment_countries_KR;

  /// No description provided for @checkout_payment_countries_MY.
  ///
  /// In en, this message translates to:
  /// **'Malaysia'**
  String get checkout_payment_countries_MY;

  /// No description provided for @checkout_payment_countries_PH.
  ///
  /// In en, this message translates to:
  /// **'Philippines'**
  String get checkout_payment_countries_PH;

  /// No description provided for @checkout_payment_countries_SG.
  ///
  /// In en, this message translates to:
  /// **'Singapore'**
  String get checkout_payment_countries_SG;

  /// No description provided for @checkout_payment_countries_TH.
  ///
  /// In en, this message translates to:
  /// **'Thailand'**
  String get checkout_payment_countries_TH;

  /// No description provided for @checkout_payment_countries_US.
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get checkout_payment_countries_US;

  /// No description provided for @checkout_payment_countries_VN.
  ///
  /// In en, this message translates to:
  /// **'Vietnam'**
  String get checkout_payment_countries_VN;

  /// No description provided for @checkout_payment_country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get checkout_payment_country;

  /// No description provided for @checkout_payment_mmYY.
  ///
  /// In en, this message translates to:
  /// **'MM / YY'**
  String get checkout_payment_mmYY;

  /// No description provided for @checkout_payment_payeeFirstName.
  ///
  /// In en, this message translates to:
  /// **'Payee First Name'**
  String get checkout_payment_payeeFirstName;

  /// No description provided for @checkout_payment_payeeLastName.
  ///
  /// In en, this message translates to:
  /// **'Payee Last Name'**
  String get checkout_payment_payeeLastName;

  /// No description provided for @checkout_payment_paymentInformation.
  ///
  /// In en, this message translates to:
  /// **'Payment Information'**
  String get checkout_payment_paymentInformation;

  /// No description provided for @checkout_payment_securedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your payment information is secured.'**
  String get checkout_payment_securedMessage;

  /// No description provided for @checkout_payment_securityCode.
  ///
  /// In en, this message translates to:
  /// **'Security code'**
  String get checkout_payment_securityCode;

  /// No description provided for @checkout_pickDatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Pick check-in and check-out to continue.'**
  String get checkout_pickDatesDescription;

  /// No description provided for @checkout_planAnotherTrip.
  ///
  /// In en, this message translates to:
  /// **'Plan another trip'**
  String get checkout_planAnotherTrip;

  /// No description provided for @checkout_priceBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Price breakdown'**
  String get checkout_priceBreakdown;

  /// No description provided for @checkout_priceChanged_backToSearch.
  ///
  /// In en, this message translates to:
  /// **'Back to search'**
  String get checkout_priceChanged_backToSearch;

  /// No description provided for @checkout_priceChanged_description.
  ///
  /// In en, this message translates to:
  /// **'The price for this room changed between when you selected it and when we tried to confirm your booking.'**
  String get checkout_priceChanged_description;

  /// No description provided for @checkout_priceChanged_newPrice.
  ///
  /// In en, this message translates to:
  /// **'New price'**
  String get checkout_priceChanged_newPrice;

  /// No description provided for @checkout_priceChanged_originalPrice.
  ///
  /// In en, this message translates to:
  /// **'Original price'**
  String get checkout_priceChanged_originalPrice;

  /// No description provided for @checkout_priceChanged_refundNotice.
  ///
  /// In en, this message translates to:
  /// **'Your payment of {amount} has been automatically refunded. It may take 3–5 business days to appear on your statement.'**
  String checkout_priceChanged_refundNotice(Object amount);

  /// No description provided for @checkout_priceChanged_title.
  ///
  /// In en, this message translates to:
  /// **'Price has changed'**
  String get checkout_priceChanged_title;

  /// No description provided for @checkout_priceMoved_accept.
  ///
  /// In en, this message translates to:
  /// **'Continue at the new price'**
  String get checkout_priceMoved_accept;

  /// No description provided for @checkout_priceMoved_chooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose another room'**
  String get checkout_priceMoved_chooseAnother;

  /// No description provided for @checkout_priceMoved_down.
  ///
  /// In en, this message translates to:
  /// **'Good news — this room now costs less than when you chose it.'**
  String get checkout_priceMoved_down;

  /// No description provided for @checkout_priceMoved_now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get checkout_priceMoved_now;

  /// No description provided for @checkout_priceMoved_refreshing.
  ///
  /// In en, this message translates to:
  /// **'Checking the latest price…'**
  String get checkout_priceMoved_refreshing;

  /// No description provided for @checkout_priceMoved_title.
  ///
  /// In en, this message translates to:
  /// **'The price has changed'**
  String get checkout_priceMoved_title;

  /// No description provided for @checkout_priceMoved_up.
  ///
  /// In en, this message translates to:
  /// **'This room now costs more than when you chose it.'**
  String get checkout_priceMoved_up;

  /// No description provided for @checkout_priceMoved_was.
  ///
  /// In en, this message translates to:
  /// **'Was'**
  String get checkout_priceMoved_was;

  /// No description provided for @checkout_promos_applied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get checkout_promos_applied;

  /// No description provided for @checkout_promos_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get checkout_promos_apply;

  /// No description provided for @checkout_promos_availableForBooking.
  ///
  /// In en, this message translates to:
  /// **'Available promos for this booking'**
  String get checkout_promos_availableForBooking;

  /// No description provided for @checkout_promos_availablePromos.
  ///
  /// In en, this message translates to:
  /// **'Available promos'**
  String get checkout_promos_availablePromos;

  /// No description provided for @checkout_promos_failedToApply.
  ///
  /// In en, this message translates to:
  /// **'Failed to apply promo. Please try again.'**
  String get checkout_promos_failedToApply;

  /// No description provided for @checkout_promos_hotelDeal.
  ///
  /// In en, this message translates to:
  /// **'Hotel Deal'**
  String get checkout_promos_hotelDeal;

  /// No description provided for @checkout_promos_loadingPromos.
  ///
  /// In en, this message translates to:
  /// **'Loading available promos...'**
  String get checkout_promos_loadingPromos;

  /// No description provided for @checkout_promos_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get checkout_promos_location;

  /// No description provided for @checkout_promos_minAmount.
  ///
  /// In en, this message translates to:
  /// **'Min. {amount}'**
  String checkout_promos_minAmount(Object amount);

  /// No description provided for @checkout_promos_newUser.
  ///
  /// In en, this message translates to:
  /// **'New User'**
  String get checkout_promos_newUser;

  /// No description provided for @checkout_promos_off.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get checkout_promos_off;

  /// No description provided for @checkout_promos_promo.
  ///
  /// In en, this message translates to:
  /// **'Promo'**
  String get checkout_promos_promo;

  /// No description provided for @checkout_promos_seasonal.
  ///
  /// In en, this message translates to:
  /// **'Seasonal'**
  String get checkout_promos_seasonal;

  /// No description provided for @checkout_promos_until.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String checkout_promos_until(Object date);

  /// No description provided for @checkout_promos_upTo.
  ///
  /// In en, this message translates to:
  /// **'Up to {amount}'**
  String checkout_promos_upTo(Object amount);

  /// No description provided for @checkout_rating_average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get checkout_rating_average;

  /// No description provided for @checkout_rating_exceptional.
  ///
  /// In en, this message translates to:
  /// **'Exceptional'**
  String get checkout_rating_exceptional;

  /// No description provided for @checkout_rating_fabulous.
  ///
  /// In en, this message translates to:
  /// **'Fabulous'**
  String get checkout_rating_fabulous;

  /// No description provided for @checkout_rating_good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get checkout_rating_good;

  /// No description provided for @checkout_rating_pleasant.
  ///
  /// In en, this message translates to:
  /// **'Pleasant'**
  String get checkout_rating_pleasant;

  /// No description provided for @checkout_rating_veryGood.
  ///
  /// In en, this message translates to:
  /// **'Very Good'**
  String get checkout_rating_veryGood;

  /// No description provided for @checkout_receiptSent.
  ///
  /// In en, this message translates to:
  /// **'Your booking is confirmed. A receipt has been sent to {email}.'**
  String checkout_receiptSent(Object email);

  /// No description provided for @checkout_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get checkout_retry;

  /// No description provided for @checkout_roomFallback.
  ///
  /// In en, this message translates to:
  /// **'Standard Room'**
  String get checkout_roomFallback;

  /// No description provided for @checkout_searchAvailableRooms.
  ///
  /// In en, this message translates to:
  /// **'Search available rooms →'**
  String get checkout_searchAvailableRooms;

  /// No description provided for @checkout_secureYourBooking.
  ///
  /// In en, this message translates to:
  /// **'Secure your booking'**
  String get checkout_secureYourBooking;

  /// No description provided for @checkout_securedByStripe.
  ///
  /// In en, this message translates to:
  /// **'Secured by Stripe'**
  String get checkout_securedByStripe;

  /// No description provided for @checkout_securingReservation.
  ///
  /// In en, this message translates to:
  /// **'Securing your reservation...'**
  String get checkout_securingReservation;

  /// No description provided for @checkout_selectYourDates.
  ///
  /// In en, this message translates to:
  /// **'Select your dates'**
  String get checkout_selectYourDates;

  /// No description provided for @checkout_serviceFee.
  ///
  /// In en, this message translates to:
  /// **'Service fee'**
  String get checkout_serviceFee;

  /// No description provided for @checkout_settling_checkTrips.
  ///
  /// In en, this message translates to:
  /// **'View my trips'**
  String get checkout_settling_checkTrips;

  /// No description provided for @checkout_settling_description.
  ///
  /// In en, this message translates to:
  /// **'The hotel is confirming your reservation. Please keep this page open.'**
  String get checkout_settling_description;

  /// No description provided for @checkout_settling_doNotPayAgain.
  ///
  /// In en, this message translates to:
  /// **'Please don\'t pay again — you won\'t be charged twice.'**
  String get checkout_settling_doNotPayAgain;

  /// No description provided for @checkout_settling_title.
  ///
  /// In en, this message translates to:
  /// **'Confirming your booking'**
  String get checkout_settling_title;

  /// No description provided for @checkout_signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get checkout_signIn;

  /// No description provided for @checkout_signInArrow.
  ///
  /// In en, this message translates to:
  /// **'Sign in →'**
  String get checkout_signInArrow;

  /// No description provided for @checkout_signInBannerDesc.
  ///
  /// In en, this message translates to:
  /// **'You\'ll receive booking confirmation and updates via email.'**
  String get checkout_signInBannerDesc;

  /// No description provided for @checkout_signInToComplete.
  ///
  /// In en, this message translates to:
  /// **'Sign in to complete your booking'**
  String get checkout_signInToComplete;

  /// No description provided for @checkout_specialRequests_placeholder.
  ///
  /// In en, this message translates to:
  /// **'The property will do its best to arrange it.'**
  String get checkout_specialRequests_placeholder;

  /// No description provided for @checkout_specialRequests_title.
  ///
  /// In en, this message translates to:
  /// **'Any special requests?'**
  String get checkout_specialRequests_title;

  /// No description provided for @checkout_steps_confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get checkout_steps_confirmed;

  /// No description provided for @checkout_steps_details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get checkout_steps_details;

  /// No description provided for @checkout_steps_payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get checkout_steps_payment;

  /// No description provided for @checkout_steps_verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get checkout_steps_verification;

  /// No description provided for @checkout_stripe_completePayment.
  ///
  /// In en, this message translates to:
  /// **'Complete Payment'**
  String get checkout_stripe_completePayment;

  /// No description provided for @checkout_stripe_loadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the payment form. Please refresh and try again.'**
  String get checkout_stripe_loadError;

  /// No description provided for @checkout_stripe_payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get checkout_stripe_payNow;

  /// No description provided for @checkout_stripe_processing.
  ///
  /// In en, this message translates to:
  /// **'Payment is processing...'**
  String get checkout_stripe_processing;

  /// No description provided for @checkout_stripe_unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get checkout_stripe_unexpectedError;

  /// No description provided for @checkout_submit_continueToPayment.
  ///
  /// In en, this message translates to:
  /// **'Continue to Payment • {amount}'**
  String checkout_submit_continueToPayment(Object amount);

  /// No description provided for @checkout_submit_goBackDifferentHotel.
  ///
  /// In en, this message translates to:
  /// **'Go back & choose a different hotel'**
  String get checkout_submit_goBackDifferentHotel;

  /// No description provided for @checkout_submit_goBackReselect.
  ///
  /// In en, this message translates to:
  /// **'Go back & reselect room'**
  String get checkout_submit_goBackReselect;

  /// No description provided for @checkout_submit_hotelUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Hotel temporarily unavailable'**
  String get checkout_submit_hotelUnavailable;

  /// No description provided for @checkout_submit_hotelUnavailableDesc.
  ///
  /// In en, this message translates to:
  /// **'This hotel cannot be booked right now. Please go back and choose a different hotel.'**
  String get checkout_submit_hotelUnavailableDesc;

  /// No description provided for @checkout_submit_processingBooking.
  ///
  /// In en, this message translates to:
  /// **'Processing Your Booking...'**
  String get checkout_submit_processingBooking;

  /// No description provided for @checkout_submit_sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Room session expired'**
  String get checkout_submit_sessionExpired;

  /// No description provided for @checkout_submit_sessionExpiredDesc.
  ///
  /// In en, this message translates to:
  /// **'Your room hold has expired. Go back and reselect the room to get a fresh session — you can pick the same room again.'**
  String get checkout_submit_sessionExpiredDesc;

  /// No description provided for @checkout_submit_signInToComplete.
  ///
  /// In en, this message translates to:
  /// **'Sign In to Complete Booking'**
  String get checkout_submit_signInToComplete;

  /// No description provided for @checkout_submit_verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed — see error above'**
  String get checkout_submit_verificationFailed;

  /// No description provided for @checkout_submit_verifyingPrice.
  ///
  /// In en, this message translates to:
  /// **'Verifying Price...'**
  String get checkout_submit_verifyingPrice;

  /// No description provided for @checkout_submit_verifyingRoom.
  ///
  /// In en, this message translates to:
  /// **'Verifying Room...'**
  String get checkout_submit_verifyingRoom;

  /// No description provided for @checkout_submit_waitingMessage.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we confirm your reservation with the hotel...'**
  String get checkout_submit_waitingMessage;

  /// No description provided for @checkout_submit_waitingWarning.
  ///
  /// In en, this message translates to:
  /// **'This may take up to 30 seconds. Do not close this page.'**
  String get checkout_submit_waitingWarning;

  /// No description provided for @checkout_success_bookFlightBundle.
  ///
  /// In en, this message translates to:
  /// **'Book your flight now and get a bundle discount on your total.'**
  String get checkout_success_bookFlightBundle;

  /// No description provided for @checkout_success_bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed! 🎉'**
  String get checkout_success_bookingConfirmed;

  /// No description provided for @checkout_success_bookingId.
  ///
  /// In en, this message translates to:
  /// **'Booking ID'**
  String get checkout_success_bookingId;

  /// No description provided for @checkout_success_bundleDeal.
  ///
  /// In en, this message translates to:
  /// **'✦ Bundle Deal'**
  String get checkout_success_bundleDeal;

  /// No description provided for @checkout_success_bundleDiscountApplied.
  ///
  /// In en, this message translates to:
  /// **'Bundle discount applied'**
  String get checkout_success_bundleDiscountApplied;

  /// No description provided for @checkout_success_checkEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email for booking details and updates'**
  String get checkout_success_checkEmail;

  /// No description provided for @checkout_success_checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get checkout_success_checkIn;

  /// No description provided for @checkout_success_checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get checkout_success_checkOut;

  /// No description provided for @checkout_success_confirmationSentTo.
  ///
  /// In en, this message translates to:
  /// **'Confirmation sent to'**
  String get checkout_success_confirmationSentTo;

  /// No description provided for @checkout_success_downloadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Download receipt'**
  String get checkout_success_downloadReceipt;

  /// No description provided for @checkout_success_emailInfo.
  ///
  /// In en, this message translates to:
  /// **'Your booking confirmation will be emailed to you within a few minutes.'**
  String get checkout_success_emailInfo;

  /// No description provided for @checkout_success_flightHotelBundle.
  ///
  /// In en, this message translates to:
  /// **'Flight + Hotel Bundle'**
  String get checkout_success_flightHotelBundle;

  /// No description provided for @checkout_success_freeCancellationInfo.
  ///
  /// In en, this message translates to:
  /// **'If your booking is free cancellation, you can cancel or modify via My Trips.'**
  String get checkout_success_freeCancellationInfo;

  /// No description provided for @checkout_success_hotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get checkout_success_hotel;

  /// No description provided for @checkout_success_hotelCheckInInfo.
  ///
  /// In en, this message translates to:
  /// **'Present your booking ID at the hotel reception upon arrival.'**
  String get checkout_success_hotelCheckInInfo;

  /// No description provided for @checkout_success_hotelSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your hotel has been booked successfully.'**
  String get checkout_success_hotelSuccess;

  /// No description provided for @checkout_success_needFlight.
  ///
  /// In en, this message translates to:
  /// **'Need a flight to {destination}?'**
  String checkout_success_needFlight(Object destination);

  /// No description provided for @checkout_success_openingDestination.
  ///
  /// In en, this message translates to:
  /// **'Opening your destination…'**
  String get checkout_success_openingDestination;

  /// No description provided for @checkout_success_returnToHome.
  ///
  /// In en, this message translates to:
  /// **'Return to Home'**
  String get checkout_success_returnToHome;

  /// No description provided for @checkout_success_room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get checkout_success_room;

  /// No description provided for @checkout_success_saveUpTo.
  ///
  /// In en, this message translates to:
  /// **'Save up to 8%'**
  String get checkout_success_saveUpTo;

  /// No description provided for @checkout_success_saved.
  ///
  /// In en, this message translates to:
  /// **'{amount} saved'**
  String checkout_success_saved(Object amount);

  /// No description provided for @checkout_success_searchFlightsAndBundle.
  ///
  /// In en, this message translates to:
  /// **'Search flights & bundle'**
  String get checkout_success_searchFlightsAndBundle;

  /// No description provided for @checkout_success_sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get checkout_success_sent;

  /// No description provided for @checkout_success_stayDuration.
  ///
  /// In en, this message translates to:
  /// **'Stay Duration'**
  String get checkout_success_stayDuration;

  /// No description provided for @checkout_success_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get checkout_success_total;

  /// No description provided for @checkout_success_viewMyTrips.
  ///
  /// In en, this message translates to:
  /// **'View My Trips'**
  String get checkout_success_viewMyTrips;

  /// No description provided for @checkout_success_whatsNext.
  ///
  /// In en, this message translates to:
  /// **'What\'s Next'**
  String get checkout_success_whatsNext;

  /// No description provided for @checkout_summary_adult.
  ///
  /// In en, this message translates to:
  /// **'Adult'**
  String get checkout_summary_adult;

  /// No description provided for @checkout_summary_adults.
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get checkout_summary_adults;

  /// No description provided for @checkout_summary_averagePerNight.
  ///
  /// In en, this message translates to:
  /// **'average per night'**
  String get checkout_summary_averagePerNight;

  /// No description provided for @checkout_summary_calculatingPerNight.
  ///
  /// In en, this message translates to:
  /// **'Calculated per night...'**
  String get checkout_summary_calculatingPerNight;

  /// No description provided for @checkout_summary_checkInAndOut.
  ///
  /// In en, this message translates to:
  /// **'Check-in & Check-out'**
  String get checkout_summary_checkInAndOut;

  /// No description provided for @checkout_summary_checkInLabel.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get checkout_summary_checkInLabel;

  /// No description provided for @checkout_summary_checkOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get checkout_summary_checkOutLabel;

  /// No description provided for @checkout_summary_child.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get checkout_summary_child;

  /// No description provided for @checkout_summary_children.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get checkout_summary_children;

  /// No description provided for @checkout_summary_dates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get checkout_summary_dates;

  /// No description provided for @checkout_summary_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get checkout_summary_edit;

  /// No description provided for @checkout_summary_fetchingPolicy.
  ///
  /// In en, this message translates to:
  /// **'Fetching cancellation policy…'**
  String get checkout_summary_fetchingPolicy;

  /// No description provided for @checkout_summary_flight.
  ///
  /// In en, this message translates to:
  /// **'Flight'**
  String get checkout_summary_flight;

  /// No description provided for @checkout_summary_freeCancellationBefore.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation before {date}'**
  String checkout_summary_freeCancellationBefore(Object date);

  /// No description provided for @checkout_summary_freeCancellationShort.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation'**
  String get checkout_summary_freeCancellationShort;

  /// No description provided for @checkout_summary_guests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get checkout_summary_guests;

  /// No description provided for @checkout_summary_included.
  ///
  /// In en, this message translates to:
  /// **'included'**
  String get checkout_summary_included;

  /// No description provided for @checkout_summary_includedInPrice.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get checkout_summary_includedInPrice;

  /// No description provided for @checkout_summary_night.
  ///
  /// In en, this message translates to:
  /// **'night'**
  String get checkout_summary_night;

  /// No description provided for @checkout_summary_nights.
  ///
  /// In en, this message translates to:
  /// **'nights'**
  String get checkout_summary_nights;

  /// No description provided for @checkout_summary_nonRefundable.
  ///
  /// In en, this message translates to:
  /// **'Non-refundable'**
  String get checkout_summary_nonRefundable;

  /// No description provided for @checkout_summary_priceDetails.
  ///
  /// In en, this message translates to:
  /// **'Price details'**
  String get checkout_summary_priceDetails;

  /// No description provided for @checkout_summary_promoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo: {code}'**
  String checkout_summary_promoCode(Object code);

  /// No description provided for @checkout_summary_room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get checkout_summary_room;

  /// No description provided for @checkout_summary_roomConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Room Confirmed'**
  String get checkout_summary_roomConfirmed;

  /// No description provided for @checkout_summary_roomNights.
  ///
  /// In en, this message translates to:
  /// **'1 room × {nights} {count}'**
  String checkout_summary_roomNights(Object nights, Object count);

  /// No description provided for @checkout_summary_serviceFee.
  ///
  /// In en, this message translates to:
  /// **'Platform service fee'**
  String get checkout_summary_serviceFee;

  /// No description provided for @checkout_summary_taxes.
  ///
  /// In en, this message translates to:
  /// **'Taxes'**
  String get checkout_summary_taxes;

  /// No description provided for @checkout_summary_termsNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Cancellation terms not provided by supplier — confirm with property before booking'**
  String get checkout_summary_termsNotProvided;

  /// No description provided for @checkout_summary_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get checkout_summary_total;

  /// No description provided for @checkout_summary_updateDates.
  ///
  /// In en, this message translates to:
  /// **'Update dates'**
  String get checkout_summary_updateDates;

  /// No description provided for @checkout_summary_youSave.
  ///
  /// In en, this message translates to:
  /// **'You save {amount} with this promo'**
  String checkout_summary_youSave(Object amount);

  /// No description provided for @checkout_summary_yourRoom.
  ///
  /// In en, this message translates to:
  /// **'Your Room'**
  String get checkout_summary_yourRoom;

  /// No description provided for @checkout_supplierDown_description.
  ///
  /// In en, this message translates to:
  /// **'Nothing is wrong with your booking — the hotel\'s system didn\'t answer. Please try again in a moment.'**
  String get checkout_supplierDown_description;

  /// No description provided for @checkout_supplierDown_retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get checkout_supplierDown_retry;

  /// No description provided for @checkout_supplierDown_title.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t reach the hotel just now'**
  String get checkout_supplierDown_title;

  /// No description provided for @checkout_title.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout_title;

  /// No description provided for @checkout_totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total paid'**
  String get checkout_totalPaid;

  /// No description provided for @checkout_unavailable_chooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose another room'**
  String get checkout_unavailable_chooseAnother;

  /// No description provided for @checkout_unavailable_description.
  ///
  /// In en, this message translates to:
  /// **'Someone else booked it, or the hotel closed it, while you were deciding. You have not been charged.'**
  String get checkout_unavailable_description;

  /// No description provided for @checkout_unavailable_title.
  ///
  /// In en, this message translates to:
  /// **'This room is no longer available'**
  String get checkout_unavailable_title;

  /// No description provided for @checkout_userDetails_age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get checkout_userDetails_age;

  /// No description provided for @checkout_userDetails_agePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'0–17'**
  String get checkout_userDetails_agePlaceholder;

  /// No description provided for @checkout_userDetails_childN.
  ///
  /// In en, this message translates to:
  /// **'CHILD {n}'**
  String checkout_userDetails_childN(Object n);

  /// No description provided for @checkout_userDetails_country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get checkout_userDetails_country;

  /// No description provided for @checkout_userDetails_dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get checkout_userDetails_dateOfBirth;

  /// No description provided for @checkout_userDetails_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get checkout_userDetails_email;

  /// No description provided for @checkout_userDetails_emailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get checkout_userDetails_emailPlaceholder;

  /// No description provided for @checkout_userDetails_firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get checkout_userDetails_firstName;

  /// No description provided for @checkout_userDetails_firstNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get checkout_userDetails_firstNamePlaceholder;

  /// No description provided for @checkout_userDetails_gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get checkout_userDetails_gender;

  /// No description provided for @checkout_userDetails_genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get checkout_userDetails_genderFemale;

  /// No description provided for @checkout_userDetails_genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get checkout_userDetails_genderMale;

  /// No description provided for @checkout_userDetails_guest1.
  ///
  /// In en, this message translates to:
  /// **'GUEST 1 (YOU)'**
  String get checkout_userDetails_guest1;

  /// No description provided for @checkout_userDetails_guestN.
  ///
  /// In en, this message translates to:
  /// **'GUEST {n}'**
  String checkout_userDetails_guestN(Object n);

  /// No description provided for @checkout_userDetails_lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get checkout_userDetails_lastName;

  /// No description provided for @checkout_userDetails_lastNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get checkout_userDetails_lastNamePlaceholder;

  /// No description provided for @checkout_userDetails_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get checkout_userDetails_no;

  /// No description provided for @checkout_userDetails_passportExpiry.
  ///
  /// In en, this message translates to:
  /// **'Passport expiry'**
  String get checkout_userDetails_passportExpiry;

  /// No description provided for @checkout_userDetails_passportNumber.
  ///
  /// In en, this message translates to:
  /// **'Passport number'**
  String get checkout_userDetails_passportNumber;

  /// No description provided for @checkout_userDetails_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get checkout_userDetails_phone;

  /// No description provided for @checkout_userDetails_phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get checkout_userDetails_phoneNumber;

  /// No description provided for @checkout_userDetails_phonePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get checkout_userDetails_phonePlaceholder;

  /// No description provided for @checkout_userDetails_title.
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get checkout_userDetails_title;

  /// No description provided for @checkout_userDetails_travelingForWork.
  ///
  /// In en, this message translates to:
  /// **'Traveling for work?'**
  String get checkout_userDetails_travelingForWork;

  /// No description provided for @checkout_userDetails_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get checkout_userDetails_yes;

  /// No description provided for @checkout_validation_ageInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an age from 0 to 17'**
  String get checkout_validation_ageInvalid;

  /// No description provided for @checkout_validation_bookingFailed.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmation failed: {message}. Your payment will be automatically refunded.'**
  String checkout_validation_bookingFailed(Object message);

  /// No description provided for @checkout_validation_emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get checkout_validation_emailInvalid;

  /// No description provided for @checkout_validation_fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get checkout_validation_fieldRequired;

  /// No description provided for @checkout_validation_firstNameRequired.
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get checkout_validation_firstNameRequired;

  /// No description provided for @checkout_validation_fixHighlighted.
  ///
  /// In en, this message translates to:
  /// **'Please fix the highlighted fields before continuing.'**
  String get checkout_validation_fixHighlighted;

  /// No description provided for @checkout_validation_invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Invalid booking price. Please retry.'**
  String get checkout_validation_invalidPrice;

  /// No description provided for @checkout_validation_lastNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get checkout_validation_lastNameRequired;

  /// No description provided for @checkout_validation_nameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Name must only contain letters'**
  String get checkout_validation_nameInvalid;

  /// No description provided for @checkout_validation_paymentSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment setup failed'**
  String get checkout_validation_paymentSetupFailed;

  /// No description provided for @checkout_validation_phoneDigitsOnly.
  ///
  /// In en, this message translates to:
  /// **'Phone number must contain digits only'**
  String get checkout_validation_phoneDigitsOnly;

  /// No description provided for @checkout_validation_phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get checkout_validation_phoneRequired;

  /// No description provided for @checkout_validation_priceVerifying.
  ///
  /// In en, this message translates to:
  /// **'Price is still being verified — please wait a moment and try again.'**
  String get checkout_validation_priceVerifying;

  /// No description provided for @checkout_validation_quoteExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Your price hold expires in 5 minutes — please complete your booking soon.'**
  String get checkout_validation_quoteExpiringSoon;

  /// No description provided for @checkout_validation_refreshingSession.
  ///
  /// In en, this message translates to:
  /// **'Refreshing your price hold…'**
  String get checkout_validation_refreshingSession;

  /// No description provided for @checkout_validation_required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get checkout_validation_required;

  /// No description provided for @checkout_validation_requiresAuth.
  ///
  /// In en, this message translates to:
  /// **'Authentication required'**
  String get checkout_validation_requiresAuth;

  /// No description provided for @checkout_validation_sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Booking session expired. Please go back and select the room again.'**
  String get checkout_validation_sessionExpired;

  /// No description provided for @checkout_validation_sessionExpiredCharge.
  ///
  /// In en, this message translates to:
  /// **'Your session expired during payment. Your card was charged — please contact support with payment reference: {id}'**
  String checkout_validation_sessionExpiredCharge(Object id);

  /// No description provided for @checkout_validation_specialRequestsTooLong.
  ///
  /// In en, this message translates to:
  /// **'Please keep special requests under 500 characters'**
  String get checkout_validation_specialRequestsTooLong;

  /// No description provided for @checkout_verifyingPayment.
  ///
  /// In en, this message translates to:
  /// **'Verifying payment...'**
  String get checkout_verifyingPayment;

  /// No description provided for @checkout_viewExistingBooking.
  ///
  /// In en, this message translates to:
  /// **'View existing booking'**
  String get checkout_viewExistingBooking;

  /// No description provided for @checkout_voucher_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get checkout_voucher_apply;

  /// No description provided for @checkout_voucher_enterPromoCode.
  ///
  /// In en, this message translates to:
  /// **'ENTER PROMO CODE'**
  String get checkout_voucher_enterPromoCode;

  /// No description provided for @checkout_voucher_failedToValidate.
  ///
  /// In en, this message translates to:
  /// **'Failed to validate voucher. Please try again.'**
  String get checkout_voucher_failedToValidate;

  /// No description provided for @checkout_voucher_havePromoCode.
  ///
  /// In en, this message translates to:
  /// **'Have a promo code?'**
  String get checkout_voucher_havePromoCode;

  /// No description provided for @checkout_voucher_off.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get checkout_voucher_off;

  /// No description provided for @checkout_voucher_promoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get checkout_voucher_promoCode;

  /// No description provided for @checkout_voucher_removeVoucher.
  ///
  /// In en, this message translates to:
  /// **'Remove voucher'**
  String get checkout_voucher_removeVoucher;

  /// No description provided for @checkout_voucher_saved.
  ///
  /// In en, this message translates to:
  /// **'{amount} saved'**
  String checkout_voucher_saved(Object amount);

  /// No description provided for @checkout_whosCheckingIn.
  ///
  /// In en, this message translates to:
  /// **'Who\'s checking in?'**
  String get checkout_whosCheckingIn;

  /// No description provided for @checkout_whosCheckingInYou.
  ///
  /// In en, this message translates to:
  /// **'Who’s checking in? (Your Details)'**
  String get checkout_whosCheckingInYou;

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @common_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// No description provided for @common_closeSettings.
  ///
  /// In en, this message translates to:
  /// **'Close settings'**
  String get common_closeSettings;

  /// No description provided for @common_currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get common_currency;

  /// No description provided for @common_filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get common_filter;

  /// No description provided for @common_freeCancel.
  ///
  /// In en, this message translates to:
  /// **'Free cancel'**
  String get common_freeCancel;

  /// No description provided for @common_goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get common_goBack;

  /// No description provided for @common_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get common_language;

  /// No description provided for @common_openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get common_openInMaps;

  /// No description provided for @common_primary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get common_primary;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// No description provided for @common_scrollLeft.
  ///
  /// In en, this message translates to:
  /// **'Scroll left'**
  String get common_scrollLeft;

  /// No description provided for @common_scrollRight.
  ///
  /// In en, this message translates to:
  /// **'Scroll right'**
  String get common_scrollRight;

  /// No description provided for @common_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get common_settings;

  /// No description provided for @common_share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get common_share;

  /// No description provided for @currencyPicker_label.
  ///
  /// In en, this message translates to:
  /// **'Select currency'**
  String get currencyPicker_label;

  /// No description provided for @deals_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get deals_all;

  /// No description provided for @deals_allDealsCount.
  ///
  /// In en, this message translates to:
  /// **'All {count} deals'**
  String deals_allDealsCount(Object count);

  /// No description provided for @deals_collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse ↑'**
  String get deals_collapse;

  /// No description provided for @deals_emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Check back soon — we update our deals regularly.'**
  String get deals_emptyBody;

  /// No description provided for @deals_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No active deals right now'**
  String get deals_emptyTitle;

  /// No description provided for @deals_headerDefault.
  ///
  /// In en, this message translates to:
  /// **'Exclusive Deals & Offers'**
  String get deals_headerDefault;

  /// No description provided for @deals_headerPersonalized.
  ///
  /// In en, this message translates to:
  /// **'Flight Deals from {city}'**
  String deals_headerPersonalized(Object city);

  /// No description provided for @deals_limitedTime.
  ///
  /// In en, this message translates to:
  /// **'Limited-time offers'**
  String get deals_limitedTime;

  /// No description provided for @deals_loadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load deals'**
  String get deals_loadError;

  /// No description provided for @deals_metaTitle.
  ///
  /// In en, this message translates to:
  /// **'Deals'**
  String get deals_metaTitle;

  /// No description provided for @deals_oneWay.
  ///
  /// In en, this message translates to:
  /// **'One Way'**
  String get deals_oneWay;

  /// No description provided for @deals_popularRoute.
  ///
  /// In en, this message translates to:
  /// **'Popular Route'**
  String get deals_popularRoute;

  /// No description provided for @deals_roundTrip.
  ///
  /// In en, this message translates to:
  /// **'Round Trip'**
  String get deals_roundTrip;

  /// No description provided for @deals_searchFlights.
  ///
  /// In en, this message translates to:
  /// **'Search Flights'**
  String get deals_searchFlights;

  /// No description provided for @deals_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Handpicked deals with the lowest prices we could find. Prices update frequently — book early to lock in your rate.'**
  String get deals_subtitle;

  /// No description provided for @deals_subtitleDefault.
  ///
  /// In en, this message translates to:
  /// **'Low fares on popular routes'**
  String get deals_subtitleDefault;

  /// No description provided for @deals_subtitlePersonalized.
  ///
  /// In en, this message translates to:
  /// **'Low fares departing from {city}'**
  String deals_subtitlePersonalized(Object city);

  /// No description provided for @deals_todaysBest.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Best Hotel Deals'**
  String get deals_todaysBest;

  /// No description provided for @destinations_hotelsAvailableFor.
  ///
  /// In en, this message translates to:
  /// **'Hotels available for {from} — {to}'**
  String destinations_hotelsAvailableFor(Object from, Object to);

  /// No description provided for @destinations_metaTitle.
  ///
  /// In en, this message translates to:
  /// **'Hotels in {place}'**
  String destinations_metaTitle(Object place);

  /// No description provided for @destinations_plural.
  ///
  /// In en, this message translates to:
  /// **'Destinations'**
  String get destinations_plural;

  /// No description provided for @destinations_singular.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destinations_singular;

  /// No description provided for @documents_actions_checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check in with airline'**
  String get documents_actions_checkIn;

  /// No description provided for @documents_actions_eticket.
  ///
  /// In en, this message translates to:
  /// **'View e-ticket'**
  String get documents_actions_eticket;

  /// No description provided for @documents_actions_receipt.
  ///
  /// In en, this message translates to:
  /// **'View payment receipt'**
  String get documents_actions_receipt;

  /// No description provided for @documents_actions_voucher.
  ///
  /// In en, this message translates to:
  /// **'View hotel voucher'**
  String get documents_actions_voucher;

  /// No description provided for @documents_eticket_atCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Assigned at check-in'**
  String get documents_eticket_atCheckIn;

  /// No description provided for @documents_eticket_checkInHint.
  ///
  /// In en, this message translates to:
  /// **'Check in with the airline to get your boarding pass. Airlines usually open check-in 24–48 hours before departure.'**
  String get documents_eticket_checkInHint;

  /// No description provided for @documents_eticket_fareConditions.
  ///
  /// In en, this message translates to:
  /// **'Fare conditions'**
  String get documents_eticket_fareConditions;

  /// No description provided for @documents_eticket_flight.
  ///
  /// In en, this message translates to:
  /// **'Flight'**
  String get documents_eticket_flight;

  /// No description provided for @documents_eticket_footer.
  ///
  /// In en, this message translates to:
  /// **'Present this with the passport or ID used to book. Names must match your travel document.'**
  String get documents_eticket_footer;

  /// No description provided for @documents_eticket_from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get documents_eticket_from;

  /// No description provided for @documents_eticket_nonChangeable.
  ///
  /// In en, this message translates to:
  /// **'changes not permitted'**
  String get documents_eticket_nonChangeable;

  /// No description provided for @documents_eticket_nonRefundable.
  ///
  /// In en, this message translates to:
  /// **'Non-refundable'**
  String get documents_eticket_nonRefundable;

  /// No description provided for @documents_eticket_passenger.
  ///
  /// In en, this message translates to:
  /// **'Passenger'**
  String get documents_eticket_passenger;

  /// No description provided for @documents_eticket_pnr.
  ///
  /// In en, this message translates to:
  /// **'Booking reference'**
  String get documents_eticket_pnr;

  /// No description provided for @documents_eticket_refundable.
  ///
  /// In en, this message translates to:
  /// **'Refundable'**
  String get documents_eticket_refundable;

  /// No description provided for @documents_eticket_seat.
  ///
  /// In en, this message translates to:
  /// **'Seat'**
  String get documents_eticket_seat;

  /// No description provided for @documents_eticket_ticketNumber.
  ///
  /// In en, this message translates to:
  /// **'E-ticket number'**
  String get documents_eticket_ticketNumber;

  /// No description provided for @documents_eticket_title.
  ///
  /// In en, this message translates to:
  /// **'E-ticket & itinerary'**
  String get documents_eticket_title;

  /// No description provided for @documents_eticket_to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get documents_eticket_to;

  /// No description provided for @documents_pending_awaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Your payment went through. We are waiting for the property to confirm — your voucher appears here as soon as it does.'**
  String get documents_pending_awaitingConfirmation;

  /// No description provided for @documents_pending_awaitingTicket.
  ///
  /// In en, this message translates to:
  /// **'Your payment went through. The airline has not issued the ticket yet — your e-ticket appears here as soon as it does.'**
  String get documents_pending_awaitingTicket;

  /// No description provided for @documents_receipt_bookingReference.
  ///
  /// In en, this message translates to:
  /// **'Booking reference'**
  String get documents_receipt_bookingReference;

  /// No description provided for @documents_receipt_card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get documents_receipt_card;

  /// No description provided for @documents_receipt_footer.
  ///
  /// In en, this message translates to:
  /// **'This receipt confirms a payment. It is not a travel document — your e-ticket or hotel voucher is what you show on arrival.'**
  String get documents_receipt_footer;

  /// No description provided for @documents_receipt_paid.
  ///
  /// In en, this message translates to:
  /// **'Payment successful'**
  String get documents_receipt_paid;

  /// No description provided for @documents_receipt_paymentDate.
  ///
  /// In en, this message translates to:
  /// **'Payment date'**
  String get documents_receipt_paymentDate;

  /// No description provided for @documents_receipt_paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get documents_receipt_paymentMethod;

  /// No description provided for @documents_receipt_receiptNumber.
  ///
  /// In en, this message translates to:
  /// **'Receipt number'**
  String get documents_receipt_receiptNumber;

  /// No description provided for @documents_receipt_title.
  ///
  /// In en, this message translates to:
  /// **'Payment receipt'**
  String get documents_receipt_title;

  /// No description provided for @documents_receipt_totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total paid'**
  String get documents_receipt_totalPaid;

  /// No description provided for @documents_section.
  ///
  /// In en, this message translates to:
  /// **'Travel documents'**
  String get documents_section;

  /// No description provided for @documents_status_confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get documents_status_confirmed;

  /// No description provided for @documents_status_ticketed.
  ///
  /// In en, this message translates to:
  /// **'Ticketed'**
  String get documents_status_ticketed;

  /// No description provided for @documents_voucher_checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get documents_voucher_checkIn;

  /// No description provided for @documents_voucher_checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get documents_voucher_checkOut;

  /// No description provided for @documents_voucher_confirmationNumber.
  ///
  /// In en, this message translates to:
  /// **'Hotel confirmation number'**
  String get documents_voucher_confirmationNumber;

  /// No description provided for @documents_voucher_footer.
  ///
  /// In en, this message translates to:
  /// **'Present this voucher and a valid government-issued ID or passport at check-in. The property may apply additional requirements.'**
  String get documents_voucher_footer;

  /// No description provided for @documents_voucher_fromTime.
  ///
  /// In en, this message translates to:
  /// **'From {time}'**
  String documents_voucher_fromTime(Object time);

  /// No description provided for @documents_voucher_guests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get documents_voucher_guests;

  /// No description provided for @documents_voucher_leadGuest.
  ///
  /// In en, this message translates to:
  /// **'Lead guest'**
  String get documents_voucher_leadGuest;

  /// No description provided for @documents_voucher_mealPlan.
  ///
  /// In en, this message translates to:
  /// **'Meal plan'**
  String get documents_voucher_mealPlan;

  /// No description provided for @documents_voucher_occupancy.
  ///
  /// In en, this message translates to:
  /// **'{adults, plural, one {# adult} other {# adults}}{children, plural, =0 {} one {, # child} other {, # children}}'**
  String documents_voucher_occupancy(num adults, num children);

  /// No description provided for @documents_voucher_ourReference.
  ///
  /// In en, this message translates to:
  /// **'Our reference'**
  String get documents_voucher_ourReference;

  /// No description provided for @documents_voucher_paidOnline.
  ///
  /// In en, this message translates to:
  /// **'Paid online'**
  String get documents_voucher_paidOnline;

  /// No description provided for @documents_voucher_payAtProperty.
  ///
  /// In en, this message translates to:
  /// **'Pay at property'**
  String get documents_voucher_payAtProperty;

  /// No description provided for @documents_voucher_paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get documents_voucher_paymentStatus;

  /// No description provided for @documents_voucher_requestsNotGuaranteed.
  ///
  /// In en, this message translates to:
  /// **'Requests are passed to the property and are not guaranteed.'**
  String get documents_voucher_requestsNotGuaranteed;

  /// No description provided for @documents_voucher_room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get documents_voucher_room;

  /// No description provided for @documents_voucher_specialRequests.
  ///
  /// In en, this message translates to:
  /// **'Special requests'**
  String get documents_voucher_specialRequests;

  /// No description provided for @documents_voucher_stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get documents_voucher_stay;

  /// No description provided for @documents_voucher_title.
  ///
  /// In en, this message translates to:
  /// **'Hotel booking voucher'**
  String get documents_voucher_title;

  /// No description provided for @documents_voucher_untilTime.
  ///
  /// In en, this message translates to:
  /// **'Until {time}'**
  String documents_voucher_untilTime(Object time);

  /// No description provided for @errors_auth_description.
  ///
  /// In en, this message translates to:
  /// **'There was an error processing your authentication request. This could happen if the link expired or was already used.'**
  String get errors_auth_description;

  /// No description provided for @errors_auth_goHome.
  ///
  /// In en, this message translates to:
  /// **'Go to homepage'**
  String get errors_auth_goHome;

  /// No description provided for @errors_auth_retryDescription.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong during authentication. Please try again.'**
  String get errors_auth_retryDescription;

  /// No description provided for @errors_auth_signInAgain.
  ///
  /// In en, this message translates to:
  /// **'Try signing in again'**
  String get errors_auth_signInAgain;

  /// No description provided for @errors_auth_title.
  ///
  /// In en, this message translates to:
  /// **'Authentication Error'**
  String get errors_auth_title;

  /// No description provided for @errors_generic.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errors_generic;

  /// No description provided for @errors_notFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found.'**
  String get errors_notFound;

  /// No description provided for @errors_page_body.
  ///
  /// In en, this message translates to:
  /// **'This page could not be loaded. Trying again usually clears it.'**
  String get errors_page_body;

  /// No description provided for @errors_page_goHome.
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get errors_page_goHome;

  /// No description provided for @errors_page_notFoundBody.
  ///
  /// In en, this message translates to:
  /// **'The link may be out of date, or the stay may no longer be listed.'**
  String get errors_page_notFoundBody;

  /// No description provided for @errors_page_notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'This page does not exist'**
  String get errors_page_notFoundTitle;

  /// No description provided for @errors_page_searchStays.
  ///
  /// In en, this message translates to:
  /// **'Search stays'**
  String get errors_page_searchStays;

  /// No description provided for @errors_page_title.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errors_page_title;

  /// No description provided for @errors_page_tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get errors_page_tryAgain;

  /// No description provided for @errors_searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed. Check your connection and try again.'**
  String get errors_searchFailed;

  /// No description provided for @flights_card_currentlySelected.
  ///
  /// In en, this message translates to:
  /// **'Currently Selected'**
  String get flights_card_currentlySelected;

  /// No description provided for @flights_card_direct.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get flights_card_direct;

  /// No description provided for @flights_card_fareOptions.
  ///
  /// In en, this message translates to:
  /// **'Available Fare Options'**
  String get flights_card_fareOptions;

  /// No description provided for @flights_card_freeCancellation.
  ///
  /// In en, this message translates to:
  /// **'Free Cancellation'**
  String get flights_card_freeCancellation;

  /// No description provided for @flights_card_includesTaxes.
  ///
  /// In en, this message translates to:
  /// **'includes taxes & fees'**
  String get flights_card_includesTaxes;

  /// No description provided for @flights_card_nonRefundable.
  ///
  /// In en, this message translates to:
  /// **'Non-refundable'**
  String get flights_card_nonRefundable;

  /// No description provided for @flights_card_perPerson.
  ///
  /// In en, this message translates to:
  /// **'per person'**
  String get flights_card_perPerson;

  /// No description provided for @flights_card_stop.
  ///
  /// In en, this message translates to:
  /// **'stop'**
  String get flights_card_stop;

  /// No description provided for @flights_card_stops.
  ///
  /// In en, this message translates to:
  /// **'stops'**
  String get flights_card_stops;

  /// No description provided for @flights_card_viewDeal.
  ///
  /// In en, this message translates to:
  /// **'View deal'**
  String get flights_card_viewDeal;

  /// No description provided for @flights_filtersPanel_airlines.
  ///
  /// In en, this message translates to:
  /// **'Airlines'**
  String get flights_filtersPanel_airlines;

  /// No description provided for @flights_filtersPanel_anyStops.
  ///
  /// In en, this message translates to:
  /// **'Any Stops'**
  String get flights_filtersPanel_anyStops;

  /// No description provided for @flights_filtersPanel_arrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get flights_filtersPanel_arrival;

  /// No description provided for @flights_filtersPanel_arrivalAirports.
  ///
  /// In en, this message translates to:
  /// **'Arrival Airports'**
  String get flights_filtersPanel_arrivalAirports;

  /// No description provided for @flights_filtersPanel_branded.
  ///
  /// In en, this message translates to:
  /// **'Branded'**
  String get flights_filtersPanel_branded;

  /// No description provided for @flights_filtersPanel_cheapestFirst.
  ///
  /// In en, this message translates to:
  /// **'Cheapest First'**
  String get flights_filtersPanel_cheapestFirst;

  /// No description provided for @flights_filtersPanel_departure.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get flights_filtersPanel_departure;

  /// No description provided for @flights_filtersPanel_direct.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get flights_filtersPanel_direct;

  /// No description provided for @flights_filtersPanel_earliestDeparture.
  ///
  /// In en, this message translates to:
  /// **'Earliest Departure'**
  String get flights_filtersPanel_earliestDeparture;

  /// No description provided for @flights_filtersPanel_fareType.
  ///
  /// In en, this message translates to:
  /// **'Fare Type'**
  String get flights_filtersPanel_fareType;

  /// No description provided for @flights_filtersPanel_fastestFirst.
  ///
  /// In en, this message translates to:
  /// **'Fastest First'**
  String get flights_filtersPanel_fastestFirst;

  /// No description provided for @flights_filtersPanel_flightDuration.
  ///
  /// In en, this message translates to:
  /// **'Flight Duration'**
  String get flights_filtersPanel_flightDuration;

  /// No description provided for @flights_filtersPanel_ndc.
  ///
  /// In en, this message translates to:
  /// **'NDC'**
  String get flights_filtersPanel_ndc;

  /// No description provided for @flights_filtersPanel_nonStopOnly.
  ///
  /// In en, this message translates to:
  /// **'Non-stop only'**
  String get flights_filtersPanel_nonStopOnly;

  /// No description provided for @flights_filtersPanel_oneStop.
  ///
  /// In en, this message translates to:
  /// **'1 Stop'**
  String get flights_filtersPanel_oneStop;

  /// No description provided for @flights_filtersPanel_pricePerPerson.
  ///
  /// In en, this message translates to:
  /// **'Price Per Person'**
  String get flights_filtersPanel_pricePerPerson;

  /// No description provided for @flights_filtersPanel_provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get flights_filtersPanel_provider;

  /// No description provided for @flights_filtersPanel_rangeFrom.
  ///
  /// In en, this message translates to:
  /// **'{label} from'**
  String flights_filtersPanel_rangeFrom(Object label);

  /// No description provided for @flights_filtersPanel_rangeTo.
  ///
  /// In en, this message translates to:
  /// **'{label} to'**
  String flights_filtersPanel_rangeTo(Object label);

  /// No description provided for @flights_filtersPanel_refundable.
  ///
  /// In en, this message translates to:
  /// **'Refundable'**
  String get flights_filtersPanel_refundable;

  /// No description provided for @flights_filtersPanel_refundableFares.
  ///
  /// In en, this message translates to:
  /// **'Refundable fares'**
  String get flights_filtersPanel_refundableFares;

  /// No description provided for @flights_filtersPanel_refundableFaresDescription.
  ///
  /// In en, this message translates to:
  /// **'Fares that allow cancellation with a refund'**
  String get flights_filtersPanel_refundableFaresDescription;

  /// No description provided for @flights_filtersPanel_reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get flights_filtersPanel_reset;

  /// No description provided for @flights_filtersPanel_selectAllAirlines.
  ///
  /// In en, this message translates to:
  /// **'Select all airlines'**
  String get flights_filtersPanel_selectAllAirlines;

  /// No description provided for @flights_filtersPanel_selectAllAirports.
  ///
  /// In en, this message translates to:
  /// **'Select all airports'**
  String get flights_filtersPanel_selectAllAirports;

  /// No description provided for @flights_filtersPanel_showAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get flights_filtersPanel_showAll;

  /// No description provided for @flights_filtersPanel_showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get flights_filtersPanel_showLess;

  /// No description provided for @flights_filtersPanel_sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get flights_filtersPanel_sortBy;

  /// No description provided for @flights_filtersPanel_stops.
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get flights_filtersPanel_stops;

  /// No description provided for @flights_filtersPanel_times.
  ///
  /// In en, this message translates to:
  /// **'Times'**
  String get flights_filtersPanel_times;

  /// No description provided for @flights_filtersPanel_twoStopsPlus.
  ///
  /// In en, this message translates to:
  /// **'2 Stops +'**
  String get flights_filtersPanel_twoStopsPlus;

  /// No description provided for @flights_filtersPanel_underHours.
  ///
  /// In en, this message translates to:
  /// **'Under {hours} hours'**
  String flights_filtersPanel_underHours(Object hours);

  /// No description provided for @flights_filtersPanel_upToOneStop.
  ///
  /// In en, this message translates to:
  /// **'Up to 1 stop'**
  String get flights_filtersPanel_upToOneStop;

  /// No description provided for @flights_filters_airlines.
  ///
  /// In en, this message translates to:
  /// **'Airlines'**
  String get flights_filters_airlines;

  /// No description provided for @flights_filters_anyStops.
  ///
  /// In en, this message translates to:
  /// **'Any stops'**
  String get flights_filters_anyStops;

  /// No description provided for @flights_filters_cheapest.
  ///
  /// In en, this message translates to:
  /// **'Cheapest'**
  String get flights_filters_cheapest;

  /// No description provided for @flights_filters_earliest.
  ///
  /// In en, this message translates to:
  /// **'Earliest Departure'**
  String get flights_filters_earliest;

  /// No description provided for @flights_filters_fareType.
  ///
  /// In en, this message translates to:
  /// **'Fare Type'**
  String get flights_filters_fareType;

  /// No description provided for @flights_filters_fastest.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get flights_filters_fastest;

  /// No description provided for @flights_filters_nonStopOnly.
  ///
  /// In en, this message translates to:
  /// **'Non-stop only'**
  String get flights_filters_nonStopOnly;

  /// No description provided for @flights_filters_provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get flights_filters_provider;

  /// No description provided for @flights_filters_refundableHint.
  ///
  /// In en, this message translates to:
  /// **'Show only fares that can be cancelled for a refund'**
  String get flights_filters_refundableHint;

  /// No description provided for @flights_filters_refundableOnly.
  ///
  /// In en, this message translates to:
  /// **'Refundable fares only'**
  String get flights_filters_refundableOnly;

  /// No description provided for @flights_filters_stops.
  ///
  /// In en, this message translates to:
  /// **'Stops'**
  String get flights_filters_stops;

  /// No description provided for @flights_filters_upTo1Stop.
  ///
  /// In en, this message translates to:
  /// **'Up to 1 stop'**
  String get flights_filters_upTo1Stop;

  /// No description provided for @flights_header_fetching.
  ///
  /// In en, this message translates to:
  /// **'Fetching providers...'**
  String get flights_header_fetching;

  /// No description provided for @flights_header_sources.
  ///
  /// In en, this message translates to:
  /// **'Sources:'**
  String get flights_header_sources;

  /// No description provided for @flights_itinerary_arriveAt.
  ///
  /// In en, this message translates to:
  /// **'Arrive at'**
  String get flights_itinerary_arriveAt;

  /// No description provided for @flights_itinerary_departFrom.
  ///
  /// In en, this message translates to:
  /// **'Depart from'**
  String get flights_itinerary_departFrom;

  /// No description provided for @flights_itinerary_flightDuration.
  ///
  /// In en, this message translates to:
  /// **'Flight Duration'**
  String get flights_itinerary_flightDuration;

  /// No description provided for @flights_itinerary_layoverLabel.
  ///
  /// In en, this message translates to:
  /// **'Layover'**
  String get flights_itinerary_layoverLabel;

  /// No description provided for @flights_itinerary_layoverValue.
  ///
  /// In en, this message translates to:
  /// **'{duration} at {airport}'**
  String flights_itinerary_layoverValue(Object duration, Object airport);

  /// No description provided for @flights_itinerary_legLabel.
  ///
  /// In en, this message translates to:
  /// **'Leg {number}'**
  String flights_itinerary_legLabel(Object number);

  /// No description provided for @flights_itinerary_nonstop.
  ///
  /// In en, this message translates to:
  /// **'Nonstop'**
  String get flights_itinerary_nonstop;

  /// No description provided for @flights_itinerary_outbound.
  ///
  /// In en, this message translates to:
  /// **'Outbound'**
  String get flights_itinerary_outbound;

  /// No description provided for @flights_itinerary_return.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get flights_itinerary_return;

  /// No description provided for @flights_itinerary_stopCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# stop} other {# stops}}'**
  String flights_itinerary_stopCount(num count);

  /// No description provided for @flights_itinerary_terminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal {terminal}'**
  String flights_itinerary_terminal(Object terminal);

  /// No description provided for @flights_itinerary_terminalUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Terminal available closer to departure'**
  String get flights_itinerary_terminalUnavailable;

  /// No description provided for @flights_itinerary_totalFlightDuration.
  ///
  /// In en, this message translates to:
  /// **'Total Flight Duration'**
  String get flights_itinerary_totalFlightDuration;

  /// No description provided for @flights_meta_description.
  ///
  /// In en, this message translates to:
  /// **'Compare and book cheap flights worldwide. Find the best deals on {brand}.'**
  String flights_meta_description(Object brand);

  /// No description provided for @flights_meta_descriptionRoute.
  ///
  /// In en, this message translates to:
  /// **'Compare and book the cheapest flights from {origin} to {destination}. Find the best deals on {brand}.'**
  String flights_meta_descriptionRoute(
    Object origin,
    Object destination,
    Object brand,
  );

  /// No description provided for @flights_meta_title.
  ///
  /// In en, this message translates to:
  /// **'Flight Search Results'**
  String get flights_meta_title;

  /// No description provided for @flights_meta_titleRoute.
  ///
  /// In en, this message translates to:
  /// **'Flights {origin} → {destination}'**
  String flights_meta_titleRoute(Object origin, Object destination);

  /// No description provided for @flights_passengers_adults.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# adult} other {# adults}}'**
  String flights_passengers_adults(num count);

  /// No description provided for @flights_passengers_children.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# child} other {# children}}'**
  String flights_passengers_children(num count);

  /// No description provided for @flights_passengers_infants.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# infant} other {# infants}}'**
  String flights_passengers_infants(num count);

  /// No description provided for @flights_priceAlert_active.
  ///
  /// In en, this message translates to:
  /// **'Price alerts active'**
  String get flights_priceAlert_active;

  /// No description provided for @flights_priceAlert_emailMe.
  ///
  /// In en, this message translates to:
  /// **'Email me when price drops'**
  String get flights_priceAlert_emailMe;

  /// No description provided for @flights_priceAlert_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get flights_priceAlert_loading;

  /// No description provided for @flights_priceAlert_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove alert'**
  String get flights_priceAlert_remove;

  /// No description provided for @flights_priceAlert_signInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in required'**
  String get flights_priceAlert_signInRequired;

  /// No description provided for @flights_priceAlert_track.
  ///
  /// In en, this message translates to:
  /// **'Track Price'**
  String get flights_priceAlert_track;

  /// No description provided for @flights_results_bundleActive.
  ///
  /// In en, this message translates to:
  /// **'Flight + Hotel Bundle Active'**
  String get flights_results_bundleActive;

  /// No description provided for @flights_results_bundleBody.
  ///
  /// In en, this message translates to:
  /// **'Select a flight below — your bundle discount will be applied at checkout.'**
  String get flights_results_bundleBody;

  /// No description provided for @flights_results_checkingFare.
  ///
  /// In en, this message translates to:
  /// **'Checking the fare is still available…'**
  String get flights_results_checkingFare;

  /// No description provided for @flights_results_checkingProviders.
  ///
  /// In en, this message translates to:
  /// **'Checking multiple providers'**
  String get flights_results_checkingProviders;

  /// No description provided for @flights_results_clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get flights_results_clearFilters;

  /// No description provided for @flights_results_countFlights.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# flight} other {# flights}}'**
  String flights_results_countFlights(num count);

  /// No description provided for @flights_results_datePicked.
  ///
  /// In en, this message translates to:
  /// **'We picked this date — change it to see other fares.'**
  String get flights_results_datePicked;

  /// No description provided for @flights_results_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get flights_results_duration;

  /// No description provided for @flights_results_empty.
  ///
  /// In en, this message translates to:
  /// **'No flights found for these dates.'**
  String get flights_results_empty;

  /// No description provided for @flights_results_filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get flights_results_filters;

  /// No description provided for @flights_results_filtersTitle.
  ///
  /// In en, this message translates to:
  /// **'Flight Filters'**
  String get flights_results_filtersTitle;

  /// No description provided for @flights_results_findingFares.
  ///
  /// In en, this message translates to:
  /// **'Finding the best fares…'**
  String get flights_results_findingFares;

  /// No description provided for @flights_results_flightsFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# flight} other {# flights}} found'**
  String flights_results_flightsFound(num count);

  /// No description provided for @flights_results_flightsTo.
  ///
  /// In en, this message translates to:
  /// **'Flights to {city}'**
  String flights_results_flightsTo(Object city);

  /// No description provided for @flights_results_loading.
  ///
  /// In en, this message translates to:
  /// **'Finding the best fares…'**
  String get flights_results_loading;

  /// No description provided for @flights_results_missingRoute.
  ///
  /// In en, this message translates to:
  /// **'Tell us where you are flying from and to, and we will find the fares.'**
  String get flights_results_missingRoute;

  /// No description provided for @flights_results_newSearch.
  ///
  /// In en, this message translates to:
  /// **'New Search'**
  String get flights_results_newSearch;

  /// No description provided for @flights_results_noFlights.
  ///
  /// In en, this message translates to:
  /// **'No flights found'**
  String get flights_results_noFlights;

  /// No description provided for @flights_results_noFlightsBody.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search dates or nearby airports.'**
  String get flights_results_noFlightsBody;

  /// No description provided for @flights_results_noMatch.
  ///
  /// In en, this message translates to:
  /// **'No flights match your filters'**
  String get flights_results_noMatch;

  /// No description provided for @flights_results_noMatchHint.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filter criteria.'**
  String get flights_results_noMatchHint;

  /// No description provided for @flights_results_price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get flights_results_price;

  /// No description provided for @flights_results_saveUpTo.
  ///
  /// In en, this message translates to:
  /// **'Save up to 8%'**
  String get flights_results_saveUpTo;

  /// No description provided for @flights_results_searchError.
  ///
  /// In en, this message translates to:
  /// **'Search Error'**
  String get flights_results_searchError;

  /// No description provided for @flights_results_slowBody.
  ///
  /// In en, this message translates to:
  /// **'Flight providers are responding slowly. Please try again.'**
  String get flights_results_slowBody;

  /// No description provided for @flights_results_slowHint.
  ///
  /// In en, this message translates to:
  /// **'Providers are responding slowly. Hang tight.'**
  String get flights_results_slowHint;

  /// No description provided for @flights_results_slowTitle.
  ///
  /// In en, this message translates to:
  /// **'Search is taking longer than usual'**
  String get flights_results_slowTitle;

  /// No description provided for @flights_results_sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get flights_results_sortBy;

  /// No description provided for @flights_results_stops_any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get flights_results_stops_any;

  /// No description provided for @flights_results_stops_direct.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get flights_results_stops_direct;

  /// No description provided for @flights_results_stops_oneStop.
  ///
  /// In en, this message translates to:
  /// **'1 stop'**
  String get flights_results_stops_oneStop;

  /// No description provided for @flights_results_stops_twoPlus.
  ///
  /// In en, this message translates to:
  /// **'2+ stops'**
  String get flights_results_stops_twoPlus;

  /// No description provided for @flights_results_tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get flights_results_tryAgain;

  /// No description provided for @flights_results_tryAnother.
  ///
  /// In en, this message translates to:
  /// **'Try another search'**
  String get flights_results_tryAnother;

  /// No description provided for @flights_topBar_cabin.
  ///
  /// In en, this message translates to:
  /// **'Cabin'**
  String get flights_topBar_cabin;

  /// No description provided for @flights_topBar_changeTrip.
  ///
  /// In en, this message translates to:
  /// **'Change dates and travellers'**
  String get flights_topBar_changeTrip;

  /// No description provided for @flights_topBar_swap.
  ///
  /// In en, this message translates to:
  /// **'Swap origin and destination'**
  String get flights_topBar_swap;

  /// No description provided for @footer_aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get footer_aboutUs;

  /// No description provided for @footer_cars.
  ///
  /// In en, this message translates to:
  /// **'Cars'**
  String get footer_cars;

  /// No description provided for @footer_company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get footer_company;

  /// No description provided for @footer_contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get footer_contact;

  /// No description provided for @footer_contactMinimal.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get footer_contactMinimal;

  /// No description provided for @footer_cookies.
  ///
  /// In en, this message translates to:
  /// **'Cookies'**
  String get footer_cookies;

  /// No description provided for @footer_cookiesMinimal.
  ///
  /// In en, this message translates to:
  /// **'Cookie preferences'**
  String get footer_cookiesMinimal;

  /// No description provided for @footer_copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 FORHU Inc. All rights reserved.'**
  String get footer_copyright;

  /// No description provided for @footer_copyrightMinimal.
  ///
  /// In en, this message translates to:
  /// **'CheapestGo © 2026'**
  String get footer_copyrightMinimal;

  /// No description provided for @footer_enterprise.
  ///
  /// In en, this message translates to:
  /// **'Enterprise'**
  String get footer_enterprise;

  /// No description provided for @footer_flights.
  ///
  /// In en, this message translates to:
  /// **'Flights'**
  String get footer_flights;

  /// No description provided for @footer_flightsApi.
  ///
  /// In en, this message translates to:
  /// **'Flights API'**
  String get footer_flightsApi;

  /// No description provided for @footer_hotels.
  ///
  /// In en, this message translates to:
  /// **'Hotels'**
  String get footer_hotels;

  /// No description provided for @footer_manageBooking.
  ///
  /// In en, this message translates to:
  /// **'Manage booking'**
  String get footer_manageBooking;

  /// No description provided for @footer_module.
  ///
  /// In en, this message translates to:
  /// **'Module'**
  String get footer_module;

  /// No description provided for @footer_network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get footer_network;

  /// No description provided for @footer_paymentGateway.
  ///
  /// In en, this message translates to:
  /// **'Payment Gateway'**
  String get footer_paymentGateway;

  /// No description provided for @footer_poweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by Duffel & TravelgateX.'**
  String get footer_poweredBy;

  /// No description provided for @footer_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get footer_privacy;

  /// No description provided for @footer_privacyMinimal.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get footer_privacyMinimal;

  /// No description provided for @footer_reportBug.
  ///
  /// In en, this message translates to:
  /// **'Report a Bug'**
  String get footer_reportBug;

  /// No description provided for @footer_support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get footer_support;

  /// No description provided for @footer_tagline.
  ///
  /// In en, this message translates to:
  /// **'Engineered for the discerning traveler.'**
  String get footer_tagline;

  /// No description provided for @footer_taglinePrecision.
  ///
  /// In en, this message translates to:
  /// **'Precision data. Zero compromise.'**
  String get footer_taglinePrecision;

  /// No description provided for @footer_terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get footer_terms;

  /// No description provided for @footer_termsMinimal.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get footer_termsMinimal;

  /// No description provided for @golf_aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About the course'**
  String get golf_aboutTitle;

  /// No description provided for @golf_addressTitle.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get golf_addressTitle;

  /// No description provided for @golf_allCountries.
  ///
  /// In en, this message translates to:
  /// **'All countries'**
  String get golf_allCountries;

  /// No description provided for @golf_amenitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'At the course'**
  String get golf_amenitiesTitle;

  /// No description provided for @golf_amenities_caddie.
  ///
  /// In en, this message translates to:
  /// **'Caddies'**
  String get golf_amenities_caddie;

  /// No description provided for @golf_amenities_cart.
  ///
  /// In en, this message translates to:
  /// **'Golf carts'**
  String get golf_amenities_cart;

  /// No description provided for @golf_amenities_club_rental.
  ///
  /// In en, this message translates to:
  /// **'Club rental'**
  String get golf_amenities_club_rental;

  /// No description provided for @golf_amenities_clubhouse.
  ///
  /// In en, this message translates to:
  /// **'Clubhouse'**
  String get golf_amenities_clubhouse;

  /// No description provided for @golf_amenities_driving_range.
  ///
  /// In en, this message translates to:
  /// **'Driving range'**
  String get golf_amenities_driving_range;

  /// No description provided for @golf_amenities_lessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get golf_amenities_lessons;

  /// No description provided for @golf_amenities_night_golf.
  ///
  /// In en, this message translates to:
  /// **'Night golf'**
  String get golf_amenities_night_golf;

  /// No description provided for @golf_amenities_pro_shop.
  ///
  /// In en, this message translates to:
  /// **'Pro shop'**
  String get golf_amenities_pro_shop;

  /// No description provided for @golf_amenities_putting_green.
  ///
  /// In en, this message translates to:
  /// **'Putting green'**
  String get golf_amenities_putting_green;

  /// No description provided for @golf_amenities_restaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get golf_amenities_restaurant;

  /// No description provided for @golf_askHint.
  ///
  /// In en, this message translates to:
  /// **'Our team replies in the support chat.'**
  String get golf_askHint;

  /// No description provided for @golf_askSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to chat with our team about tee times.'**
  String get golf_askSignIn;

  /// No description provided for @golf_askTeeTimes.
  ///
  /// In en, this message translates to:
  /// **'Ask about tee times'**
  String get golf_askTeeTimes;

  /// No description provided for @golf_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get golf_back;

  /// No description provided for @golf_booking_backToCourse.
  ///
  /// In en, this message translates to:
  /// **'Back to the course'**
  String get golf_booking_backToCourse;

  /// No description provided for @golf_booking_cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get golf_booking_cancelBooking;

  /// No description provided for @golf_booking_cancelFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t cancel this just now, and nothing has changed. Please try again.'**
  String get golf_booking_cancelFailed;

  /// No description provided for @golf_booking_cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel this request'**
  String get golf_booking_cancelRequest;

  /// No description provided for @golf_booking_cancelRequestNote.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been charged. Cancelling releases the hold on your card and gives up these spots.'**
  String get golf_booking_cancelRequestNote;

  /// No description provided for @golf_booking_cancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling…'**
  String get golf_booking_cancelling;

  /// No description provided for @golf_booking_confirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel it'**
  String get golf_booking_confirmCancel;

  /// No description provided for @golf_booking_contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get golf_booking_contactSupport;

  /// No description provided for @golf_booking_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue to payment'**
  String get golf_booking_continue;

  /// No description provided for @golf_booking_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get golf_booking_date;

  /// No description provided for @golf_booking_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get golf_booking_email;

  /// No description provided for @golf_booking_extraAdd.
  ///
  /// In en, this message translates to:
  /// **'Add one: {name}'**
  String golf_booking_extraAdd(Object name);

  /// No description provided for @golf_booking_extraEach.
  ///
  /// In en, this message translates to:
  /// **'{price} each'**
  String golf_booking_extraEach(Object price);

  /// No description provided for @golf_booking_extraLine.
  ///
  /// In en, this message translates to:
  /// **'{name} × {count}'**
  String golf_booking_extraLine(Object name, Object count);

  /// No description provided for @golf_booking_extraNames_caddie.
  ///
  /// In en, this message translates to:
  /// **'Caddie'**
  String get golf_booking_extraNames_caddie;

  /// No description provided for @golf_booking_extraNames_cart.
  ///
  /// In en, this message translates to:
  /// **'Golf cart'**
  String get golf_booking_extraNames_cart;

  /// No description provided for @golf_booking_extraNames_club_rental.
  ///
  /// In en, this message translates to:
  /// **'Club rental'**
  String get golf_booking_extraNames_club_rental;

  /// No description provided for @golf_booking_extraNames_lessons.
  ///
  /// In en, this message translates to:
  /// **'Golf lesson'**
  String get golf_booking_extraNames_lessons;

  /// No description provided for @golf_booking_extraNames_range_balls.
  ///
  /// In en, this message translates to:
  /// **'Bucket of range balls'**
  String get golf_booking_extraNames_range_balls;

  /// No description provided for @golf_booking_extraRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove one: {name}'**
  String golf_booking_extraRemove(Object name);

  /// No description provided for @golf_booking_extrasHeading.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get golf_booking_extrasHeading;

  /// No description provided for @golf_booking_extrasHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. Our team arranges them with the course when confirming your tee time.'**
  String get golf_booking_extrasHint;

  /// No description provided for @golf_booking_extrasUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The extras on offer have changed. Please review them and try again.'**
  String get golf_booking_extrasUnavailable;

  /// No description provided for @golf_booking_finishPaying.
  ///
  /// In en, this message translates to:
  /// **'Finish paying'**
  String get golf_booking_finishPaying;

  /// No description provided for @golf_booking_freeCancelEnded.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation ended on {date}. To change this booking, please talk to us.'**
  String golf_booking_freeCancelEnded(Object date);

  /// No description provided for @golf_booking_freeCancelUntil.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation until {date}.'**
  String golf_booking_freeCancelUntil(Object date);

  /// No description provided for @golf_booking_greenFee.
  ///
  /// In en, this message translates to:
  /// **'Green fees'**
  String get golf_booking_greenFee;

  /// No description provided for @golf_booking_holdRanOutBody.
  ///
  /// In en, this message translates to:
  /// **'We released your spots after 15 minutes. Nothing was charged.'**
  String get golf_booking_holdRanOutBody;

  /// No description provided for @golf_booking_holdRanOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Your hold ran out'**
  String get golf_booking_holdRanOutTitle;

  /// No description provided for @golf_booking_holdTimer.
  ///
  /// In en, this message translates to:
  /// **'Your spots are held for {time}.'**
  String golf_booking_holdTimer(Object time);

  /// No description provided for @golf_booking_howItWorks.
  ///
  /// In en, this message translates to:
  /// **'Your card is authorised now and charged only once the course confirms your tee time, within 48 hours at most. If the course can’t take you, the hold is released and you’re not charged.'**
  String get golf_booking_howItWorks;

  /// No description provided for @golf_booking_keepBooking.
  ///
  /// In en, this message translates to:
  /// **'Keep my booking'**
  String get golf_booking_keepBooking;

  /// No description provided for @golf_booking_leadName.
  ///
  /// In en, this message translates to:
  /// **'Lead player'**
  String get golf_booking_leadName;

  /// No description provided for @golf_booking_leadNameHint.
  ///
  /// In en, this message translates to:
  /// **'The name the course will have on its sheet.'**
  String get golf_booking_leadNameHint;

  /// No description provided for @golf_booking_leadNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the lead player’s name.'**
  String get golf_booking_leadNameRequired;

  /// No description provided for @golf_booking_metaTitle.
  ///
  /// In en, this message translates to:
  /// **'Book your tee time'**
  String get golf_booking_metaTitle;

  /// No description provided for @golf_booking_missingBody.
  ///
  /// In en, this message translates to:
  /// **'It may belong to another account. Check you’re signed in with the email you booked with.'**
  String get golf_booking_missingBody;

  /// No description provided for @golf_booking_missingTitle.
  ///
  /// In en, this message translates to:
  /// **'We can’t find this booking'**
  String get golf_booking_missingTitle;

  /// No description provided for @golf_booking_noFreeCancel.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation has already passed for this tee time, so once it’s confirmed it can’t be cancelled online.'**
  String get golf_booking_noFreeCancel;

  /// No description provided for @golf_booking_payButton.
  ///
  /// In en, this message translates to:
  /// **'Request this tee time · {amount}'**
  String golf_booking_payButton(Object amount);

  /// No description provided for @golf_booking_payFailed.
  ///
  /// In en, this message translates to:
  /// **'Your card couldn’t be authorised. Please try again.'**
  String get golf_booking_payFailed;

  /// No description provided for @golf_booking_paying.
  ///
  /// In en, this message translates to:
  /// **'Authorising your card…'**
  String get golf_booking_paying;

  /// No description provided for @golf_booking_pickAnother.
  ///
  /// In en, this message translates to:
  /// **'Pick another time'**
  String get golf_booking_pickAnother;

  /// No description provided for @golf_booking_players.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get golf_booking_players;

  /// No description provided for @golf_booking_priceChanged.
  ///
  /// In en, this message translates to:
  /// **'The price of this tee time has just changed. Please check the new total before you continue.'**
  String get golf_booking_priceChanged;

  /// No description provided for @golf_booking_reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get golf_booking_reference;

  /// No description provided for @golf_booking_refundNote.
  ///
  /// In en, this message translates to:
  /// **'You’ll get {amount} back, the whole amount including the service fee.'**
  String golf_booking_refundNote(Object amount);

  /// No description provided for @golf_booking_refunded.
  ///
  /// In en, this message translates to:
  /// **'We’ve refunded {amount}. It can take 5–10 business days to appear on your statement.'**
  String golf_booking_refunded(Object amount);

  /// No description provided for @golf_booking_serviceFee.
  ///
  /// In en, this message translates to:
  /// **'Service fee'**
  String get golf_booking_serviceFee;

  /// No description provided for @golf_booking_startError.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t start the payment. Please try again.'**
  String get golf_booking_startError;

  /// No description provided for @golf_booking_starting.
  ///
  /// In en, this message translates to:
  /// **'Holding your spots…'**
  String get golf_booking_starting;

  /// No description provided for @golf_booking_status_cancelledByTeam_body.
  ///
  /// In en, this message translates to:
  /// **'You weren’t charged, and the hold on your card has been released.'**
  String get golf_booking_status_cancelledByTeam_body;

  /// No description provided for @golf_booking_status_cancelledByTeam_title.
  ///
  /// In en, this message translates to:
  /// **'The course had to cancel this tee time'**
  String get golf_booking_status_cancelledByTeam_title;

  /// No description provided for @golf_booking_status_cancelled_body.
  ///
  /// In en, this message translates to:
  /// **'You weren’t charged, and the hold on your card has been released.'**
  String get golf_booking_status_cancelled_body;

  /// No description provided for @golf_booking_status_cancelled_title.
  ///
  /// In en, this message translates to:
  /// **'This booking is cancelled'**
  String get golf_booking_status_cancelled_title;

  /// No description provided for @golf_booking_status_confirmed_body.
  ///
  /// In en, this message translates to:
  /// **'The course has confirmed your tee time and your card has been charged.'**
  String get golf_booking_status_confirmed_body;

  /// No description provided for @golf_booking_status_confirmed_title.
  ///
  /// In en, this message translates to:
  /// **'You’re booked'**
  String get golf_booking_status_confirmed_title;

  /// No description provided for @golf_booking_status_declined_body.
  ///
  /// In en, this message translates to:
  /// **'Your card wasn’t charged, and the hold on it has been released. Please pick another time.'**
  String get golf_booking_status_declined_body;

  /// No description provided for @golf_booking_status_declined_title.
  ///
  /// In en, this message translates to:
  /// **'The course couldn’t take this tee time'**
  String get golf_booking_status_declined_title;

  /// No description provided for @golf_booking_status_expired_body.
  ///
  /// In en, this message translates to:
  /// **'It wasn’t paid for in time, so nothing was charged and the spots were released.'**
  String get golf_booking_status_expired_body;

  /// No description provided for @golf_booking_status_expired_title.
  ///
  /// In en, this message translates to:
  /// **'This booking ran out'**
  String get golf_booking_status_expired_title;

  /// No description provided for @golf_booking_status_held_body.
  ///
  /// In en, this message translates to:
  /// **'Your spots are held until {holdEnds}. Finish paying to send your request to the course.'**
  String golf_booking_status_held_body(Object holdEnds);

  /// No description provided for @golf_booking_status_held_title.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your payment'**
  String get golf_booking_status_held_title;

  /// No description provided for @golf_booking_status_notAnswered_body.
  ///
  /// In en, this message translates to:
  /// **'Your card wasn’t charged, and the hold on it has been released. We’re sorry. Please pick another time.'**
  String get golf_booking_status_notAnswered_body;

  /// No description provided for @golf_booking_status_notAnswered_title.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t confirm this in time'**
  String get golf_booking_status_notAnswered_title;

  /// No description provided for @golf_booking_status_requested_body.
  ///
  /// In en, this message translates to:
  /// **'Your card is authorised, not charged. We’ll have an answer by {deadline}. If the course can’t take you, the hold is released and you pay nothing.'**
  String golf_booking_status_requested_body(Object deadline);

  /// No description provided for @golf_booking_status_requested_title.
  ///
  /// In en, this message translates to:
  /// **'We’re checking with the course'**
  String get golf_booking_status_requested_title;

  /// No description provided for @golf_booking_supportDraft.
  ///
  /// In en, this message translates to:
  /// **'Hi! I’d like to ask about changing my golf booking {reference}.'**
  String golf_booking_supportDraft(Object reference);

  /// No description provided for @golf_booking_time.
  ///
  /// In en, this message translates to:
  /// **'Tee time'**
  String get golf_booking_time;

  /// No description provided for @golf_booking_title.
  ///
  /// In en, this message translates to:
  /// **'Book your tee time'**
  String get golf_booking_title;

  /// No description provided for @golf_booking_tooFewSpots.
  ///
  /// In en, this message translates to:
  /// **'Only {count, plural, one {# spot is} other {# spots are}} left on this tee time. Nothing was charged.'**
  String golf_booking_tooFewSpots(num count);

  /// No description provided for @golf_booking_tooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get golf_booking_tooMany;

  /// No description provided for @golf_booking_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get golf_booking_total;

  /// No description provided for @golf_booking_unavailableBody.
  ///
  /// In en, this message translates to:
  /// **'It has been taken or closed since you picked it. Nothing was charged.'**
  String get golf_booking_unavailableBody;

  /// No description provided for @golf_booking_unavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'This tee time is no longer available'**
  String get golf_booking_unavailableTitle;

  /// No description provided for @golf_booking_yourBooking.
  ///
  /// In en, this message translates to:
  /// **'Your golf booking'**
  String get golf_booking_yourBooking;

  /// No description provided for @golf_breadcrumb.
  ///
  /// In en, this message translates to:
  /// **'Golf'**
  String get golf_breadcrumb;

  /// No description provided for @golf_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# course} other {# courses}}'**
  String golf_count(num count);

  /// No description provided for @golf_countIn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# course} other {# courses}} in {country}'**
  String golf_countIn(num count, Object country);

  /// No description provided for @golf_courseMetaTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} — golf'**
  String golf_courseMetaTitle(Object name);

  /// No description provided for @golf_emptyBody.
  ///
  /// In en, this message translates to:
  /// **'We\'re adding golf courses. Check back soon.'**
  String get golf_emptyBody;

  /// No description provided for @golf_emptyCountryBody.
  ///
  /// In en, this message translates to:
  /// **'Try another country, or see every course.'**
  String get golf_emptyCountryBody;

  /// No description provided for @golf_emptyCountryTitle.
  ///
  /// In en, this message translates to:
  /// **'No courses in {country}'**
  String golf_emptyCountryTitle(Object country);

  /// No description provided for @golf_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No courses yet'**
  String get golf_emptyTitle;

  /// No description provided for @golf_errorBody.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Please try again.'**
  String get golf_errorBody;

  /// No description provided for @golf_errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Golf courses didn\'t load'**
  String get golf_errorTitle;

  /// No description provided for @golf_eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Golf'**
  String get golf_eyebrow;

  /// No description provided for @golf_filterLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter by country'**
  String get golf_filterLabel;

  /// No description provided for @golf_fromLabel.
  ///
  /// In en, this message translates to:
  /// **'Green fees from'**
  String get golf_fromLabel;

  /// No description provided for @golf_greenFeesFrom.
  ///
  /// In en, this message translates to:
  /// **'Green fees from {price}'**
  String golf_greenFeesFrom(Object price);

  /// No description provided for @golf_guidePrice.
  ///
  /// In en, this message translates to:
  /// **'A guide price per player. We confirm the exact fee when you ask about a tee time.'**
  String get golf_guidePrice;

  /// No description provided for @golf_holes.
  ///
  /// In en, this message translates to:
  /// **'{holes} holes'**
  String golf_holes(Object holes);

  /// No description provided for @golf_metaDescription.
  ///
  /// In en, this message translates to:
  /// **'Golf courses our team can arrange play at, with a guide green fee and tee times on request.'**
  String get golf_metaDescription;

  /// No description provided for @golf_metaTitle.
  ///
  /// In en, this message translates to:
  /// **'Golf courses'**
  String get golf_metaTitle;

  /// No description provided for @golf_missingBody.
  ///
  /// In en, this message translates to:
  /// **'It may have been removed. See the courses we can arrange.'**
  String get golf_missingBody;

  /// No description provided for @golf_missingTitle.
  ///
  /// In en, this message translates to:
  /// **'This course isn\'t available'**
  String get golf_missingTitle;

  /// No description provided for @golf_par.
  ///
  /// In en, this message translates to:
  /// **'Par {par}'**
  String golf_par(Object par);

  /// No description provided for @golf_photo.
  ///
  /// In en, this message translates to:
  /// **'Photo {n}'**
  String golf_photo(Object n);

  /// No description provided for @golf_retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get golf_retry;

  /// No description provided for @golf_seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all courses'**
  String get golf_seeAll;

  /// No description provided for @golf_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Courses our team can arrange play at. Pick one and ask us about tee times.'**
  String get golf_subtitle;

  /// No description provided for @golf_teeTimes_askThis.
  ///
  /// In en, this message translates to:
  /// **'Ask about this tee time'**
  String get golf_teeTimes_askThis;

  /// No description provided for @golf_teeTimes_book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get golf_teeTimes_book;

  /// No description provided for @golf_teeTimes_chargedAfter.
  ///
  /// In en, this message translates to:
  /// **'Your card is only charged once the course confirms.'**
  String get golf_teeTimes_chargedAfter;

  /// No description provided for @golf_teeTimes_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get golf_teeTimes_date;

  /// No description provided for @golf_teeTimes_draft.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'d like to play {course} on {date} at {time} ({city} time) for {count, plural, one {# player} other {# players}}. Is it available?'**
  String golf_teeTimes_draft(
    num count,
    Object course,
    Object date,
    Object time,
    Object city,
  );

  /// No description provided for @golf_teeTimes_earlierDays.
  ///
  /// In en, this message translates to:
  /// **'Earlier days'**
  String get golf_teeTimes_earlierDays;

  /// No description provided for @golf_teeTimes_earlierTimes.
  ///
  /// In en, this message translates to:
  /// **'Earlier times'**
  String get golf_teeTimes_earlierTimes;

  /// No description provided for @golf_teeTimes_justGone.
  ///
  /// In en, this message translates to:
  /// **'That time has just gone. Please pick another.'**
  String get golf_teeTimes_justGone;

  /// No description provided for @golf_teeTimes_laterDays.
  ///
  /// In en, this message translates to:
  /// **'Later days'**
  String get golf_teeTimes_laterDays;

  /// No description provided for @golf_teeTimes_laterTimes.
  ///
  /// In en, this message translates to:
  /// **'Later times'**
  String get golf_teeTimes_laterTimes;

  /// No description provided for @golf_teeTimes_loadError.
  ///
  /// In en, this message translates to:
  /// **'Tee times didn\'t load.'**
  String get golf_teeTimes_loadError;

  /// No description provided for @golf_teeTimes_nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get golf_teeTimes_nextMonth;

  /// No description provided for @golf_teeTimes_none.
  ///
  /// In en, this message translates to:
  /// **'No tee times left on this day. Try another date.'**
  String get golf_teeTimes_none;

  /// No description provided for @golf_teeTimes_pickHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a time to book it.'**
  String get golf_teeTimes_pickHint;

  /// No description provided for @golf_teeTimes_playerCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# player} other {# players}}'**
  String golf_teeTimes_playerCount(num count);

  /// No description provided for @golf_teeTimes_players.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get golf_teeTimes_players;

  /// No description provided for @golf_teeTimes_prevMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get golf_teeTimes_prevMonth;

  /// No description provided for @golf_teeTimes_priceNote.
  ///
  /// In en, this message translates to:
  /// **'All-in price per player for {count, plural, one {# player} other {# players}}, service fee included. It changes with the size of the party.'**
  String golf_teeTimes_priceNote(num count);

  /// No description provided for @golf_teeTimes_priceOnRequest.
  ///
  /// In en, this message translates to:
  /// **'Price on request'**
  String get golf_teeTimes_priceOnRequest;

  /// No description provided for @golf_teeTimes_spotsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String golf_teeTimes_spotsLeft(Object count);

  /// No description provided for @golf_teeTimes_summary.
  ///
  /// In en, this message translates to:
  /// **'{date} · {time} · {count, plural, one {# player} other {# players}}'**
  String golf_teeTimes_summary(num count, Object date, Object time);

  /// No description provided for @golf_teeTimes_title.
  ///
  /// In en, this message translates to:
  /// **'Book a tee time'**
  String get golf_teeTimes_title;

  /// No description provided for @golf_teeTimes_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get golf_teeTimes_total;

  /// No description provided for @golf_title.
  ///
  /// In en, this message translates to:
  /// **'Golf courses'**
  String get golf_title;

  /// No description provided for @guestFavorites_allFavoritesCount.
  ///
  /// In en, this message translates to:
  /// **'All {count} favorites'**
  String guestFavorites_allFavoritesCount(Object count);

  /// No description provided for @guestFavorites_collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse ↑'**
  String get guestFavorites_collapse;

  /// No description provided for @guestFavorites_headerHighlight.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get guestFavorites_headerHighlight;

  /// No description provided for @guestFavorites_headerMain.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guestFavorites_headerMain;

  /// No description provided for @guestFavorites_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Top-rated hotels loved by travellers · updated daily'**
  String get guestFavorites_subtitle;

  /// No description provided for @help_chatCta.
  ///
  /// In en, this message translates to:
  /// **'Chat with us'**
  String get help_chatCta;

  /// No description provided for @help_chatNote.
  ///
  /// In en, this message translates to:
  /// **'Support is answered inside your account, so your conversation is waiting for you whenever you come back. Sign in to start one.'**
  String get help_chatNote;

  /// No description provided for @help_contactHeading.
  ///
  /// In en, this message translates to:
  /// **'Prefer email?'**
  String get help_contactHeading;

  /// No description provided for @help_description.
  ///
  /// In en, this message translates to:
  /// **'Answers about bookings, refunds and payments, and how to reach our team.'**
  String get help_description;

  /// No description provided for @help_pageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Answers to the things people ask most, and a way to reach a person.'**
  String get help_pageSubtitle;

  /// No description provided for @help_pageTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help_pageTitle;

  /// No description provided for @help_sections_changes_body.
  ///
  /// In en, this message translates to:
  /// **'Cancellation is done from Trips, and what it costs depends on the rate: some are free until a deadline, some are not refundable at any point. The deadline is on the booking. Changing dates or names is not something we can do directly — cancel and rebook if the rate allows it, and message us first if you are unsure.'**
  String get help_sections_changes_body;

  /// No description provided for @help_sections_changes_title.
  ///
  /// In en, this message translates to:
  /// **'Can I change or cancel a booking?'**
  String get help_sections_changes_title;

  /// No description provided for @help_sections_confirmation_body.
  ///
  /// In en, this message translates to:
  /// **'Check Trips while signed in with the account you booked on — a booking appears there as soon as the supplier confirms it, usually within a minute. If your card was charged and nothing is in Trips, tell us: that is the one case we want to hear about immediately, because it means a booking exists somewhere we cannot see.'**
  String get help_sections_confirmation_body;

  /// No description provided for @help_sections_confirmation_title.
  ///
  /// In en, this message translates to:
  /// **'I booked, but I have no confirmation'**
  String get help_sections_confirmation_title;

  /// No description provided for @help_sections_payment_body.
  ///
  /// In en, this message translates to:
  /// **'That charge is an authorisation that was never completed, and your bank releases it on its own, usually within a few days. If it has not cleared, or if you were charged and a booking does exist that you did not intend, message us with the reference and we will trace it.'**
  String get help_sections_payment_body;

  /// No description provided for @help_sections_payment_title.
  ///
  /// In en, this message translates to:
  /// **'My card was charged but the booking failed'**
  String get help_sections_payment_title;

  /// No description provided for @help_sections_priceGap_body.
  ///
  /// In en, this message translates to:
  /// **'A search result shows the supplier price converted to your currency. Our fee is added at checkout, so the total is higher than the figure you first saw, and it is shown in full before you pay. Nothing is added after that.'**
  String get help_sections_priceGap_body;

  /// No description provided for @help_sections_priceGap_title.
  ///
  /// In en, this message translates to:
  /// **'Why is the total higher than the price I searched?'**
  String get help_sections_priceGap_title;

  /// No description provided for @help_sections_refunds_body.
  ///
  /// In en, this message translates to:
  /// **'A refund goes back to the card that paid, and how long it takes is decided by your bank rather than by us — commonly five to ten working days after we send it. Whether a booking can be refunded at all depends on the rate you chose, which is shown before you pay and again on the booking itself.'**
  String get help_sections_refunds_body;

  /// No description provided for @help_sections_refunds_link.
  ///
  /// In en, this message translates to:
  /// **'Read the refund policy'**
  String get help_sections_refunds_link;

  /// No description provided for @help_sections_refunds_title.
  ///
  /// In en, this message translates to:
  /// **'When do I get my refund?'**
  String get help_sections_refunds_title;

  /// No description provided for @help_title.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help_title;

  /// No description provided for @hotels_allHotelsCount.
  ///
  /// In en, this message translates to:
  /// **'All {count} hotels'**
  String hotels_allHotelsCount(Object count);

  /// No description provided for @hotels_bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get hotels_bookNow;

  /// No description provided for @hotels_collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse ↑'**
  String get hotels_collapse;

  /// No description provided for @hotels_description_checkIn.
  ///
  /// In en, this message translates to:
  /// **'CHECK-IN'**
  String get hotels_description_checkIn;

  /// No description provided for @hotels_description_checkOut.
  ///
  /// In en, this message translates to:
  /// **'OUT'**
  String get hotels_description_checkOut;

  /// No description provided for @hotels_description_rating.
  ///
  /// In en, this message translates to:
  /// **'rating'**
  String get hotels_description_rating;

  /// No description provided for @hotels_filters_adjustPrice.
  ///
  /// In en, this message translates to:
  /// **'Adjust Price'**
  String get hotels_filters_adjustPrice;

  /// No description provided for @hotels_filters_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get hotels_filters_clear;

  /// No description provided for @hotels_filters_close.
  ///
  /// In en, this message translates to:
  /// **'Close filters'**
  String get hotels_filters_close;

  /// No description provided for @hotels_filters_hide.
  ///
  /// In en, this message translates to:
  /// **'Hide filters'**
  String get hotels_filters_hide;

  /// No description provided for @hotels_filters_maxPerNight.
  ///
  /// In en, this message translates to:
  /// **'Maximum price per night'**
  String get hotels_filters_maxPerNight;

  /// No description provided for @hotels_filters_minPerNight.
  ///
  /// In en, this message translates to:
  /// **'Minimum price per night'**
  String get hotels_filters_minPerNight;

  /// No description provided for @hotels_filters_reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get hotels_filters_reset;

  /// No description provided for @hotels_filters_show.
  ///
  /// In en, this message translates to:
  /// **'Show filters'**
  String get hotels_filters_show;

  /// No description provided for @hotels_fromPrice.
  ///
  /// In en, this message translates to:
  /// **'From {price}'**
  String hotels_fromPrice(Object price);

  /// No description provided for @hotels_guestFavorite.
  ///
  /// In en, this message translates to:
  /// **'Guest Favorite'**
  String get hotels_guestFavorite;

  /// No description provided for @hotels_headerDefault.
  ///
  /// In en, this message translates to:
  /// **'Top Hotel Deals'**
  String get hotels_headerDefault;

  /// No description provided for @hotels_headerPersonalized.
  ///
  /// In en, this message translates to:
  /// **'Hotel Deals in {country}'**
  String hotels_headerPersonalized(Object country);

  /// No description provided for @hotels_maintenance_description.
  ///
  /// In en, this message translates to:
  /// **'Our accommodation supplier isn\'t returning availability right now. Nothing on your end caused this, and we\'re working to bring stays back.'**
  String get hotels_maintenance_description;

  /// No description provided for @hotels_maintenance_flightsCta.
  ///
  /// In en, this message translates to:
  /// **'Search flights'**
  String get hotels_maintenance_flightsCta;

  /// No description provided for @hotels_maintenance_homeCta.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get hotels_maintenance_homeCta;

  /// No description provided for @hotels_maintenance_note.
  ///
  /// In en, this message translates to:
  /// **'Flights are unaffected'**
  String get hotels_maintenance_note;

  /// No description provided for @hotels_maintenance_title.
  ///
  /// In en, this message translates to:
  /// **'Hotel bookings are paused'**
  String get hotels_maintenance_title;

  /// No description provided for @hotels_nearby_none.
  ///
  /// In en, this message translates to:
  /// **'No places found nearby.'**
  String get hotels_nearby_none;

  /// No description provided for @hotels_perNight.
  ///
  /// In en, this message translates to:
  /// **'/night'**
  String get hotels_perNight;

  /// No description provided for @hotels_pricesMayVary.
  ///
  /// In en, this message translates to:
  /// **'prices may vary'**
  String get hotels_pricesMayVary;

  /// No description provided for @hotels_ratings_average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get hotels_ratings_average;

  /// No description provided for @hotels_ratings_excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get hotels_ratings_excellent;

  /// No description provided for @hotels_ratings_exceptional.
  ///
  /// In en, this message translates to:
  /// **'Exceptional'**
  String get hotels_ratings_exceptional;

  /// No description provided for @hotels_ratings_good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get hotels_ratings_good;

  /// No description provided for @hotels_ratings_superb.
  ///
  /// In en, this message translates to:
  /// **'Superb'**
  String get hotels_ratings_superb;

  /// No description provided for @hotels_ratings_veryGood.
  ///
  /// In en, this message translates to:
  /// **'Very Good'**
  String get hotels_ratings_veryGood;

  /// No description provided for @hotels_results_datesPicked.
  ///
  /// In en, this message translates to:
  /// **'We picked these dates — change them to see other prices.'**
  String get hotels_results_datesPicked;

  /// No description provided for @hotels_results_loadingPrices.
  ///
  /// In en, this message translates to:
  /// **'Loading prices…'**
  String get hotels_results_loadingPrices;

  /// No description provided for @hotels_results_noMatchHint.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters, dates, or searching a nearby city.'**
  String get hotels_results_noMatchHint;

  /// No description provided for @hotels_results_searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed.'**
  String get hotels_results_searchFailed;

  /// No description provided for @hotels_review_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Tell others about your stay...'**
  String get hotels_review_placeholder;

  /// No description provided for @hotels_review_shareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share your experience'**
  String get hotels_review_shareTitle;

  /// No description provided for @hotels_review_thanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your review!'**
  String get hotels_review_thanks;

  /// No description provided for @hotels_rooms_nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get hotels_rooms_nextPage;

  /// No description provided for @hotels_rooms_noMatch.
  ///
  /// In en, this message translates to:
  /// **'No rooms match that rate. Try another filter.'**
  String get hotels_rooms_noMatch;

  /// No description provided for @hotels_rooms_nonRefundable.
  ///
  /// In en, this message translates to:
  /// **'Non-refundable'**
  String get hotels_rooms_nonRefundable;

  /// No description provided for @hotels_rooms_pages.
  ///
  /// In en, this message translates to:
  /// **'Room pages'**
  String get hotels_rooms_pages;

  /// No description provided for @hotels_rooms_prevPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get hotels_rooms_prevPage;

  /// No description provided for @hotels_rooms_refundable.
  ///
  /// In en, this message translates to:
  /// **'Refundable'**
  String get hotels_rooms_refundable;

  /// No description provided for @hotels_rooms_roomDetails.
  ///
  /// In en, this message translates to:
  /// **'Room details'**
  String get hotels_rooms_roomDetails;

  /// No description provided for @hotels_subtitleDefault.
  ///
  /// In en, this message translates to:
  /// **'Handpicked stays at unbeatable prices'**
  String get hotels_subtitleDefault;

  /// No description provided for @hotels_subtitlePersonalized.
  ///
  /// In en, this message translates to:
  /// **'Top-rated stays in {country} · updated daily'**
  String hotels_subtitlePersonalized(Object country);

  /// No description provided for @invoice_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get invoice_amount;

  /// No description provided for @invoice_billedTo.
  ///
  /// In en, this message translates to:
  /// **'Billed to'**
  String get invoice_billedTo;

  /// No description provided for @invoice_bookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get invoice_bookingDetails;

  /// No description provided for @invoice_bookingRef.
  ///
  /// In en, this message translates to:
  /// **'Booking Ref'**
  String get invoice_bookingRef;

  /// No description provided for @invoice_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get invoice_date;

  /// No description provided for @invoice_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get invoice_description;

  /// No description provided for @invoice_flight.
  ///
  /// In en, this message translates to:
  /// **'Flight'**
  String get invoice_flight;

  /// No description provided for @invoice_hotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get invoice_hotel;

  /// No description provided for @invoice_hotelPartner.
  ///
  /// In en, this message translates to:
  /// **'Hotel Partner'**
  String get invoice_hotelPartner;

  /// No description provided for @invoice_issued.
  ///
  /// In en, this message translates to:
  /// **'Issued: {date}'**
  String invoice_issued(Object date);

  /// No description provided for @invoice_passengers.
  ///
  /// In en, this message translates to:
  /// **'Passengers'**
  String get invoice_passengers;

  /// No description provided for @invoice_payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get invoice_payment;

  /// No description provided for @invoice_paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Stripe (Card)'**
  String get invoice_paymentMethod;

  /// No description provided for @invoice_provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get invoice_provider;

  /// No description provided for @invoice_receipt.
  ///
  /// In en, this message translates to:
  /// **'RECEIPT'**
  String get invoice_receipt;

  /// No description provided for @invoice_route.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get invoice_route;

  /// No description provided for @invoice_thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for booking with CheapestGo. For support, contact'**
  String get invoice_thankYou;

  /// No description provided for @invoice_totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get invoice_totalPaid;

  /// No description provided for @invoice_type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get invoice_type;

  /// No description provided for @invoice_yourTravelPartner.
  ///
  /// In en, this message translates to:
  /// **'Your Travel Partner'**
  String get invoice_yourTravelPartner;

  /// No description provided for @landing_deals_save.
  ///
  /// In en, this message translates to:
  /// **'Save deal'**
  String get landing_deals_save;

  /// No description provided for @landing_faq_eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Before you book'**
  String get landing_faq_eyebrow;

  /// No description provided for @landing_flightRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Round trip, all-in, next 60 days'**
  String get landing_flightRowSubtitle;

  /// No description provided for @landing_hero_blurb.
  ///
  /// In en, this message translates to:
  /// **'Every major flight and hotel supplier, compared at once. Taxes and fees included, no booking fee.'**
  String get landing_hero_blurb;

  /// No description provided for @landing_hero_checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get landing_hero_checkIn;

  /// No description provided for @landing_hero_checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check out'**
  String get landing_hero_checkOut;

  /// No description provided for @landing_hero_cta.
  ///
  /// In en, this message translates to:
  /// **'Search flights'**
  String get landing_hero_cta;

  /// No description provided for @landing_hero_flightType.
  ///
  /// In en, this message translates to:
  /// **'Flight type'**
  String get landing_hero_flightType;

  /// No description provided for @landing_hero_guests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get landing_hero_guests;

  /// No description provided for @landing_hero_maxBudget.
  ///
  /// In en, this message translates to:
  /// **'Maximum budget'**
  String get landing_hero_maxBudget;

  /// No description provided for @landing_hero_maxTripBudget.
  ///
  /// In en, this message translates to:
  /// **'Maximum trip budget'**
  String get landing_hero_maxTripBudget;

  /// No description provided for @landing_hero_monoSubtext.
  ///
  /// In en, this message translates to:
  /// **'Ask anything. Book everything.'**
  String get landing_hero_monoSubtext;

  /// No description provided for @landing_hero_searchFlights.
  ///
  /// In en, this message translates to:
  /// **'Search flights'**
  String get landing_hero_searchFlights;

  /// No description provided for @landing_hero_searchHotels.
  ///
  /// In en, this message translates to:
  /// **'Search hotels'**
  String get landing_hero_searchHotels;

  /// No description provided for @landing_hero_searchType.
  ///
  /// In en, this message translates to:
  /// **'Search type'**
  String get landing_hero_searchType;

  /// No description provided for @landing_hero_subtitle.
  ///
  /// In en, this message translates to:
  /// **'The operating system for the modern voyager.'**
  String get landing_hero_subtitle;

  /// No description provided for @landing_hero_tabs_budget.
  ///
  /// In en, this message translates to:
  /// **'Where can I go?'**
  String get landing_hero_tabs_budget;

  /// No description provided for @landing_hero_tabs_flights.
  ///
  /// In en, this message translates to:
  /// **'Flights'**
  String get landing_hero_tabs_flights;

  /// No description provided for @landing_hero_tabs_hotels.
  ///
  /// In en, this message translates to:
  /// **'Hotels'**
  String get landing_hero_tabs_hotels;

  /// No description provided for @landing_hero_title.
  ///
  /// In en, this message translates to:
  /// **'Flights at the lowest price'**
  String get landing_hero_title;

  /// No description provided for @landing_hero_titleBottom.
  ///
  /// In en, this message translates to:
  /// **'for less.'**
  String get landing_hero_titleBottom;

  /// No description provided for @landing_hero_titleLine1.
  ///
  /// In en, this message translates to:
  /// **'Precision Travel.'**
  String get landing_hero_titleLine1;

  /// No description provided for @landing_hero_titleLine2.
  ///
  /// In en, this message translates to:
  /// **'Machined for You.'**
  String get landing_hero_titleLine2;

  /// No description provided for @landing_hero_titleTop.
  ///
  /// In en, this message translates to:
  /// **'Fly anywhere'**
  String get landing_hero_titleTop;

  /// No description provided for @landing_hero_travelers.
  ///
  /// In en, this message translates to:
  /// **'Travelers'**
  String get landing_hero_travelers;

  /// No description provided for @landing_hero_whatAfter.
  ///
  /// In en, this message translates to:
  /// **'What are you after?'**
  String get landing_hero_whatAfter;

  /// No description provided for @landing_hero_where.
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get landing_hero_where;

  /// No description provided for @landing_hotelRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Total price per night, taxes and resort fees included'**
  String get landing_hotelRowSubtitle;

  /// No description provided for @landing_hotelRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Stays travelers are booking'**
  String get landing_hotelRowTitle;

  /// No description provided for @landing_howItWorks_steps_book_description.
  ///
  /// In en, this message translates to:
  /// **'Secure your trip in minutes with safe, encrypted checkout. Instant confirmation every time.'**
  String get landing_howItWorks_steps_book_description;

  /// No description provided for @landing_howItWorks_steps_book_title.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get landing_howItWorks_steps_book_title;

  /// No description provided for @landing_howItWorks_steps_compare_description.
  ///
  /// In en, this message translates to:
  /// **'Browse real-time prices across airlines and hotels. Filter by price, rating, or amenities.'**
  String get landing_howItWorks_steps_compare_description;

  /// No description provided for @landing_howItWorks_steps_compare_title.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get landing_howItWorks_steps_compare_title;

  /// No description provided for @landing_howItWorks_steps_search_description.
  ///
  /// In en, this message translates to:
  /// **'Enter your destination, dates, and traveler count to find the best flights and hotels.'**
  String get landing_howItWorks_steps_search_description;

  /// No description provided for @landing_howItWorks_steps_search_title.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get landing_howItWorks_steps_search_title;

  /// No description provided for @landing_howItWorks_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Book your next trip in three simple steps.'**
  String get landing_howItWorks_subtitle;

  /// No description provided for @landing_howItWorks_title.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get landing_howItWorks_title;

  /// No description provided for @landing_journey_altitude_label.
  ///
  /// In en, this message translates to:
  /// **'Alt'**
  String get landing_journey_altitude_label;

  /// No description provided for @landing_journey_altitude_unit.
  ///
  /// In en, this message translates to:
  /// **'ft'**
  String get landing_journey_altitude_unit;

  /// No description provided for @landing_journey_ask_example1.
  ///
  /// In en, this message translates to:
  /// **'Five nights in Seoul under ₱40,000'**
  String get landing_journey_ask_example1;

  /// No description provided for @landing_journey_ask_example2.
  ///
  /// In en, this message translates to:
  /// **'Beach, direct flight, leaving Friday'**
  String get landing_journey_ask_example2;

  /// No description provided for @landing_journey_ask_example3.
  ///
  /// In en, this message translates to:
  /// **'Two cities in Japan, one week'**
  String get landing_journey_ask_example3;

  /// No description provided for @landing_journey_ask_label.
  ///
  /// In en, this message translates to:
  /// **'Describe the trip you want'**
  String get landing_journey_ask_label;

  /// No description provided for @landing_journey_ask_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Describe the trip you want…'**
  String get landing_journey_ask_placeholder;

  /// No description provided for @landing_journey_ask_submit.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get landing_journey_ask_submit;

  /// No description provided for @landing_journey_hero_kicker.
  ///
  /// In en, this message translates to:
  /// **'Hotels · Flights · Golf'**
  String get landing_journey_hero_kicker;

  /// No description provided for @landing_journey_hero_scrollCue.
  ///
  /// In en, this message translates to:
  /// **'Scroll down to explore'**
  String get landing_journey_hero_scrollCue;

  /// No description provided for @landing_journey_hero_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Skip the surprise fees. Chase the sunsets.'**
  String get landing_journey_hero_subtitle;

  /// No description provided for @landing_journey_hero_titleLine1.
  ///
  /// In en, this message translates to:
  /// **'One search.'**
  String get landing_journey_hero_titleLine1;

  /// No description provided for @landing_journey_hero_titleLine2.
  ///
  /// In en, this message translates to:
  /// **'Every way to go.'**
  String get landing_journey_hero_titleLine2;

  /// No description provided for @landing_journey_options_flightsNote.
  ///
  /// In en, this message translates to:
  /// **'Every carrier we reach'**
  String get landing_journey_options_flightsNote;

  /// No description provided for @landing_journey_options_golf.
  ///
  /// In en, this message translates to:
  /// **'Golf'**
  String get landing_journey_options_golf;

  /// No description provided for @landing_journey_options_golfNote.
  ///
  /// In en, this message translates to:
  /// **'Curated courses, tee times on request'**
  String get landing_journey_options_golfNote;

  /// No description provided for @landing_journey_options_staysNote.
  ///
  /// In en, this message translates to:
  /// **'Hotels & homes'**
  String get landing_journey_options_staysNote;

  /// No description provided for @landing_journey_stages_ai_caption.
  ///
  /// In en, this message translates to:
  /// **'Tell us the trip. We\'ll price the stays and routes that fit.'**
  String get landing_journey_stages_ai_caption;

  /// No description provided for @landing_journey_stages_ai_titleLead.
  ///
  /// In en, this message translates to:
  /// **'Or'**
  String get landing_journey_stages_ai_titleLead;

  /// No description provided for @landing_journey_stages_ai_titleRest.
  ///
  /// In en, this message translates to:
  /// **'just ask.'**
  String get landing_journey_stages_ai_titleRest;

  /// No description provided for @landing_journey_stages_flights_caption.
  ///
  /// In en, this message translates to:
  /// **'Every airline, every fare class, sorted by what you actually pay.'**
  String get landing_journey_stages_flights_caption;

  /// No description provided for @landing_journey_stages_flights_titleLead.
  ///
  /// In en, this message translates to:
  /// **'Then'**
  String get landing_journey_stages_flights_titleLead;

  /// No description provided for @landing_journey_stages_flights_titleRest.
  ///
  /// In en, this message translates to:
  /// **'get there.'**
  String get landing_journey_stages_flights_titleRest;

  /// No description provided for @landing_journey_stages_golf_caption.
  ///
  /// In en, this message translates to:
  /// **'Real tee times at courses we work with, priced per player.'**
  String get landing_journey_stages_golf_caption;

  /// No description provided for @landing_journey_stages_golf_titleLead.
  ///
  /// In en, this message translates to:
  /// **'Or'**
  String get landing_journey_stages_golf_titleLead;

  /// No description provided for @landing_journey_stages_golf_titleRest.
  ///
  /// In en, this message translates to:
  /// **'tee off.'**
  String get landing_journey_stages_golf_titleRest;

  /// No description provided for @landing_journey_stages_options_caption.
  ///
  /// In en, this message translates to:
  /// **'Stays, flights and golf, all in one place.'**
  String get landing_journey_stages_options_caption;

  /// No description provided for @landing_journey_stages_options_eyebrow.
  ///
  /// In en, this message translates to:
  /// **'ARRIVAL'**
  String get landing_journey_stages_options_eyebrow;

  /// No description provided for @landing_journey_stages_options_titleLead.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get landing_journey_stages_options_titleLead;

  /// No description provided for @landing_journey_stages_options_titleRest.
  ///
  /// In en, this message translates to:
  /// **'choose.'**
  String get landing_journey_stages_options_titleRest;

  /// No description provided for @landing_journey_stages_stays_caption.
  ///
  /// In en, this message translates to:
  /// **'Hotels and homes, priced per night — every fee shown before you tap book.'**
  String get landing_journey_stages_stays_caption;

  /// No description provided for @landing_journey_stages_stays_titleLead.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get landing_journey_stages_stays_titleLead;

  /// No description provided for @landing_journey_stages_stays_titleRest.
  ///
  /// In en, this message translates to:
  /// **'your stay.'**
  String get landing_journey_stages_stays_titleRest;

  /// No description provided for @landing_journey_strip_from.
  ///
  /// In en, this message translates to:
  /// **'from {price}'**
  String landing_journey_strip_from(Object price);

  /// No description provided for @landing_perNight.
  ///
  /// In en, this message translates to:
  /// **'/ night'**
  String get landing_perNight;

  /// No description provided for @landing_popularDestinations_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore top spots across Asia-Pacific — search flights and hotels in seconds.'**
  String get landing_popularDestinations_subtitle;

  /// No description provided for @landing_popularDestinations_title.
  ///
  /// In en, this message translates to:
  /// **'Popular Destinations'**
  String get landing_popularDestinations_title;

  /// No description provided for @landing_quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get landing_quickAccess;

  /// No description provided for @landing_recentlyViewed_flight.
  ///
  /// In en, this message translates to:
  /// **'Flight'**
  String get landing_recentlyViewed_flight;

  /// No description provided for @landing_recentlyViewed_from.
  ///
  /// In en, this message translates to:
  /// **'from'**
  String get landing_recentlyViewed_from;

  /// No description provided for @landing_recentlyViewed_recentlySearched.
  ///
  /// In en, this message translates to:
  /// **'Recently searched'**
  String get landing_recentlyViewed_recentlySearched;

  /// No description provided for @landing_recentlyViewed_showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get landing_recentlyViewed_showLess;

  /// No description provided for @landing_recentlyViewed_stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get landing_recentlyViewed_stay;

  /// No description provided for @landing_recentlyViewed_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off'**
  String get landing_recentlyViewed_subtitle;

  /// No description provided for @landing_recentlyViewed_title.
  ///
  /// In en, this message translates to:
  /// **'Continue Your Search'**
  String get landing_recentlyViewed_title;

  /// No description provided for @landing_recentlyViewed_viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get landing_recentlyViewed_viewAll;

  /// No description provided for @landing_search_addGuests.
  ///
  /// In en, this message translates to:
  /// **'Add guests'**
  String get landing_search_addGuests;

  /// No description provided for @landing_search_adultAge.
  ///
  /// In en, this message translates to:
  /// **'Age 12+'**
  String get landing_search_adultAge;

  /// No description provided for @landing_search_adults.
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get landing_search_adults;

  /// No description provided for @landing_search_aiDevelopment.
  ///
  /// In en, this message translates to:
  /// **'AI Search is under development. Stay tuned!'**
  String get landing_search_aiDevelopment;

  /// No description provided for @landing_search_aiGreeting.
  ///
  /// In en, this message translates to:
  /// **'How can I help you this morning?'**
  String get landing_search_aiGreeting;

  /// No description provided for @landing_search_anyWeek.
  ///
  /// In en, this message translates to:
  /// **'Any week'**
  String get landing_search_anyWeek;

  /// No description provided for @landing_search_anywhere.
  ///
  /// In en, this message translates to:
  /// **'Anywhere'**
  String get landing_search_anywhere;

  /// No description provided for @landing_search_askAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get landing_search_askAi;

  /// No description provided for @landing_search_bundle_hotelBooked.
  ///
  /// In en, this message translates to:
  /// **'Hotel booked!'**
  String get landing_search_bundle_hotelBooked;

  /// No description provided for @landing_search_bundle_instructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your {from} and {to} airports, pick your dates, then hit Search to bundle and save up to 8%.'**
  String landing_search_bundle_instructions(Object from, Object to);

  /// No description provided for @landing_search_cabinClassLabel.
  ///
  /// In en, this message translates to:
  /// **'Cabin Class'**
  String get landing_search_cabinClassLabel;

  /// No description provided for @landing_search_cabinClass_business.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get landing_search_cabinClass_business;

  /// No description provided for @landing_search_cabinClass_economy.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get landing_search_cabinClass_economy;

  /// No description provided for @landing_search_cabinClass_first.
  ///
  /// In en, this message translates to:
  /// **'First'**
  String get landing_search_cabinClass_first;

  /// No description provided for @landing_search_cabinClass_premiumEconomy.
  ///
  /// In en, this message translates to:
  /// **'Premium economy'**
  String get landing_search_cabinClass_premiumEconomy;

  /// No description provided for @landing_search_calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get landing_search_calendar;

  /// No description provided for @landing_search_checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get landing_search_checkIn;

  /// No description provided for @landing_search_checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get landing_search_checkOut;

  /// No description provided for @landing_search_childAge.
  ///
  /// In en, this message translates to:
  /// **'Age 2-11'**
  String get landing_search_childAge;

  /// No description provided for @landing_search_childLabel.
  ///
  /// In en, this message translates to:
  /// **'Child {index}: {age} yrs'**
  String landing_search_childLabel(Object index, Object age);

  /// No description provided for @landing_search_children.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get landing_search_children;

  /// No description provided for @landing_search_childrenAges.
  ///
  /// In en, this message translates to:
  /// **'Ages 0 to 17'**
  String get landing_search_childrenAges;

  /// No description provided for @landing_search_cities.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get landing_search_cities;

  /// No description provided for @landing_search_clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get landing_search_clearAll;

  /// No description provided for @landing_search_comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get landing_search_comingSoon;

  /// No description provided for @landing_search_countries.
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get landing_search_countries;

  /// No description provided for @landing_search_depart.
  ///
  /// In en, this message translates to:
  /// **'Depart'**
  String get landing_search_depart;

  /// No description provided for @landing_search_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get landing_search_done;

  /// No description provided for @landing_search_findDeals.
  ///
  /// In en, this message translates to:
  /// **'Find the best deals'**
  String get landing_search_findDeals;

  /// No description provided for @landing_search_findingFlights.
  ///
  /// In en, this message translates to:
  /// **'Finding flights…'**
  String get landing_search_findingFlights;

  /// No description provided for @landing_search_flexibleDates.
  ///
  /// In en, this message translates to:
  /// **'Flexible dates'**
  String get landing_search_flexibleDates;

  /// No description provided for @landing_search_from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get landing_search_from;

  /// No description provided for @landing_search_go.
  ///
  /// In en, this message translates to:
  /// **'GO'**
  String get landing_search_go;

  /// No description provided for @landing_search_guest.
  ///
  /// In en, this message translates to:
  /// **'{count} Guest'**
  String landing_search_guest(Object count);

  /// No description provided for @landing_search_guestPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} Guests'**
  String landing_search_guestPlural(Object count);

  /// No description provided for @landing_search_guests.
  ///
  /// In en, this message translates to:
  /// **'{count} guest'**
  String landing_search_guests(Object count);

  /// No description provided for @landing_search_guestsPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} guests'**
  String landing_search_guestsPlural(Object count);

  /// No description provided for @landing_search_guestsRooms.
  ///
  /// In en, this message translates to:
  /// **'Guests & Rooms'**
  String get landing_search_guestsRooms;

  /// No description provided for @landing_search_infantAge.
  ///
  /// In en, this message translates to:
  /// **'Under 2 (lap)'**
  String get landing_search_infantAge;

  /// No description provided for @landing_search_infants.
  ///
  /// In en, this message translates to:
  /// **'Infants'**
  String get landing_search_infants;

  /// No description provided for @landing_search_month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get landing_search_month;

  /// No description provided for @landing_search_noAirportsFound.
  ///
  /// In en, this message translates to:
  /// **'No airports found for \"{query}\"'**
  String landing_search_noAirportsFound(Object query);

  /// No description provided for @landing_search_noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get landing_search_noResults;

  /// No description provided for @landing_search_passengers.
  ///
  /// In en, this message translates to:
  /// **'Passengers'**
  String get landing_search_passengers;

  /// No description provided for @landing_search_placeholder_airport.
  ///
  /// In en, this message translates to:
  /// **'City or airport'**
  String get landing_search_placeholder_airport;

  /// No description provided for @landing_search_placeholder_date.
  ///
  /// In en, this message translates to:
  /// **'Add date'**
  String get landing_search_placeholder_date;

  /// No description provided for @landing_search_recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get landing_search_recentSearches;

  /// No description provided for @landing_search_results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get landing_search_results;

  /// No description provided for @landing_search_return.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get landing_search_return;

  /// No description provided for @landing_search_rooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get landing_search_rooms;

  /// No description provided for @landing_search_roomsNote.
  ///
  /// In en, this message translates to:
  /// **'1 room per booking. Book separately for more.'**
  String get landing_search_roomsNote;

  /// No description provided for @landing_search_searchDestination.
  ///
  /// In en, this message translates to:
  /// **'Search destination'**
  String get landing_search_searchDestination;

  /// No description provided for @landing_search_searchDestinationsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search destinations...'**
  String get landing_search_searchDestinationsPlaceholder;

  /// No description provided for @landing_search_searchFlightsHeader.
  ///
  /// In en, this message translates to:
  /// **'Search Flights'**
  String get landing_search_searchFlightsHeader;

  /// No description provided for @landing_search_searchMode_aiSearch.
  ///
  /// In en, this message translates to:
  /// **'AI Search'**
  String get landing_search_searchMode_aiSearch;

  /// No description provided for @landing_search_searchMode_flights.
  ///
  /// In en, this message translates to:
  /// **'Flights'**
  String get landing_search_searchMode_flights;

  /// No description provided for @landing_search_searchMode_golf.
  ///
  /// In en, this message translates to:
  /// **'Golf'**
  String get landing_search_searchMode_golf;

  /// No description provided for @landing_search_searchMode_stays.
  ///
  /// In en, this message translates to:
  /// **'Stays'**
  String get landing_search_searchMode_stays;

  /// No description provided for @landing_search_searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get landing_search_searching;

  /// No description provided for @landing_search_searchingFlights.
  ///
  /// In en, this message translates to:
  /// **'Searching flights…'**
  String get landing_search_searchingFlights;

  /// No description provided for @landing_search_searchingGolf.
  ///
  /// In en, this message translates to:
  /// **'Finding tee times…'**
  String get landing_search_searchingGolf;

  /// No description provided for @landing_search_searchingStays.
  ///
  /// In en, this message translates to:
  /// **'Searching hotels…'**
  String get landing_search_searchingStays;

  /// No description provided for @landing_search_selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get landing_search_selectDate;

  /// No description provided for @landing_search_submit.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get landing_search_submit;

  /// No description provided for @landing_search_to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get landing_search_to;

  /// No description provided for @landing_search_travelers.
  ///
  /// In en, this message translates to:
  /// **'Travelers'**
  String get landing_search_travelers;

  /// No description provided for @landing_search_tripType_multiCity.
  ///
  /// In en, this message translates to:
  /// **'Multi-city'**
  String get landing_search_tripType_multiCity;

  /// No description provided for @landing_search_tripType_oneWay.
  ///
  /// In en, this message translates to:
  /// **'One way'**
  String get landing_search_tripType_oneWay;

  /// No description provided for @landing_search_tripType_roundTrip.
  ///
  /// In en, this message translates to:
  /// **'Round trip'**
  String get landing_search_tripType_roundTrip;

  /// No description provided for @landing_search_typeToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type city name or airport code...'**
  String get landing_search_typeToSearch;

  /// No description provided for @landing_search_typeToSearchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type a city or airport code to search'**
  String get landing_search_typeToSearchPrompt;

  /// No description provided for @landing_search_whenTravel.
  ///
  /// In en, this message translates to:
  /// **'When do you want to travel?'**
  String get landing_search_whenTravel;

  /// No description provided for @landing_search_whereTo.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get landing_search_whereTo;

  /// No description provided for @landing_search_whosComing.
  ///
  /// In en, this message translates to:
  /// **'Who\'s coming?'**
  String get landing_search_whosComing;

  /// No description provided for @landing_search_year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get landing_search_year;

  /// No description provided for @landing_search_yearsOld.
  ///
  /// In en, this message translates to:
  /// **'{age} years old'**
  String landing_search_yearsOld(Object age);

  /// No description provided for @landing_telemetry_confirmed.
  ///
  /// In en, this message translates to:
  /// **'CONFIRMED'**
  String get landing_telemetry_confirmed;

  /// No description provided for @landing_telemetry_flight.
  ///
  /// In en, this message translates to:
  /// **'Flight'**
  String get landing_telemetry_flight;

  /// No description provided for @landing_telemetry_gate.
  ///
  /// In en, this message translates to:
  /// **'Gate'**
  String get landing_telemetry_gate;

  /// No description provided for @landing_telemetry_humidity.
  ///
  /// In en, this message translates to:
  /// **'HUM: 45%'**
  String get landing_telemetry_humidity;

  /// No description provided for @landing_telemetry_lowDetected.
  ///
  /// In en, this message translates to:
  /// **'24h Low detected. Buy advised.'**
  String get landing_telemetry_lowDetected;

  /// No description provided for @landing_telemetry_smartPriceTracking.
  ///
  /// In en, this message translates to:
  /// **'Smart Price Tracking'**
  String get landing_telemetry_smartPriceTracking;

  /// No description provided for @landing_telemetry_systemNominal.
  ///
  /// In en, this message translates to:
  /// **'System Nominal'**
  String get landing_telemetry_systemNominal;

  /// No description provided for @landing_telemetry_viewBoardingPass.
  ///
  /// In en, this message translates to:
  /// **'View Boarding Pass'**
  String get landing_telemetry_viewBoardingPass;

  /// No description provided for @landing_telemetry_visibility.
  ///
  /// In en, this message translates to:
  /// **'VIS: 10mi'**
  String get landing_telemetry_visibility;

  /// No description provided for @languagePicker_cn.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languagePicker_cn;

  /// No description provided for @languagePicker_en.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languagePicker_en;

  /// No description provided for @languagePicker_ja.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languagePicker_ja;

  /// No description provided for @languagePicker_ko.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get languagePicker_ko;

  /// No description provided for @languagePicker_label.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get languagePicker_label;

  /// No description provided for @legal_content_cookie_changes_body.
  ///
  /// In en, this message translates to:
  /// **'We may update this Cookie Policy from time to time to reflect changes in technology, regulation, or our use of cookies. When we make material changes, we will update the \"Last Updated\" date at the top of this page. Continued use of the Platform after changes are posted constitutes your acceptance of the revised policy.'**
  String get legal_content_cookie_changes_body;

  /// No description provided for @legal_content_cookie_changes_title.
  ///
  /// In en, this message translates to:
  /// **'Changes to This Cookie Policy'**
  String get legal_content_cookie_changes_title;

  /// No description provided for @legal_content_cookie_contact_address.
  ///
  /// In en, this message translates to:
  /// **'🏢 FORHU Inc. · 30 Wall Street, 8th Floor · New York, NY 10005 · USA'**
  String get legal_content_cookie_contact_address;

  /// No description provided for @legal_content_cookie_contact_email.
  ///
  /// In en, this message translates to:
  /// **'📧 support@cheapestgo.com'**
  String get legal_content_cookie_contact_email;

  /// No description provided for @legal_content_cookie_contact_intro.
  ///
  /// In en, this message translates to:
  /// **'For questions about our use of cookies:'**
  String get legal_content_cookie_contact_intro;

  /// No description provided for @legal_content_cookie_contact_title.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get legal_content_cookie_contact_title;

  /// No description provided for @legal_content_cookie_doNotTrack_body.
  ///
  /// In en, this message translates to:
  /// **'Some browsers send a \"Do Not Track\" (DNT) signal. CheapestGo does not currently respond to DNT signals, as there is no universal standard for how websites should react to them. We continue to evaluate this area as standards evolve.'**
  String get legal_content_cookie_doNotTrack_body;

  /// No description provided for @legal_content_cookie_doNotTrack_title.
  ///
  /// In en, this message translates to:
  /// **'Do Not Track'**
  String get legal_content_cookie_doNotTrack_title;

  /// No description provided for @legal_content_cookie_duration_intro.
  ///
  /// In en, this message translates to:
  /// **'Cookies on CheapestGo are either:'**
  String get legal_content_cookie_duration_intro;

  /// No description provided for @legal_content_cookie_duration_title.
  ///
  /// In en, this message translates to:
  /// **'Cookie Duration'**
  String get legal_content_cookie_duration_title;

  /// No description provided for @legal_content_cookie_managing_intro.
  ///
  /// In en, this message translates to:
  /// **'You can control cookies in several ways:'**
  String get legal_content_cookie_managing_intro;

  /// No description provided for @legal_content_cookie_managing_note.
  ///
  /// In en, this message translates to:
  /// **'Adjusting your cookie settings may affect the functionality of the Platform. Essential cookies cannot be disabled without impacting your ability to use CheapestGo.'**
  String get legal_content_cookie_managing_note;

  /// No description provided for @legal_content_cookie_managing_title.
  ///
  /// In en, this message translates to:
  /// **'Managing Your Cookie Preferences'**
  String get legal_content_cookie_managing_title;

  /// No description provided for @legal_content_cookie_thirdParty_intro.
  ///
  /// In en, this message translates to:
  /// **'Some cookies are set by third-party services that appear on our pages:'**
  String get legal_content_cookie_thirdParty_intro;

  /// No description provided for @legal_content_cookie_thirdParty_outro.
  ///
  /// In en, this message translates to:
  /// **'We have no control over third-party cookies. Please review the respective privacy policies of these providers for more information.'**
  String get legal_content_cookie_thirdParty_outro;

  /// No description provided for @legal_content_cookie_thirdParty_stripeBefore.
  ///
  /// In en, this message translates to:
  /// **'sets cookies for fraud detection and payment session management. See'**
  String get legal_content_cookie_thirdParty_stripeBefore;

  /// No description provided for @legal_content_cookie_thirdParty_stripeLinkText.
  ///
  /// In en, this message translates to:
  /// **'Stripe\'s Privacy Policy'**
  String get legal_content_cookie_thirdParty_stripeLinkText;

  /// No description provided for @legal_content_cookie_thirdParty_supabaseText.
  ///
  /// In en, this message translates to:
  /// **'sets authentication cookies to manage your login session on our database infrastructure.'**
  String get legal_content_cookie_thirdParty_supabaseText;

  /// No description provided for @legal_content_cookie_thirdParty_title.
  ///
  /// In en, this message translates to:
  /// **'Third-Party Cookies'**
  String get legal_content_cookie_thirdParty_title;

  /// No description provided for @legal_content_cookie_types_title.
  ///
  /// In en, this message translates to:
  /// **'Types of Cookies We Use'**
  String get legal_content_cookie_types_title;

  /// No description provided for @legal_content_cookie_whatAreCookies_body.
  ///
  /// In en, this message translates to:
  /// **'Cookies are small text files placed on your device when you visit a website. They are widely used to make websites work efficiently, to remember your preferences, and to provide information to website operators. Similar technologies include web beacons, pixels, local storage, and session storage, all of which we refer to collectively as \"cookies\" in this policy.'**
  String get legal_content_cookie_whatAreCookies_body;

  /// No description provided for @legal_content_cookie_whatAreCookies_title.
  ///
  /// In en, this message translates to:
  /// **'What Are Cookies?'**
  String get legal_content_cookie_whatAreCookies_title;

  /// No description provided for @legal_content_cookie_whyWeUse_intro.
  ///
  /// In en, this message translates to:
  /// **'CheapestGo uses cookies to:'**
  String get legal_content_cookie_whyWeUse_intro;

  /// No description provided for @legal_content_cookie_whyWeUse_title.
  ///
  /// In en, this message translates to:
  /// **'Why We Use Cookies'**
  String get legal_content_cookie_whyWeUse_title;

  /// No description provided for @legal_content_privacy_changes_body.
  ///
  /// In en, this message translates to:
  /// **'We may update this Privacy Policy from time to time. When we make material changes, we will notify you by email (if you have an account) or by posting a prominent notice on our website. Your continued use of CheapestGo after the effective date of the revised policy constitutes your acceptance of the changes.'**
  String get legal_content_privacy_changes_body;

  /// No description provided for @legal_content_privacy_changes_title.
  ///
  /// In en, this message translates to:
  /// **'Changes to This Policy'**
  String get legal_content_privacy_changes_title;

  /// No description provided for @legal_content_privacy_childrensPrivacy_body.
  ///
  /// In en, this message translates to:
  /// **'CheapestGo is not intended for children under the age of 18. We do not knowingly collect personal information from children. If you believe we have inadvertently collected information from a child, please contact us immediately at support@cheapestgo.com and we will delete such information promptly.'**
  String get legal_content_privacy_childrensPrivacy_body;

  /// No description provided for @legal_content_privacy_childrensPrivacy_title.
  ///
  /// In en, this message translates to:
  /// **'Children\'s Privacy'**
  String get legal_content_privacy_childrensPrivacy_title;

  /// No description provided for @legal_content_privacy_contact_address.
  ///
  /// In en, this message translates to:
  /// **'🏢 FORHU Inc. · 30 Wall Street, 8th Floor · New York, NY 10005 · USA'**
  String get legal_content_privacy_contact_address;

  /// No description provided for @legal_content_privacy_contact_email.
  ///
  /// In en, this message translates to:
  /// **'📧 support@cheapestgo.com'**
  String get legal_content_privacy_contact_email;

  /// No description provided for @legal_content_privacy_contact_intro.
  ///
  /// In en, this message translates to:
  /// **'For privacy-related inquiries, requests, or complaints:'**
  String get legal_content_privacy_contact_intro;

  /// No description provided for @legal_content_privacy_contact_title.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get legal_content_privacy_contact_title;

  /// No description provided for @legal_content_privacy_cookies_linkText.
  ///
  /// In en, this message translates to:
  /// **'Cookie Policy'**
  String get legal_content_privacy_cookies_linkText;

  /// No description provided for @legal_content_privacy_cookies_textAfter.
  ///
  /// In en, this message translates to:
  /// **'for full details on what cookies we use and how to manage your preferences.'**
  String get legal_content_privacy_cookies_textAfter;

  /// No description provided for @legal_content_privacy_cookies_textBefore.
  ///
  /// In en, this message translates to:
  /// **'We use cookies and similar technologies to operate our platform and improve your experience. Please see our'**
  String get legal_content_privacy_cookies_textBefore;

  /// No description provided for @legal_content_privacy_cookies_title.
  ///
  /// In en, this message translates to:
  /// **'Cookies and Tracking Technologies'**
  String get legal_content_privacy_cookies_title;

  /// No description provided for @legal_content_privacy_dataRetention_intro.
  ///
  /// In en, this message translates to:
  /// **'We retain your personal data for as long as necessary to:'**
  String get legal_content_privacy_dataRetention_intro;

  /// No description provided for @legal_content_privacy_dataRetention_note.
  ///
  /// In en, this message translates to:
  /// **'When you delete your account, we will delete or anonymize your personal data within 90 days, except where retention is required by law.'**
  String get legal_content_privacy_dataRetention_note;

  /// No description provided for @legal_content_privacy_dataRetention_title.
  ///
  /// In en, this message translates to:
  /// **'Data Retention'**
  String get legal_content_privacy_dataRetention_title;

  /// No description provided for @legal_content_privacy_howWeShare_intro.
  ///
  /// In en, this message translates to:
  /// **'We do not sell your personal information. We share your data only in the following circumstances:'**
  String get legal_content_privacy_howWeShare_intro;

  /// No description provided for @legal_content_privacy_howWeShare_title.
  ///
  /// In en, this message translates to:
  /// **'How We Share Your Information'**
  String get legal_content_privacy_howWeShare_title;

  /// No description provided for @legal_content_privacy_howWeUse_title.
  ///
  /// In en, this message translates to:
  /// **'How We Use Your Information'**
  String get legal_content_privacy_howWeUse_title;

  /// No description provided for @legal_content_privacy_informationWeCollect_autoLabel.
  ///
  /// In en, this message translates to:
  /// **'Information collected automatically:'**
  String get legal_content_privacy_informationWeCollect_autoLabel;

  /// No description provided for @legal_content_privacy_informationWeCollect_directLabel.
  ///
  /// In en, this message translates to:
  /// **'Information you provide directly:'**
  String get legal_content_privacy_informationWeCollect_directLabel;

  /// No description provided for @legal_content_privacy_informationWeCollect_thirdPartyLabel.
  ///
  /// In en, this message translates to:
  /// **'Information from third parties:'**
  String get legal_content_privacy_informationWeCollect_thirdPartyLabel;

  /// No description provided for @legal_content_privacy_informationWeCollect_title.
  ///
  /// In en, this message translates to:
  /// **'Information We Collect'**
  String get legal_content_privacy_informationWeCollect_title;

  /// No description provided for @legal_content_privacy_internationalTransfers_body.
  ///
  /// In en, this message translates to:
  /// **'CheapestGo is headquartered in the United States. When you use our services from Southeast Asia or other regions, your data is transferred to and processed in the United States. We ensure appropriate safeguards are in place for international transfers, including standard contractual clauses where required under applicable law (including GDPR and the Philippine Data Privacy Act of 2012, Republic Act No. 10173).'**
  String get legal_content_privacy_internationalTransfers_body;

  /// No description provided for @legal_content_privacy_internationalTransfers_title.
  ///
  /// In en, this message translates to:
  /// **'International Data Transfers'**
  String get legal_content_privacy_internationalTransfers_title;

  /// No description provided for @legal_content_privacy_security_body.
  ///
  /// In en, this message translates to:
  /// **'We implement industry-standard technical and organizational measures to protect your personal data, including encryption in transit (TLS/HTTPS), encryption at rest, access controls, and regular security reviews. Payment data is handled exclusively by Stripe, which is PCI DSS compliant. However, no method of transmission over the internet is completely secure, and we cannot guarantee absolute security.'**
  String get legal_content_privacy_security_body;

  /// No description provided for @legal_content_privacy_security_title.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get legal_content_privacy_security_title;

  /// No description provided for @legal_content_privacy_whoWeAre_para1.
  ///
  /// In en, this message translates to:
  /// **'CheapestGo (\"we,\" \"us,\" or \"our\") is an online travel agency operated by FORHU Inc., located at 30 Wall Street, 8th Floor, New York, NY 10005, United States. We provide hotel booking, flight package, and travel deal services primarily to travelers in Southeast Asia through our website and mobile platform.'**
  String get legal_content_privacy_whoWeAre_para1;

  /// No description provided for @legal_content_privacy_whoWeAre_para2After.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get legal_content_privacy_whoWeAre_para2After;

  /// No description provided for @legal_content_privacy_whoWeAre_para2Before.
  ///
  /// In en, this message translates to:
  /// **'For questions regarding this Privacy Policy, contact us at'**
  String get legal_content_privacy_whoWeAre_para2Before;

  /// No description provided for @legal_content_privacy_whoWeAre_title.
  ///
  /// In en, this message translates to:
  /// **'Who We Are'**
  String get legal_content_privacy_whoWeAre_title;

  /// No description provided for @legal_content_privacy_yourRights_emailAfter.
  ///
  /// In en, this message translates to:
  /// **'. We will respond within 30 days.'**
  String get legal_content_privacy_yourRights_emailAfter;

  /// No description provided for @legal_content_privacy_yourRights_emailBefore.
  ///
  /// In en, this message translates to:
  /// **'To exercise any of these rights, email us at'**
  String get legal_content_privacy_yourRights_emailBefore;

  /// No description provided for @legal_content_privacy_yourRights_intro.
  ///
  /// In en, this message translates to:
  /// **'Depending on your jurisdiction, you may have the following rights:'**
  String get legal_content_privacy_yourRights_intro;

  /// No description provided for @legal_content_privacy_yourRights_title.
  ///
  /// In en, this message translates to:
  /// **'Your Rights and Choices'**
  String get legal_content_privacy_yourRights_title;

  /// No description provided for @legal_content_refund_amendments_intro.
  ///
  /// In en, this message translates to:
  /// **'Date changes, room type changes, and guest name corrections are subject to hotel availability and supplier policies. To request an amendment:'**
  String get legal_content_refund_amendments_intro;

  /// No description provided for @legal_content_refund_amendments_noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note:'**
  String get legal_content_refund_amendments_noteLabel;

  /// No description provided for @legal_content_refund_amendments_noteText.
  ///
  /// In en, this message translates to:
  /// **'Amendments may result in a price difference (additional charge or credit) and may not always be possible without cancelling and rebooking. We cannot guarantee that amendment requests will be accommodated.'**
  String get legal_content_refund_amendments_noteText;

  /// No description provided for @legal_content_refund_amendments_title.
  ///
  /// In en, this message translates to:
  /// **'Booking Amendments'**
  String get legal_content_refund_amendments_title;

  /// No description provided for @legal_content_refund_cancellationTypes_free_body.
  ///
  /// In en, this message translates to:
  /// **'You may cancel at no charge before the deadline specified at booking. The exact deadline (e.g., \"Free cancellation until 48 hours before check-in\") is shown on the booking page and in your confirmation email.'**
  String get legal_content_refund_cancellationTypes_free_body;

  /// No description provided for @legal_content_refund_cancellationTypes_free_heading.
  ///
  /// In en, this message translates to:
  /// **'Free Cancellation'**
  String get legal_content_refund_cancellationTypes_free_heading;

  /// No description provided for @legal_content_refund_cancellationTypes_intro.
  ///
  /// In en, this message translates to:
  /// **'When you book a hotel through CheapestGo, you will see one of the following rate types:'**
  String get legal_content_refund_cancellationTypes_intro;

  /// No description provided for @legal_content_refund_cancellationTypes_nonRefundable_body.
  ///
  /// In en, this message translates to:
  /// **'No refund is provided if you cancel. These rates are typically lower in price and are clearly labeled \"Non-refundable\" before checkout.'**
  String get legal_content_refund_cancellationTypes_nonRefundable_body;

  /// No description provided for @legal_content_refund_cancellationTypes_nonRefundable_heading.
  ///
  /// In en, this message translates to:
  /// **'Non-Refundable'**
  String get legal_content_refund_cancellationTypes_nonRefundable_heading;

  /// No description provided for @legal_content_refund_cancellationTypes_partial_body.
  ///
  /// In en, this message translates to:
  /// **'A partial refund applies depending on when you cancel relative to the check-in date. The penalty amount and cutoff dates are displayed before you confirm payment.'**
  String get legal_content_refund_cancellationTypes_partial_body;

  /// No description provided for @legal_content_refund_cancellationTypes_partial_heading.
  ///
  /// In en, this message translates to:
  /// **'Partially Refundable'**
  String get legal_content_refund_cancellationTypes_partial_heading;

  /// No description provided for @legal_content_refund_cancellationTypes_title.
  ///
  /// In en, this message translates to:
  /// **'Hotel Cancellation Types'**
  String get legal_content_refund_cancellationTypes_title;

  /// No description provided for @legal_content_refund_contact_address.
  ///
  /// In en, this message translates to:
  /// **'🏢 FORHU Inc. · 30 Wall Street, 8th Floor · New York, NY 10005 · USA'**
  String get legal_content_refund_contact_address;

  /// No description provided for @legal_content_refund_contact_email.
  ///
  /// In en, this message translates to:
  /// **'📧 support@cheapestgo.com'**
  String get legal_content_refund_contact_email;

  /// No description provided for @legal_content_refund_contact_intro.
  ///
  /// In en, this message translates to:
  /// **'For all refund and cancellation queries, please have your booking reference number ready and reach us at:'**
  String get legal_content_refund_contact_intro;

  /// No description provided for @legal_content_refund_contact_outro.
  ///
  /// In en, this message translates to:
  /// **'We aim to respond to all refund requests within 1–2 business days.'**
  String get legal_content_refund_contact_outro;

  /// No description provided for @legal_content_refund_contact_title.
  ///
  /// In en, this message translates to:
  /// **'Contact for Refund Requests'**
  String get legal_content_refund_contact_title;

  /// No description provided for @legal_content_refund_disputes_body.
  ///
  /// In en, this message translates to:
  /// **'If you have a concern about a charge, please contact us at support@cheapestgo.com before initiating a chargeback with your bank. Most issues can be resolved quickly. Chargebacks initiated without first contacting CheapestGo may result in account suspension. CheapestGo reserves the right to contest chargebacks that are made in bad faith or that do not comply with our cancellation policy.'**
  String get legal_content_refund_disputes_body;

  /// No description provided for @legal_content_refund_disputes_title.
  ///
  /// In en, this message translates to:
  /// **'Disputes and Chargebacks'**
  String get legal_content_refund_disputes_title;

  /// No description provided for @legal_content_refund_flightPackages_body.
  ///
  /// In en, this message translates to:
  /// **'For all-inclusive flight + hotel packages, cancellation terms depend on both the hotel and airline components. Airline tickets are generally non-refundable or carry significant cancellation fees. The specific terms for your package will be shown during checkout and in your confirmation email. If you need to cancel a package, contact us immediately at support@cheapestgo.com for guidance.'**
  String get legal_content_refund_flightPackages_body;

  /// No description provided for @legal_content_refund_flightPackages_title.
  ///
  /// In en, this message translates to:
  /// **'Flight Packages'**
  String get legal_content_refund_flightPackages_title;

  /// No description provided for @legal_content_refund_howToCancel_emailAfter.
  ///
  /// In en, this message translates to:
  /// **'with your booking reference number and we will process the cancellation within 1 business day.'**
  String get legal_content_refund_howToCancel_emailAfter;

  /// No description provided for @legal_content_refund_howToCancel_emailBefore.
  ///
  /// In en, this message translates to:
  /// **'Alternatively, contact us at'**
  String get legal_content_refund_howToCancel_emailBefore;

  /// No description provided for @legal_content_refund_howToCancel_intro.
  ///
  /// In en, this message translates to:
  /// **'To cancel a booking:'**
  String get legal_content_refund_howToCancel_intro;

  /// No description provided for @legal_content_refund_howToCancel_title.
  ///
  /// In en, this message translates to:
  /// **'How to Cancel a Booking'**
  String get legal_content_refund_howToCancel_title;

  /// No description provided for @legal_content_refund_noShows_body.
  ///
  /// In en, this message translates to:
  /// **'If you fail to check in on the scheduled arrival date without cancelling in advance, the booking will be treated as a no-show. No-show policies vary by hotel — most hotels will charge the full booking amount. CheapestGo cannot override hotel no-show policies. We strongly recommend cancelling ahead of time if your plans change.'**
  String get legal_content_refund_noShows_body;

  /// No description provided for @legal_content_refund_noShows_title.
  ///
  /// In en, this message translates to:
  /// **'No-Shows'**
  String get legal_content_refund_noShows_title;

  /// No description provided for @legal_content_refund_overview_body.
  ///
  /// In en, this message translates to:
  /// **'CheapestGo acts as an intermediary between you and travel suppliers (hotels, airlines, and package providers). Cancellation and refund rights are primarily governed by the individual supplier\'s policies, which vary by property, rate type, and booking dates. This policy explains how we facilitate cancellations and refunds on your behalf.'**
  String get legal_content_refund_overview_body;

  /// No description provided for @legal_content_refund_overview_title.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get legal_content_refund_overview_title;

  /// No description provided for @legal_content_refund_processing_title.
  ///
  /// In en, this message translates to:
  /// **'Refund Processing'**
  String get legal_content_refund_processing_title;

  /// No description provided for @legal_content_refund_supplierCancellations_intro.
  ///
  /// In en, this message translates to:
  /// **'In rare cases, a hotel or travel supplier may cancel your booking due to overbooking, closure, natural disaster, or force majeure events. If this occurs:'**
  String get legal_content_refund_supplierCancellations_intro;

  /// No description provided for @legal_content_refund_supplierCancellations_note.
  ///
  /// In en, this message translates to:
  /// **'CheapestGo is not liable for losses arising from supplier cancellations, including transportation costs, additional hotel nights booked elsewhere, or consequential losses. We recommend purchasing travel insurance to cover such events.'**
  String get legal_content_refund_supplierCancellations_note;

  /// No description provided for @legal_content_refund_supplierCancellations_title.
  ///
  /// In en, this message translates to:
  /// **'Supplier Cancellations and Force Majeure'**
  String get legal_content_refund_supplierCancellations_title;

  /// No description provided for @legal_content_terms_acceptance_body.
  ///
  /// In en, this message translates to:
  /// **'By accessing or using the CheapestGo website and services (the \"Platform\"), you agree to be bound by these Terms of Service (\"Terms\") and all applicable laws and regulations. If you do not agree to these Terms, you may not use the Platform. CheapestGo is operated by FORHU Inc., 30 Wall Street, 8th Floor, New York, NY 10005, United States. These Terms constitute a legally binding agreement between you and CheapestGo.'**
  String get legal_content_terms_acceptance_body;

  /// No description provided for @legal_content_terms_acceptance_title.
  ///
  /// In en, this message translates to:
  /// **'Acceptance of Terms'**
  String get legal_content_terms_acceptance_title;

  /// No description provided for @legal_content_terms_accountRegistration_intro.
  ///
  /// In en, this message translates to:
  /// **'To access certain features of the Platform, you may need to create an account. You agree to:'**
  String get legal_content_terms_accountRegistration_intro;

  /// No description provided for @legal_content_terms_accountRegistration_note.
  ///
  /// In en, this message translates to:
  /// **'CheapestGo reserves the right to suspend or terminate accounts that violate these Terms or that are inactive for an extended period.'**
  String get legal_content_terms_accountRegistration_note;

  /// No description provided for @legal_content_terms_accountRegistration_title.
  ///
  /// In en, this message translates to:
  /// **'Account Registration'**
  String get legal_content_terms_accountRegistration_title;

  /// No description provided for @legal_content_terms_bookingProcess_intro.
  ///
  /// In en, this message translates to:
  /// **'When you make a booking through CheapestGo, you are entering into a contract with the travel supplier (hotel, airline, or package provider), not with CheapestGo. CheapestGo acts as an intermediary facilitating the booking.'**
  String get legal_content_terms_bookingProcess_intro;

  /// No description provided for @legal_content_terms_bookingProcess_title.
  ///
  /// In en, this message translates to:
  /// **'Booking Process and Confirmation'**
  String get legal_content_terms_bookingProcess_title;

  /// No description provided for @legal_content_terms_cancellations_refundLinkText.
  ///
  /// In en, this message translates to:
  /// **'Refund & Cancellation Policy'**
  String get legal_content_terms_cancellations_refundLinkText;

  /// No description provided for @legal_content_terms_cancellations_textAfter.
  ///
  /// In en, this message translates to:
  /// **', which is incorporated into these Terms by reference. Please review it carefully before making a booking, as policies vary by hotel and rate type.'**
  String get legal_content_terms_cancellations_textAfter;

  /// No description provided for @legal_content_terms_cancellations_textBefore.
  ///
  /// In en, this message translates to:
  /// **'Cancellations and refunds are governed by our'**
  String get legal_content_terms_cancellations_textBefore;

  /// No description provided for @legal_content_terms_cancellations_title.
  ///
  /// In en, this message translates to:
  /// **'Cancellations and Refunds'**
  String get legal_content_terms_cancellations_title;

  /// No description provided for @legal_content_terms_changes_body.
  ///
  /// In en, this message translates to:
  /// **'CheapestGo reserves the right to modify these Terms at any time. We will notify registered users of material changes via email and by posting an updated version on the Platform with a revised \"Last Updated\" date. Your continued use of the Platform after changes take effect constitutes your acceptance of the revised Terms.'**
  String get legal_content_terms_changes_body;

  /// No description provided for @legal_content_terms_changes_title.
  ///
  /// In en, this message translates to:
  /// **'Changes to These Terms'**
  String get legal_content_terms_changes_title;

  /// No description provided for @legal_content_terms_contact_address.
  ///
  /// In en, this message translates to:
  /// **'🏢 FORHU Inc. · 30 Wall Street, 8th Floor · New York, NY 10005 · USA'**
  String get legal_content_terms_contact_address;

  /// No description provided for @legal_content_terms_contact_email.
  ///
  /// In en, this message translates to:
  /// **'📧 support@cheapestgo.com'**
  String get legal_content_terms_contact_email;

  /// No description provided for @legal_content_terms_contact_intro.
  ///
  /// In en, this message translates to:
  /// **'For questions about these Terms:'**
  String get legal_content_terms_contact_intro;

  /// No description provided for @legal_content_terms_contact_title.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get legal_content_terms_contact_title;

  /// No description provided for @legal_content_terms_disclaimers_intro.
  ///
  /// In en, this message translates to:
  /// **'CheapestGo provides its services on an \"as is\" and \"as available\" basis. We do not guarantee that:'**
  String get legal_content_terms_disclaimers_intro;

  /// No description provided for @legal_content_terms_disclaimers_note.
  ///
  /// In en, this message translates to:
  /// **'CheapestGo is not responsible for the acts, errors, omissions, representations, warranties, or negligence of any travel supplier.'**
  String get legal_content_terms_disclaimers_note;

  /// No description provided for @legal_content_terms_disclaimers_title.
  ///
  /// In en, this message translates to:
  /// **'Disclaimers'**
  String get legal_content_terms_disclaimers_title;

  /// No description provided for @legal_content_terms_eligibility_intro.
  ///
  /// In en, this message translates to:
  /// **'To use CheapestGo, you must:'**
  String get legal_content_terms_eligibility_intro;

  /// No description provided for @legal_content_terms_eligibility_title.
  ///
  /// In en, this message translates to:
  /// **'Eligibility'**
  String get legal_content_terms_eligibility_title;

  /// No description provided for @legal_content_terms_governingLaw_para1.
  ///
  /// In en, this message translates to:
  /// **'These Terms are governed by the laws of the State of New York, United States, without regard to its conflict of law provisions.'**
  String get legal_content_terms_governingLaw_para1;

  /// No description provided for @legal_content_terms_governingLaw_para2.
  ///
  /// In en, this message translates to:
  /// **'Any dispute arising from or relating to these Terms or your use of CheapestGo shall first be attempted to be resolved through good-faith negotiation. If unresolved within 30 days, disputes shall be submitted to binding arbitration in New York City, New York, under the rules of the American Arbitration Association (AAA). You waive any right to participate in a class action lawsuit or class-wide arbitration.'**
  String get legal_content_terms_governingLaw_para2;

  /// No description provided for @legal_content_terms_governingLaw_title.
  ///
  /// In en, this message translates to:
  /// **'Governing Law and Dispute Resolution'**
  String get legal_content_terms_governingLaw_title;

  /// No description provided for @legal_content_terms_indemnification_body.
  ///
  /// In en, this message translates to:
  /// **'You agree to indemnify, defend, and hold harmless CheapestGo and FORHU Inc. from and against any claims, liabilities, damages, losses, and expenses (including legal fees) arising out of or in any way connected with your use of the Platform, your violation of these Terms, or your violation of any rights of another person.'**
  String get legal_content_terms_indemnification_body;

  /// No description provided for @legal_content_terms_indemnification_title.
  ///
  /// In en, this message translates to:
  /// **'Indemnification'**
  String get legal_content_terms_indemnification_title;

  /// No description provided for @legal_content_terms_intellectualProperty_body.
  ///
  /// In en, this message translates to:
  /// **'All content on the CheapestGo Platform — including logos, text, graphics, software, and design — is the property of CheapestGo or its licensors and is protected by applicable intellectual property laws. You may not reproduce, distribute, or create derivative works from our content without prior written consent. Hotel and flight images and descriptions are provided by our partners (Duffel, TravelgateX) and respective suppliers under license.'**
  String get legal_content_terms_intellectualProperty_body;

  /// No description provided for @legal_content_terms_intellectualProperty_title.
  ///
  /// In en, this message translates to:
  /// **'Intellectual Property'**
  String get legal_content_terms_intellectualProperty_title;

  /// No description provided for @legal_content_terms_liability_body.
  ///
  /// In en, this message translates to:
  /// **'To the maximum extent permitted by applicable law, CheapestGo, its officers, directors, employees, and affiliates shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including loss of profits, data, or goodwill, arising out of or in connection with your use of the Platform or any booking made through it. Our total aggregate liability to you for any claim arising out of these Terms shall not exceed the total amount paid by you for the booking giving rise to the claim.'**
  String get legal_content_terms_liability_body;

  /// No description provided for @legal_content_terms_liability_title.
  ///
  /// In en, this message translates to:
  /// **'Limitation of Liability'**
  String get legal_content_terms_liability_title;

  /// No description provided for @legal_content_terms_pricing_title.
  ///
  /// In en, this message translates to:
  /// **'Pricing and Payments'**
  String get legal_content_terms_pricing_title;

  /// No description provided for @legal_content_terms_prohibitedConduct_intro.
  ///
  /// In en, this message translates to:
  /// **'You agree not to:'**
  String get legal_content_terms_prohibitedConduct_intro;

  /// No description provided for @legal_content_terms_prohibitedConduct_title.
  ///
  /// In en, this message translates to:
  /// **'Prohibited Conduct'**
  String get legal_content_terms_prohibitedConduct_title;

  /// No description provided for @legal_cookiePolicy_description.
  ///
  /// In en, this message translates to:
  /// **'How CheapestGo uses cookies and similar tracking technologies.'**
  String get legal_cookiePolicy_description;

  /// No description provided for @legal_cookiePolicy_pageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How we use cookies and similar technologies on CheapestGo.'**
  String get legal_cookiePolicy_pageSubtitle;

  /// No description provided for @legal_cookiePolicy_pageTitle.
  ///
  /// In en, this message translates to:
  /// **'Cookie Policy'**
  String get legal_cookiePolicy_pageTitle;

  /// No description provided for @legal_cookiePolicy_title.
  ///
  /// In en, this message translates to:
  /// **'Cookie Policy — CheapestGo'**
  String get legal_cookiePolicy_title;

  /// No description provided for @legal_layout_breadcrumb.
  ///
  /// In en, this message translates to:
  /// **'CheapestGo · Legal'**
  String get legal_layout_breadcrumb;

  /// No description provided for @legal_layout_contact_address.
  ///
  /// In en, this message translates to:
  /// **'FORHU Inc. · 30 Wall Street, 8th Floor · New York, NY 10005 · United States'**
  String get legal_layout_contact_address;

  /// No description provided for @legal_layout_contact_contactLine.
  ///
  /// In en, this message translates to:
  /// **'Contact us at'**
  String get legal_layout_contact_contactLine;

  /// No description provided for @legal_layout_contact_heading.
  ///
  /// In en, this message translates to:
  /// **'Questions about this document?'**
  String get legal_layout_contact_heading;

  /// No description provided for @legal_layout_contents.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get legal_layout_contents;

  /// No description provided for @legal_layout_disclaimer_body.
  ///
  /// In en, this message translates to:
  /// **'This document is provided for informational purposes. CheapestGo recommends consulting a qualified attorney to review these terms for your specific jurisdiction before publishing to production.'**
  String get legal_layout_disclaimer_body;

  /// No description provided for @legal_layout_disclaimer_label.
  ///
  /// In en, this message translates to:
  /// **'Note:'**
  String get legal_layout_disclaimer_label;

  /// No description provided for @legal_layout_effective.
  ///
  /// In en, this message translates to:
  /// **'Effective:'**
  String get legal_layout_effective;

  /// No description provided for @legal_layout_lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated:'**
  String get legal_layout_lastUpdated;

  /// No description provided for @legal_privacyPolicy_description.
  ///
  /// In en, this message translates to:
  /// **'How CheapestGo collects, uses, and protects your personal information.'**
  String get legal_privacyPolicy_description;

  /// No description provided for @legal_privacyPolicy_pageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How we collect, use, and protect your personal information.'**
  String get legal_privacyPolicy_pageSubtitle;

  /// No description provided for @legal_privacyPolicy_pageTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legal_privacyPolicy_pageTitle;

  /// No description provided for @legal_privacyPolicy_title.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy — CheapestGo'**
  String get legal_privacyPolicy_title;

  /// No description provided for @legal_refundPolicy_description.
  ///
  /// In en, this message translates to:
  /// **'Understand how cancellations, refunds, and amendments work on CheapestGo.'**
  String get legal_refundPolicy_description;

  /// No description provided for @legal_refundPolicy_pageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything you need to know about cancellations, refunds, and booking changes.'**
  String get legal_refundPolicy_pageSubtitle;

  /// No description provided for @legal_refundPolicy_pageTitle.
  ///
  /// In en, this message translates to:
  /// **'Refund & Cancellation Policy'**
  String get legal_refundPolicy_pageTitle;

  /// No description provided for @legal_refundPolicy_title.
  ///
  /// In en, this message translates to:
  /// **'Refund & Cancellation Policy — CheapestGo'**
  String get legal_refundPolicy_title;

  /// No description provided for @legal_scrollToContinue.
  ///
  /// In en, this message translates to:
  /// **'Scroll to the bottom to continue'**
  String get legal_scrollToContinue;

  /// No description provided for @legal_termsGate_acceptButton.
  ///
  /// In en, this message translates to:
  /// **'Accept and continue'**
  String get legal_termsGate_acceptButton;

  /// No description provided for @legal_termsGate_checkboxAriaLabel.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms & Conditions and Privacy Policy'**
  String get legal_termsGate_checkboxAriaLabel;

  /// No description provided for @legal_termsGate_checkboxConnector.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get legal_termsGate_checkboxConnector;

  /// No description provided for @legal_termsGate_checkboxLabel.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the Terms of Service and Privacy Policy.'**
  String get legal_termsGate_checkboxLabel;

  /// No description provided for @legal_termsGate_checkboxPrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get legal_termsGate_checkboxPrefix;

  /// No description provided for @legal_termsGate_checkboxPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legal_termsGate_checkboxPrivacy;

  /// No description provided for @legal_termsGate_checkboxSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get legal_termsGate_checkboxSuffix;

  /// No description provided for @legal_termsGate_checkboxTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get legal_termsGate_checkboxTerms;

  /// No description provided for @legal_termsGate_opensInNewTab.
  ///
  /// In en, this message translates to:
  /// **'Opens in a new tab — you won\'t lose your place.'**
  String get legal_termsGate_opensInNewTab;

  /// No description provided for @legal_termsGate_privacyLink.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legal_termsGate_privacyLink;

  /// No description provided for @legal_termsGate_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Please review and accept our terms to continue using CheapestGo.'**
  String get legal_termsGate_subtitle;

  /// No description provided for @legal_termsGate_termsLink.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get legal_termsGate_termsLink;

  /// No description provided for @legal_termsGate_title.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get legal_termsGate_title;

  /// No description provided for @legal_termsOfService_description.
  ///
  /// In en, this message translates to:
  /// **'The terms and conditions governing your use of CheapestGo.'**
  String get legal_termsOfService_description;

  /// No description provided for @legal_termsOfService_pageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please read these terms carefully before using CheapestGo.'**
  String get legal_termsOfService_pageSubtitle;

  /// No description provided for @legal_termsOfService_pageTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get legal_termsOfService_pageTitle;

  /// No description provided for @legal_termsOfService_title.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service — CheapestGo'**
  String get legal_termsOfService_title;

  /// No description provided for @map_details.
  ///
  /// In en, this message translates to:
  /// **'Map Details'**
  String get map_details;

  /// No description provided for @map_fromProperty.
  ///
  /// In en, this message translates to:
  /// **'{distance} from property'**
  String map_fromProperty(Object distance);

  /// No description provided for @map_labels.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get map_labels;

  /// No description provided for @map_mapType.
  ///
  /// In en, this message translates to:
  /// **'Map Type'**
  String get map_mapType;

  /// No description provided for @map_noPlacesInArea.
  ///
  /// In en, this message translates to:
  /// **'No places found in this area'**
  String get map_noPlacesInArea;

  /// No description provided for @map_searchOnMap.
  ///
  /// In en, this message translates to:
  /// **'Search on map…'**
  String get map_searchOnMap;

  /// No description provided for @map_viewDeal.
  ///
  /// In en, this message translates to:
  /// **'View Deal'**
  String get map_viewDeal;

  /// No description provided for @map_viewOnGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'View on Google Maps →'**
  String get map_viewOnGoogleMaps;

  /// No description provided for @nav_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get nav_account;

  /// No description provided for @nav_accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get nav_accountSettings;

  /// No description provided for @nav_accountWorks.
  ///
  /// In en, this message translates to:
  /// **'Your account works across CheapestGo and all partner sites'**
  String get nav_accountWorks;

  /// No description provided for @nav_bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get nav_bookings;

  /// No description provided for @nav_createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get nav_createAccount;

  /// No description provided for @nav_membersSave.
  ///
  /// In en, this message translates to:
  /// **'Members save 10% or more'**
  String get nav_membersSave;

  /// No description provided for @nav_membersSaveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'on select stays when signed in'**
  String get nav_membersSaveSubtitle;

  /// No description provided for @nav_menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get nav_menu;

  /// No description provided for @nav_myTrips.
  ///
  /// In en, this message translates to:
  /// **'My trips'**
  String get nav_myTrips;

  /// No description provided for @nav_openApp.
  ///
  /// In en, this message translates to:
  /// **'Open app'**
  String get nav_openApp;

  /// No description provided for @nav_signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get nav_signIn;

  /// No description provided for @nav_signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get nav_signOut;

  /// No description provided for @nav_support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get nav_support;

  /// No description provided for @nav_trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get nav_trips;

  /// No description provided for @propertyGallery_alt_galleryView.
  ///
  /// In en, this message translates to:
  /// **'Gallery view {number}'**
  String propertyGallery_alt_galleryView(Object number);

  /// No description provided for @propertyGallery_alt_mainPropertyView.
  ///
  /// In en, this message translates to:
  /// **'Main property view'**
  String get propertyGallery_alt_mainPropertyView;

  /// No description provided for @propertyGallery_alt_propertyView.
  ///
  /// In en, this message translates to:
  /// **'Property view'**
  String get propertyGallery_alt_propertyView;

  /// No description provided for @propertyGallery_alt_propertyViewNumbered.
  ///
  /// In en, this message translates to:
  /// **'Property view {number}'**
  String propertyGallery_alt_propertyViewNumbered(Object number);

  /// No description provided for @propertyGallery_alt_thumbnail.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail {number}'**
  String propertyGallery_alt_thumbnail(Object number);

  /// No description provided for @propertyGallery_alt_view.
  ///
  /// In en, this message translates to:
  /// **'View {number}'**
  String propertyGallery_alt_view(Object number);

  /// No description provided for @propertyGallery_moreInfo.
  ///
  /// In en, this message translates to:
  /// **'More Info'**
  String get propertyGallery_moreInfo;

  /// No description provided for @propertyGallery_morePhotos.
  ///
  /// In en, this message translates to:
  /// **'+{count} photos'**
  String propertyGallery_morePhotos(Object count);

  /// No description provided for @propertyGallery_noImages.
  ///
  /// In en, this message translates to:
  /// **'No images available'**
  String get propertyGallery_noImages;

  /// No description provided for @propertyGallery_showAllPhotos.
  ///
  /// In en, this message translates to:
  /// **'Show all photos'**
  String get propertyGallery_showAllPhotos;

  /// No description provided for @propertyGallery_viewPhoto.
  ///
  /// In en, this message translates to:
  /// **'View photo'**
  String get propertyGallery_viewPhoto;

  /// No description provided for @propertyNav_amenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get propertyNav_amenities;

  /// No description provided for @propertyNav_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get propertyNav_location;

  /// No description provided for @propertyNav_overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get propertyNav_overview;

  /// No description provided for @propertyNav_policies.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get propertyNav_policies;

  /// No description provided for @propertyNav_reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get propertyNav_reviews;

  /// No description provided for @propertyNav_rooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get propertyNav_rooms;

  /// No description provided for @propertyOverview_aboutProperty.
  ///
  /// In en, this message translates to:
  /// **'About this property'**
  String get propertyOverview_aboutProperty;

  /// No description provided for @propertyOverview_amenityLabels_24_7_Reception.
  ///
  /// In en, this message translates to:
  /// **'24/7 Reception'**
  String get propertyOverview_amenityLabels_24_7_Reception;

  /// No description provided for @propertyOverview_amenityLabels_ATM_on_Site.
  ///
  /// In en, this message translates to:
  /// **'ATM on Site'**
  String get propertyOverview_amenityLabels_ATM_on_Site;

  /// No description provided for @propertyOverview_amenityLabels_Air_Conditioning.
  ///
  /// In en, this message translates to:
  /// **'Air Conditioning'**
  String get propertyOverview_amenityLabels_Air_Conditioning;

  /// No description provided for @propertyOverview_amenityLabels_Airport_Transfer.
  ///
  /// In en, this message translates to:
  /// **'Airport Transfer'**
  String get propertyOverview_amenityLabels_Airport_Transfer;

  /// No description provided for @propertyOverview_amenityLabels_BBQ_Facilities.
  ///
  /// In en, this message translates to:
  /// **'BBQ Facilities'**
  String get propertyOverview_amenityLabels_BBQ_Facilities;

  /// No description provided for @propertyOverview_amenityLabels_Balcony.
  ///
  /// In en, this message translates to:
  /// **'Balcony'**
  String get propertyOverview_amenityLabels_Balcony;

  /// No description provided for @propertyOverview_amenityLabels_Bar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get propertyOverview_amenityLabels_Bar;

  /// No description provided for @propertyOverview_amenityLabels_Beach_Access.
  ///
  /// In en, this message translates to:
  /// **'Beach Access'**
  String get propertyOverview_amenityLabels_Beach_Access;

  /// No description provided for @propertyOverview_amenityLabels_Breakfast_Available.
  ///
  /// In en, this message translates to:
  /// **'Breakfast Available'**
  String get propertyOverview_amenityLabels_Breakfast_Available;

  /// No description provided for @propertyOverview_amenityLabels_Breakfast_Included.
  ///
  /// In en, this message translates to:
  /// **'Breakfast Included'**
  String get propertyOverview_amenityLabels_Breakfast_Included;

  /// No description provided for @propertyOverview_amenityLabels_Buffet_Breakfast.
  ///
  /// In en, this message translates to:
  /// **'Buffet Breakfast'**
  String get propertyOverview_amenityLabels_Buffet_Breakfast;

  /// No description provided for @propertyOverview_amenityLabels_Business_Center.
  ///
  /// In en, this message translates to:
  /// **'Business Center'**
  String get propertyOverview_amenityLabels_Business_Center;

  /// No description provided for @propertyOverview_amenityLabels_City_View.
  ///
  /// In en, this message translates to:
  /// **'City View'**
  String get propertyOverview_amenityLabels_City_View;

  /// No description provided for @propertyOverview_amenityLabels_Coffee_Maker.
  ///
  /// In en, this message translates to:
  /// **'Coffee Maker'**
  String get propertyOverview_amenityLabels_Coffee_Maker;

  /// No description provided for @propertyOverview_amenityLabels_Concierge.
  ///
  /// In en, this message translates to:
  /// **'Concierge'**
  String get propertyOverview_amenityLabels_Concierge;

  /// No description provided for @propertyOverview_amenityLabels_Conference_Facilities.
  ///
  /// In en, this message translates to:
  /// **'Conference Facilities'**
  String get propertyOverview_amenityLabels_Conference_Facilities;

  /// No description provided for @propertyOverview_amenityLabels_Daily_Housekeeping.
  ///
  /// In en, this message translates to:
  /// **'Daily Housekeeping'**
  String get propertyOverview_amenityLabels_Daily_Housekeeping;

  /// No description provided for @propertyOverview_amenityLabels_Disabled_Facilities.
  ///
  /// In en, this message translates to:
  /// **'Disabled Facilities'**
  String get propertyOverview_amenityLabels_Disabled_Facilities;

  /// No description provided for @propertyOverview_amenityLabels_Dry_Cleaning.
  ///
  /// In en, this message translates to:
  /// **'Dry Cleaning'**
  String get propertyOverview_amenityLabels_Dry_Cleaning;

  /// No description provided for @propertyOverview_amenityLabels_Early_Check_in.
  ///
  /// In en, this message translates to:
  /// **'Early Check-in'**
  String get propertyOverview_amenityLabels_Early_Check_in;

  /// No description provided for @propertyOverview_amenityLabels_Elevator.
  ///
  /// In en, this message translates to:
  /// **'Elevator'**
  String get propertyOverview_amenityLabels_Elevator;

  /// No description provided for @propertyOverview_amenityLabels_Express_Check_in.
  ///
  /// In en, this message translates to:
  /// **'Express Check-in'**
  String get propertyOverview_amenityLabels_Express_Check_in;

  /// No description provided for @propertyOverview_amenityLabels_Family_Rooms.
  ///
  /// In en, this message translates to:
  /// **'Family Rooms'**
  String get propertyOverview_amenityLabels_Family_Rooms;

  /// No description provided for @propertyOverview_amenityLabels_Fitness_Center.
  ///
  /// In en, this message translates to:
  /// **'Fitness Center'**
  String get propertyOverview_amenityLabels_Fitness_Center;

  /// No description provided for @propertyOverview_amenityLabels_Flat_Screen_TV.
  ///
  /// In en, this message translates to:
  /// **'Flat-Screen TV'**
  String get propertyOverview_amenityLabels_Flat_Screen_TV;

  /// No description provided for @propertyOverview_amenityLabels_Free_Parking.
  ///
  /// In en, this message translates to:
  /// **'Free Parking'**
  String get propertyOverview_amenityLabels_Free_Parking;

  /// No description provided for @propertyOverview_amenityLabels_Free_WiFi.
  ///
  /// In en, this message translates to:
  /// **'Free WiFi'**
  String get propertyOverview_amenityLabels_Free_WiFi;

  /// No description provided for @propertyOverview_amenityLabels_Garden.
  ///
  /// In en, this message translates to:
  /// **'Garden'**
  String get propertyOverview_amenityLabels_Garden;

  /// No description provided for @propertyOverview_amenityLabels_Garden_View.
  ///
  /// In en, this message translates to:
  /// **'Garden View'**
  String get propertyOverview_amenityLabels_Garden_View;

  /// No description provided for @propertyOverview_amenityLabels_Gift_Shop.
  ///
  /// In en, this message translates to:
  /// **'Gift Shop'**
  String get propertyOverview_amenityLabels_Gift_Shop;

  /// No description provided for @propertyOverview_amenityLabels_Heated_Pool.
  ///
  /// In en, this message translates to:
  /// **'Heated Pool'**
  String get propertyOverview_amenityLabels_Heated_Pool;

  /// No description provided for @propertyOverview_amenityLabels_Heating.
  ///
  /// In en, this message translates to:
  /// **'Heating'**
  String get propertyOverview_amenityLabels_Heating;

  /// No description provided for @propertyOverview_amenityLabels_High_Speed_Internet.
  ///
  /// In en, this message translates to:
  /// **'High-Speed Internet'**
  String get propertyOverview_amenityLabels_High_Speed_Internet;

  /// No description provided for @propertyOverview_amenityLabels_Hot_Tub.
  ///
  /// In en, this message translates to:
  /// **'Hot Tub'**
  String get propertyOverview_amenityLabels_Hot_Tub;

  /// No description provided for @propertyOverview_amenityLabels_In_Room_Safe.
  ///
  /// In en, this message translates to:
  /// **'In-Room Safe'**
  String get propertyOverview_amenityLabels_In_Room_Safe;

  /// No description provided for @propertyOverview_amenityLabels_Indoor_Pool.
  ///
  /// In en, this message translates to:
  /// **'Indoor Pool'**
  String get propertyOverview_amenityLabels_Indoor_Pool;

  /// No description provided for @propertyOverview_amenityLabels_Internet.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get propertyOverview_amenityLabels_Internet;

  /// No description provided for @propertyOverview_amenityLabels_Jacuzzi.
  ///
  /// In en, this message translates to:
  /// **'Jacuzzi'**
  String get propertyOverview_amenityLabels_Jacuzzi;

  /// No description provided for @propertyOverview_amenityLabels_Kitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get propertyOverview_amenityLabels_Kitchen;

  /// No description provided for @propertyOverview_amenityLabels_Kitchenette.
  ///
  /// In en, this message translates to:
  /// **'Kitchenette'**
  String get propertyOverview_amenityLabels_Kitchenette;

  /// No description provided for @propertyOverview_amenityLabels_Late_Check_out.
  ///
  /// In en, this message translates to:
  /// **'Late Check-out'**
  String get propertyOverview_amenityLabels_Late_Check_out;

  /// No description provided for @propertyOverview_amenityLabels_Laundry_Service.
  ///
  /// In en, this message translates to:
  /// **'Laundry Service'**
  String get propertyOverview_amenityLabels_Laundry_Service;

  /// No description provided for @propertyOverview_amenityLabels_Lobby_TV.
  ///
  /// In en, this message translates to:
  /// **'Lobby TV'**
  String get propertyOverview_amenityLabels_Lobby_TV;

  /// No description provided for @propertyOverview_amenityLabels_Lockers.
  ///
  /// In en, this message translates to:
  /// **'Lockers'**
  String get propertyOverview_amenityLabels_Lockers;

  /// No description provided for @propertyOverview_amenityLabels_Luggage_Storage.
  ///
  /// In en, this message translates to:
  /// **'Luggage Storage'**
  String get propertyOverview_amenityLabels_Luggage_Storage;

  /// No description provided for @propertyOverview_amenityLabels_Meeting_Rooms.
  ///
  /// In en, this message translates to:
  /// **'Meeting Rooms'**
  String get propertyOverview_amenityLabels_Meeting_Rooms;

  /// No description provided for @propertyOverview_amenityLabels_Minibar.
  ///
  /// In en, this message translates to:
  /// **'Minibar'**
  String get propertyOverview_amenityLabels_Minibar;

  /// No description provided for @propertyOverview_amenityLabels_Multilingual_Staff.
  ///
  /// In en, this message translates to:
  /// **'Multilingual Staff'**
  String get propertyOverview_amenityLabels_Multilingual_Staff;

  /// No description provided for @propertyOverview_amenityLabels_Newsstand.
  ///
  /// In en, this message translates to:
  /// **'Newsstand'**
  String get propertyOverview_amenityLabels_Newsstand;

  /// No description provided for @propertyOverview_amenityLabels_Non_Smoking_Rooms.
  ///
  /// In en, this message translates to:
  /// **'Non-Smoking Rooms'**
  String get propertyOverview_amenityLabels_Non_Smoking_Rooms;

  /// No description provided for @propertyOverview_amenityLabels_Outdoor_Pool.
  ///
  /// In en, this message translates to:
  /// **'Outdoor Pool'**
  String get propertyOverview_amenityLabels_Outdoor_Pool;

  /// No description provided for @propertyOverview_amenityLabels_Parking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get propertyOverview_amenityLabels_Parking;

  /// No description provided for @propertyOverview_amenityLabels_Pet_Friendly.
  ///
  /// In en, this message translates to:
  /// **'Pet Friendly'**
  String get propertyOverview_amenityLabels_Pet_Friendly;

  /// No description provided for @propertyOverview_amenityLabels_Private_Beach.
  ///
  /// In en, this message translates to:
  /// **'Private Beach'**
  String get propertyOverview_amenityLabels_Private_Beach;

  /// No description provided for @propertyOverview_amenityLabels_Restaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get propertyOverview_amenityLabels_Restaurant;

  /// No description provided for @propertyOverview_amenityLabels_Rooftop_Pool.
  ///
  /// In en, this message translates to:
  /// **'Rooftop Pool'**
  String get propertyOverview_amenityLabels_Rooftop_Pool;

  /// No description provided for @propertyOverview_amenityLabels_Room_Service.
  ///
  /// In en, this message translates to:
  /// **'Room Service'**
  String get propertyOverview_amenityLabels_Room_Service;

  /// No description provided for @propertyOverview_amenityLabels_Sauna.
  ///
  /// In en, this message translates to:
  /// **'Sauna'**
  String get propertyOverview_amenityLabels_Sauna;

  /// No description provided for @propertyOverview_amenityLabels_Sea_View.
  ///
  /// In en, this message translates to:
  /// **'Sea View'**
  String get propertyOverview_amenityLabels_Sea_View;

  /// No description provided for @propertyOverview_amenityLabels_Secure_Parking.
  ///
  /// In en, this message translates to:
  /// **'Secure Parking'**
  String get propertyOverview_amenityLabels_Secure_Parking;

  /// No description provided for @propertyOverview_amenityLabels_Security_Guard.
  ///
  /// In en, this message translates to:
  /// **'Security Guard'**
  String get propertyOverview_amenityLabels_Security_Guard;

  /// No description provided for @propertyOverview_amenityLabels_Shuttle_Service.
  ///
  /// In en, this message translates to:
  /// **'Shuttle Service'**
  String get propertyOverview_amenityLabels_Shuttle_Service;

  /// No description provided for @propertyOverview_amenityLabels_Smoke_Free_Property.
  ///
  /// In en, this message translates to:
  /// **'Smoke-Free Property'**
  String get propertyOverview_amenityLabels_Smoke_Free_Property;

  /// No description provided for @propertyOverview_amenityLabels_Smoking_Areas.
  ///
  /// In en, this message translates to:
  /// **'Smoking Areas'**
  String get propertyOverview_amenityLabels_Smoking_Areas;

  /// No description provided for @propertyOverview_amenityLabels_Snack_Bar.
  ///
  /// In en, this message translates to:
  /// **'Snack Bar'**
  String get propertyOverview_amenityLabels_Snack_Bar;

  /// No description provided for @propertyOverview_amenityLabels_Spa.
  ///
  /// In en, this message translates to:
  /// **'Spa'**
  String get propertyOverview_amenityLabels_Spa;

  /// No description provided for @propertyOverview_amenityLabels_Steam_Room.
  ///
  /// In en, this message translates to:
  /// **'Steam Room'**
  String get propertyOverview_amenityLabels_Steam_Room;

  /// No description provided for @propertyOverview_amenityLabels_Sun_Terrace.
  ///
  /// In en, this message translates to:
  /// **'Sun Terrace'**
  String get propertyOverview_amenityLabels_Sun_Terrace;

  /// No description provided for @propertyOverview_amenityLabels_Swimming_Pool.
  ///
  /// In en, this message translates to:
  /// **'Swimming Pool'**
  String get propertyOverview_amenityLabels_Swimming_Pool;

  /// No description provided for @propertyOverview_amenityLabels_TV.
  ///
  /// In en, this message translates to:
  /// **'TV'**
  String get propertyOverview_amenityLabels_TV;

  /// No description provided for @propertyOverview_amenityLabels_Terrace.
  ///
  /// In en, this message translates to:
  /// **'Terrace'**
  String get propertyOverview_amenityLabels_Terrace;

  /// No description provided for @propertyOverview_amenityLabels_Tour_Desk.
  ///
  /// In en, this message translates to:
  /// **'Tour Desk'**
  String get propertyOverview_amenityLabels_Tour_Desk;

  /// No description provided for @propertyOverview_amenityLabels_Underground_Parking.
  ///
  /// In en, this message translates to:
  /// **'Underground Parking'**
  String get propertyOverview_amenityLabels_Underground_Parking;

  /// No description provided for @propertyOverview_amenityLabels_Valet_Parking.
  ///
  /// In en, this message translates to:
  /// **'Valet Parking'**
  String get propertyOverview_amenityLabels_Valet_Parking;

  /// No description provided for @propertyOverview_amenityLabels_Wheelchair_Accessible.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair Accessible'**
  String get propertyOverview_amenityLabels_Wheelchair_Accessible;

  /// No description provided for @propertyOverview_amenityLabels_WiFi.
  ///
  /// In en, this message translates to:
  /// **'WiFi'**
  String get propertyOverview_amenityLabels_WiFi;

  /// No description provided for @propertyOverview_checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get propertyOverview_checkIn;

  /// No description provided for @propertyOverview_checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get propertyOverview_checkOut;

  /// No description provided for @propertyOverview_cleaningSafety_description.
  ///
  /// In en, this message translates to:
  /// **'This property has extensive hygiene measures in place, including contactless check-in and enhanced cleaning protocols.'**
  String get propertyOverview_cleaningSafety_description;

  /// No description provided for @propertyOverview_cleaningSafety_title.
  ///
  /// In en, this message translates to:
  /// **'Cleaning and safety practices'**
  String get propertyOverview_cleaningSafety_title;

  /// No description provided for @propertyOverview_contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get propertyOverview_contactInfo;

  /// No description provided for @propertyOverview_importantInfo.
  ///
  /// In en, this message translates to:
  /// **'Important information'**
  String get propertyOverview_importantInfo;

  /// No description provided for @propertyOverview_noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get propertyOverview_noReviewsYet;

  /// No description provided for @propertyOverview_popularAmenities.
  ///
  /// In en, this message translates to:
  /// **'Popular amenities'**
  String get propertyOverview_popularAmenities;

  /// No description provided for @propertyOverview_readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get propertyOverview_readMore;

  /// No description provided for @propertyOverview_seeAllAmenities.
  ///
  /// In en, this message translates to:
  /// **'See all {count} amenities'**
  String propertyOverview_seeAllAmenities(Object count);

  /// No description provided for @propertyOverview_showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get propertyOverview_showLess;

  /// No description provided for @propertyOverview_showLessAmenities.
  ///
  /// In en, this message translates to:
  /// **'Show less amenities'**
  String get propertyOverview_showLessAmenities;

  /// No description provided for @propertyOverview_verifiedReview.
  ///
  /// In en, this message translates to:
  /// **'{count} verified review'**
  String propertyOverview_verifiedReview(Object count);

  /// No description provided for @propertyOverview_verifiedReviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# verified review} other {# verified reviews}}'**
  String propertyOverview_verifiedReviewCount(num count);

  /// No description provided for @propertyOverview_verifiedReviews.
  ///
  /// In en, this message translates to:
  /// **'{count} verified reviews'**
  String propertyOverview_verifiedReviews(Object count);

  /// No description provided for @property_addressNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Address not available'**
  String get property_addressNotAvailable;

  /// No description provided for @property_bookingWidget_amenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get property_bookingWidget_amenities;

  /// No description provided for @property_bookingWidget_bookThisRoom.
  ///
  /// In en, this message translates to:
  /// **'Book This Room'**
  String get property_bookingWidget_bookThisRoom;

  /// No description provided for @property_bookingWidget_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get property_bookingWidget_description;

  /// No description provided for @property_bookingWidget_guests.
  ///
  /// In en, this message translates to:
  /// **'{count} guests'**
  String property_bookingWidget_guests(Object count);

  /// No description provided for @property_bookingWidget_roomDetails.
  ///
  /// In en, this message translates to:
  /// **'Room Details'**
  String get property_bookingWidget_roomDetails;

  /// No description provided for @property_bookingWidget_selectedRoom.
  ///
  /// In en, this message translates to:
  /// **'Selected Room'**
  String get property_bookingWidget_selectedRoom;

  /// No description provided for @property_breadcrumbHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get property_breadcrumbHome;

  /// No description provided for @property_breadcrumbStaysIn.
  ///
  /// In en, this message translates to:
  /// **'Stays in {city}'**
  String property_breadcrumbStaysIn(Object city);

  /// No description provided for @property_bundleActive.
  ///
  /// In en, this message translates to:
  /// **'Bundle Discount Active'**
  String get property_bundleActive;

  /// No description provided for @property_bundleApplied.
  ///
  /// In en, this message translates to:
  /// **'Bundle discount applied — you\'re saving {percent}% on this hotel'**
  String property_bundleApplied(Object percent);

  /// No description provided for @property_faq_checkInAnswer.
  ///
  /// In en, this message translates to:
  /// **'Check-in time is {time}'**
  String property_faq_checkInAnswer(Object time);

  /// No description provided for @property_faq_checkInQuestion.
  ///
  /// In en, this message translates to:
  /// **'What time is check-in at this property?'**
  String get property_faq_checkInQuestion;

  /// No description provided for @property_faq_checkOutAnswer.
  ///
  /// In en, this message translates to:
  /// **'Check-out time is {time}'**
  String property_faq_checkOutAnswer(Object time);

  /// No description provided for @property_faq_checkOutQuestion.
  ///
  /// In en, this message translates to:
  /// **'What are the check-out times?'**
  String get property_faq_checkOutQuestion;

  /// No description provided for @property_faq_fallbackCancellationAnswer.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policies vary by rate. Please check the room options above for specific cancellation terms before booking.'**
  String get property_faq_fallbackCancellationAnswer;

  /// No description provided for @property_faq_fallbackCancellationQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is the cancellation policy at {name}?'**
  String property_faq_fallbackCancellationQuestion(Object name);

  /// No description provided for @property_faq_fallbackModificationAnswer.
  ///
  /// In en, this message translates to:
  /// **'You can manage your booking through the confirmation email you receive after booking. For urgent changes, contact the property directly.'**
  String get property_faq_fallbackModificationAnswer;

  /// No description provided for @property_faq_fallbackModificationQuestion.
  ///
  /// In en, this message translates to:
  /// **'How do I modify or cancel my reservation?'**
  String get property_faq_fallbackModificationQuestion;

  /// No description provided for @property_faq_fallbackPaymentAnswer.
  ///
  /// In en, this message translates to:
  /// **'Most major credit and debit cards are accepted. Contact the property directly to confirm accepted payment methods.'**
  String get property_faq_fallbackPaymentAnswer;

  /// No description provided for @property_faq_fallbackPaymentQuestion.
  ///
  /// In en, this message translates to:
  /// **'Does {name} accept credit cards?'**
  String property_faq_fallbackPaymentQuestion(Object name);

  /// No description provided for @property_faq_importantQuestion.
  ///
  /// In en, this message translates to:
  /// **'Is there anything important I should know before booking?'**
  String get property_faq_importantQuestion;

  /// No description provided for @property_faq_parkingAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes, the property offers {facility}.'**
  String property_faq_parkingAnswer(Object facility);

  /// No description provided for @property_faq_parkingQuestion.
  ///
  /// In en, this message translates to:
  /// **'Does {name} have parking?'**
  String property_faq_parkingQuestion(Object name);

  /// No description provided for @property_faq_poolAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes, the property has {facility}.'**
  String property_faq_poolAnswer(Object facility);

  /// No description provided for @property_faq_poolQuestion.
  ///
  /// In en, this message translates to:
  /// **'Does {name} have a pool?'**
  String property_faq_poolQuestion(Object name);

  /// No description provided for @property_faq_restaurantAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes, the property has an on-site restaurant.'**
  String get property_faq_restaurantAnswer;

  /// No description provided for @property_faq_restaurantQuestion.
  ///
  /// In en, this message translates to:
  /// **'Is there a restaurant at {name}?'**
  String property_faq_restaurantQuestion(Object name);

  /// No description provided for @property_faq_title.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get property_faq_title;

  /// No description provided for @property_faq_wifiAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes, WiFi is available at the property.'**
  String get property_faq_wifiAnswer;

  /// No description provided for @property_faq_wifiQuestion.
  ///
  /// In en, this message translates to:
  /// **'Is WiFi available at {name}?'**
  String property_faq_wifiQuestion(Object name);

  /// No description provided for @property_locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get property_locationLabel;

  /// No description provided for @property_locationTitle.
  ///
  /// In en, this message translates to:
  /// **'Where you\'ll be'**
  String get property_locationTitle;

  /// No description provided for @property_mapOverlay_details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get property_mapOverlay_details;

  /// No description provided for @property_mapOverlay_exitFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Exit fullscreen'**
  String get property_mapOverlay_exitFullscreen;

  /// No description provided for @property_mapOverlay_fullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get property_mapOverlay_fullscreen;

  /// No description provided for @property_mapOverlay_getDirections.
  ///
  /// In en, this message translates to:
  /// **'Get directions...'**
  String get property_mapOverlay_getDirections;

  /// No description provided for @property_mapOverlay_kmAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String property_mapOverlay_kmAway(Object distance);

  /// No description provided for @property_mapOverlay_layers.
  ///
  /// In en, this message translates to:
  /// **'Layers'**
  String get property_mapOverlay_layers;

  /// No description provided for @property_mapOverlay_recenterMap.
  ///
  /// In en, this message translates to:
  /// **'Recenter Map'**
  String get property_mapOverlay_recenterMap;

  /// No description provided for @property_mapOverlay_selectMode.
  ///
  /// In en, this message translates to:
  /// **'Select Mode'**
  String get property_mapOverlay_selectMode;

  /// No description provided for @property_mapOverlay_viewOnMaps.
  ///
  /// In en, this message translates to:
  /// **'View on Maps'**
  String get property_mapOverlay_viewOnMaps;

  /// No description provided for @property_mapOverlay_whereFrom.
  ///
  /// In en, this message translates to:
  /// **'Where from?'**
  String get property_mapOverlay_whereFrom;

  /// No description provided for @property_metaDescription.
  ///
  /// In en, this message translates to:
  /// **'Rates, rooms and photos for {name}. Compare prices and book with free cancellation where available.'**
  String property_metaDescription(Object name);

  /// No description provided for @property_meta_closing.
  ///
  /// In en, this message translates to:
  /// **'Best deals on hotels with free cancellation options.'**
  String get property_meta_closing;

  /// No description provided for @property_meta_description.
  ///
  /// In en, this message translates to:
  /// **'Book {name} at the cheapest price.'**
  String property_meta_description(Object name);

  /// No description provided for @property_meta_descriptionIn.
  ///
  /// In en, this message translates to:
  /// **'Book {name} in {location} at the cheapest price.'**
  String property_meta_descriptionIn(Object name, Object location);

  /// No description provided for @property_meta_rated.
  ///
  /// In en, this message translates to:
  /// **'Rated {rating}/10.'**
  String property_meta_rated(Object rating);

  /// No description provided for @property_meta_title.
  ///
  /// In en, this message translates to:
  /// **'{name} – Cheapest Rates | CheapestGo'**
  String property_meta_title(Object name);

  /// No description provided for @property_mobileCta_checkRoomRates.
  ///
  /// In en, this message translates to:
  /// **'Check room rates'**
  String get property_mobileCta_checkRoomRates;

  /// No description provided for @property_mobileCta_from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get property_mobileCta_from;

  /// No description provided for @property_mobileCta_perNight.
  ///
  /// In en, this message translates to:
  /// **'/night'**
  String get property_mobileCta_perNight;

  /// No description provided for @property_mobileCta_viewRooms.
  ///
  /// In en, this message translates to:
  /// **'View Rooms'**
  String get property_mobileCta_viewRooms;

  /// No description provided for @property_nearby_addToTrip.
  ///
  /// In en, this message translates to:
  /// **'Add to trip'**
  String get property_nearby_addToTrip;

  /// No description provided for @property_nearby_away.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String property_nearby_away(Object distance);

  /// No description provided for @property_nearby_bike.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get property_nearby_bike;

  /// No description provided for @property_nearby_call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get property_nearby_call;

  /// No description provided for @property_nearby_categories_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get property_nearby_categories_all;

  /// No description provided for @property_nearby_categories_attraction.
  ///
  /// In en, this message translates to:
  /// **'Attractions & Parks'**
  String get property_nearby_categories_attraction;

  /// No description provided for @property_nearby_categories_cafe.
  ///
  /// In en, this message translates to:
  /// **'Cafés'**
  String get property_nearby_categories_cafe;

  /// No description provided for @property_nearby_categories_grocery.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get property_nearby_categories_grocery;

  /// No description provided for @property_nearby_categories_medical.
  ///
  /// In en, this message translates to:
  /// **'Hospitals & Health'**
  String get property_nearby_categories_medical;

  /// No description provided for @property_nearby_categories_restaurant.
  ///
  /// In en, this message translates to:
  /// **'Dining'**
  String get property_nearby_categories_restaurant;

  /// No description provided for @property_nearby_categories_transit.
  ///
  /// In en, this message translates to:
  /// **'Transit'**
  String get property_nearby_categories_transit;

  /// No description provided for @property_nearby_categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Place type'**
  String get property_nearby_categoryLabel;

  /// No description provided for @property_nearby_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get property_nearby_close;

  /// No description provided for @property_nearby_details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get property_nearby_details;

  /// No description provided for @property_nearby_directions_close.
  ///
  /// In en, this message translates to:
  /// **'Hide directions'**
  String get property_nearby_directions_close;

  /// No description provided for @property_nearby_directions_locateMe.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get property_nearby_directions_locateMe;

  /// No description provided for @property_nearby_directions_locating.
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get property_nearby_directions_locating;

  /// No description provided for @property_nearby_directions_locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your location. Type a starting point instead.'**
  String get property_nearby_directions_locationDenied;

  /// No description provided for @property_nearby_directions_open.
  ///
  /// In en, this message translates to:
  /// **'Get directions'**
  String get property_nearby_directions_open;

  /// No description provided for @property_nearby_directions_searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t search places. Try again.'**
  String get property_nearby_directions_searchFailed;

  /// No description provided for @property_nearby_directions_toHotel.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min to the hotel'**
  String property_nearby_directions_toHotel(Object minutes);

  /// No description provided for @property_nearby_directions_whereFrom.
  ///
  /// In en, this message translates to:
  /// **'Where from?'**
  String get property_nearby_directions_whereFrom;

  /// No description provided for @property_nearby_drive.
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get property_nearby_drive;

  /// No description provided for @property_nearby_fromHotel.
  ///
  /// In en, this message translates to:
  /// **'{distance} from the hotel'**
  String property_nearby_fromHotel(Object distance);

  /// No description provided for @property_nearby_googleMaps.
  ///
  /// In en, this message translates to:
  /// **'Google Maps'**
  String get property_nearby_googleMaps;

  /// No description provided for @property_nearby_hotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get property_nearby_hotel;

  /// No description provided for @property_nearby_loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load nearby places.'**
  String get property_nearby_loadFailed;

  /// No description provided for @property_nearby_loadingRoute.
  ///
  /// In en, this message translates to:
  /// **'Finding a route…'**
  String get property_nearby_loadingRoute;

  /// No description provided for @property_nearby_minutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String property_nearby_minutes(Object count);

  /// No description provided for @property_nearby_radiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Search radius'**
  String get property_nearby_radiusLabel;

  /// No description provided for @property_nearby_ratingOutOf5.
  ///
  /// In en, this message translates to:
  /// **'{rating} out of 5 stars'**
  String property_nearby_ratingOutOf5(Object rating);

  /// No description provided for @property_nearby_removeFromTrip.
  ///
  /// In en, this message translates to:
  /// **'Remove from trip'**
  String get property_nearby_removeFromTrip;

  /// No description provided for @property_nearby_retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get property_nearby_retry;

  /// No description provided for @property_nearby_reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# review} other {# reviews}}'**
  String property_nearby_reviewsCount(num count);

  /// No description provided for @property_nearby_routeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Route unavailable'**
  String get property_nearby_routeUnavailable;

  /// No description provided for @property_nearby_scrollLeft.
  ///
  /// In en, this message translates to:
  /// **'Scroll left'**
  String get property_nearby_scrollLeft;

  /// No description provided for @property_nearby_scrollRight.
  ///
  /// In en, this message translates to:
  /// **'Scroll right'**
  String get property_nearby_scrollRight;

  /// No description provided for @property_nearby_traffic.
  ///
  /// In en, this message translates to:
  /// **'Live traffic'**
  String get property_nearby_traffic;

  /// No description provided for @property_nearby_travelMode.
  ///
  /// In en, this message translates to:
  /// **'Travel mode'**
  String get property_nearby_travelMode;

  /// No description provided for @property_nearby_trip_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get property_nearby_trip_clear;

  /// No description provided for @property_nearby_trip_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t optimize this route.'**
  String get property_nearby_trip_failed;

  /// No description provided for @property_nearby_trip_max.
  ///
  /// In en, this message translates to:
  /// **'You can plan up to {max} stops.'**
  String property_nearby_trip_max(Object max);

  /// No description provided for @property_nearby_trip_optimize.
  ///
  /// In en, this message translates to:
  /// **'Optimize route'**
  String get property_nearby_trip_optimize;

  /// No description provided for @property_nearby_trip_optimizing.
  ///
  /// In en, this message translates to:
  /// **'Optimizing…'**
  String get property_nearby_trip_optimizing;

  /// No description provided for @property_nearby_trip_summary.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min round trip from the hotel'**
  String property_nearby_trip_summary(Object minutes);

  /// No description provided for @property_nearby_trip_title.
  ///
  /// In en, this message translates to:
  /// **'Your trip · {count}/{max}'**
  String property_nearby_trip_title(Object count, Object max);

  /// No description provided for @property_nearby_unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance unit'**
  String get property_nearby_unitLabel;

  /// No description provided for @property_nearby_walk.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get property_nearby_walk;

  /// No description provided for @property_nearby_weather_feelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels like {temp}'**
  String property_nearby_weather_feelsLike(Object temp);

  /// No description provided for @property_nearby_weather_highLow.
  ///
  /// In en, this message translates to:
  /// **'{high} / {low}'**
  String property_nearby_weather_highLow(Object high, Object low);

  /// No description provided for @property_nearby_website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get property_nearby_website;

  /// No description provided for @property_poiDetails_addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get property_poiDetails_addPhoto;

  /// No description provided for @property_poiDetails_brandReviews.
  ///
  /// In en, this message translates to:
  /// **'Cheapest Go Reviews'**
  String get property_poiDetails_brandReviews;

  /// No description provided for @property_poiDetails_closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get property_poiDetails_closed;

  /// No description provided for @property_poiDetails_commentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Share your experience...'**
  String get property_poiDetails_commentPlaceholder;

  /// No description provided for @property_poiDetails_communityPhotos.
  ///
  /// In en, this message translates to:
  /// **'Community Photos'**
  String get property_poiDetails_communityPhotos;

  /// No description provided for @property_poiDetails_foursquareRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Foursquare Recommendations'**
  String get property_poiDetails_foursquareRecommendations;

  /// No description provided for @property_poiDetails_googleFoursquareReviews.
  ///
  /// In en, this message translates to:
  /// **'Google & Foursquare Reviews'**
  String get property_poiDetails_googleFoursquareReviews;

  /// No description provided for @property_poiDetails_googleReviews.
  ///
  /// In en, this message translates to:
  /// **'Google Reviews'**
  String get property_poiDetails_googleReviews;

  /// No description provided for @property_poiDetails_justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get property_poiDetails_justNow;

  /// No description provided for @property_poiDetails_noReviews.
  ///
  /// In en, this message translates to:
  /// **'No direct reviews available for this place yet.'**
  String get property_poiDetails_noReviews;

  /// No description provided for @property_poiDetails_openNow.
  ///
  /// In en, this message translates to:
  /// **'Open Now'**
  String get property_poiDetails_openNow;

  /// No description provided for @property_poiDetails_openingHours.
  ///
  /// In en, this message translates to:
  /// **'Opening Hours'**
  String get property_poiDetails_openingHours;

  /// No description provided for @property_poiDetails_postReview.
  ///
  /// In en, this message translates to:
  /// **'Post Review'**
  String get property_poiDetails_postReview;

  /// No description provided for @property_poiDetails_you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get property_poiDetails_you;

  /// No description provided for @property_poiDetails_yourRating.
  ///
  /// In en, this message translates to:
  /// **'Your Rating'**
  String get property_poiDetails_yourRating;

  /// No description provided for @property_policies_cancellationPolicy.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Policy'**
  String get property_policies_cancellationPolicy;

  /// No description provided for @property_policies_checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get property_policies_checkIn;

  /// No description provided for @property_policies_checkInOut.
  ///
  /// In en, this message translates to:
  /// **'Check-in & Check-out'**
  String get property_policies_checkInOut;

  /// No description provided for @property_policies_checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get property_policies_checkOut;

  /// No description provided for @property_policies_contactProperty.
  ///
  /// In en, this message translates to:
  /// **'Contact property'**
  String get property_policies_contactProperty;

  /// No description provided for @property_policies_earlyDepartureBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} if you check out before your scheduled date.'**
  String property_policies_earlyDepartureBody(Object amount);

  /// No description provided for @property_policies_earlyDepartureFee.
  ///
  /// In en, this message translates to:
  /// **'Early Departure Fee:'**
  String get property_policies_earlyDepartureFee;

  /// No description provided for @property_policies_importantInformation.
  ///
  /// In en, this message translates to:
  /// **'Important Information'**
  String get property_policies_importantInformation;

  /// No description provided for @property_policies_noShowBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} if you don\'t check in without cancelling.'**
  String property_policies_noShowBody(Object amount);

  /// No description provided for @property_policies_noShowPenalty.
  ///
  /// In en, this message translates to:
  /// **'No-Show Penalty:'**
  String get property_policies_noShowPenalty;

  /// No description provided for @property_policies_nonRefundable.
  ///
  /// In en, this message translates to:
  /// **'Non-refundable'**
  String get property_policies_nonRefundable;

  /// No description provided for @property_policies_refundable.
  ///
  /// In en, this message translates to:
  /// **'Refundable'**
  String get property_policies_refundable;

  /// No description provided for @property_policies_title.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get property_policies_title;

  /// No description provided for @property_propertyNotFound.
  ///
  /// In en, this message translates to:
  /// **'Property not found. (ID: {id})'**
  String property_propertyNotFound(Object id);

  /// No description provided for @property_rooms_availableRooms.
  ///
  /// In en, this message translates to:
  /// **'Available Rooms ({count})'**
  String property_rooms_availableRooms(Object count);

  /// No description provided for @property_rooms_changeDates.
  ///
  /// In en, this message translates to:
  /// **'Change dates'**
  String get property_rooms_changeDates;

  /// No description provided for @property_rooms_checkAtCheckout.
  ///
  /// In en, this message translates to:
  /// **'Check at checkout'**
  String get property_rooms_checkAtCheckout;

  /// No description provided for @property_rooms_choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get property_rooms_choose;

  /// No description provided for @property_rooms_chooseRoom.
  ///
  /// In en, this message translates to:
  /// **'Choose room'**
  String get property_rooms_chooseRoom;

  /// No description provided for @property_rooms_etgNotice_description.
  ///
  /// In en, this message translates to:
  /// **'This property is managed by our partner booking system. Indicative prices are shown below. Please contact us to confirm availability and complete your reservation.'**
  String get property_rooms_etgNotice_description;

  /// No description provided for @property_rooms_etgNotice_title.
  ///
  /// In en, this message translates to:
  /// **'Online booking not yet available'**
  String get property_rooms_etgNotice_title;

  /// No description provided for @property_rooms_filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get property_rooms_filterAll;

  /// No description provided for @property_rooms_filterNonRefundable.
  ///
  /// In en, this message translates to:
  /// **'Non-refundable'**
  String get property_rooms_filterNonRefundable;

  /// No description provided for @property_rooms_filterRefundable.
  ///
  /// In en, this message translates to:
  /// **'Refundable'**
  String get property_rooms_filterRefundable;

  /// No description provided for @property_rooms_freeCancellation.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation'**
  String get property_rooms_freeCancellation;

  /// No description provided for @property_rooms_freeCancellationTick.
  ///
  /// In en, this message translates to:
  /// **'✓ Free cancellation'**
  String get property_rooms_freeCancellationTick;

  /// No description provided for @property_rooms_hotelPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Hotel photo'**
  String get property_rooms_hotelPhotoLabel;

  /// No description provided for @property_rooms_includesTaxes.
  ///
  /// In en, this message translates to:
  /// **'({nights, plural, one {1 night} other {# nights}}, 1 Room incl. taxes)'**
  String property_rooms_includesTaxes(num nights);

  /// No description provided for @property_rooms_noMeals.
  ///
  /// In en, this message translates to:
  /// **'No meals included'**
  String get property_rooms_noMeals;

  /// No description provided for @property_rooms_noNonRefundableRooms.
  ///
  /// In en, this message translates to:
  /// **'No non-refundable rooms available.'**
  String get property_rooms_noNonRefundableRooms;

  /// No description provided for @property_rooms_noRefundableRooms.
  ///
  /// In en, this message translates to:
  /// **'No refundable rooms available.'**
  String get property_rooms_noRefundableRooms;

  /// No description provided for @property_rooms_noRooms.
  ///
  /// In en, this message translates to:
  /// **'No rooms available for the selected dates.'**
  String get property_rooms_noRooms;

  /// No description provided for @property_rooms_nonRefundable.
  ///
  /// In en, this message translates to:
  /// **'Non-refundable'**
  String get property_rooms_nonRefundable;

  /// No description provided for @property_rooms_nonRefundablePill.
  ///
  /// In en, this message translates to:
  /// **'Non-Refundable'**
  String get property_rooms_nonRefundablePill;

  /// No description provided for @property_rooms_pageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String property_rooms_pageOf(Object current, Object total);

  /// No description provided for @property_rooms_perNight.
  ///
  /// In en, this message translates to:
  /// **'/night'**
  String get property_rooms_perNight;

  /// No description provided for @property_rooms_rateOptions.
  ///
  /// In en, this message translates to:
  /// **'{count} rate options'**
  String property_rooms_rateOptions(Object count);

  /// No description provided for @property_rooms_reserve.
  ///
  /// In en, this message translates to:
  /// **'Reserve'**
  String get property_rooms_reserve;

  /// No description provided for @property_rooms_room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get property_rooms_room;

  /// No description provided for @property_rooms_roomOnly.
  ///
  /// In en, this message translates to:
  /// **'Room only'**
  String get property_rooms_roomOnly;

  /// No description provided for @property_rooms_select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get property_rooms_select;

  /// No description provided for @property_rooms_showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get property_rooms_showLess;

  /// No description provided for @property_rooms_showingRooms.
  ///
  /// In en, this message translates to:
  /// **'Showing {start}–{end} of {total} rooms'**
  String property_rooms_showingRooms(Object start, Object end, Object total);

  /// No description provided for @property_rooms_sleeps.
  ///
  /// In en, this message translates to:
  /// **'Sleeps {count}'**
  String property_rooms_sleeps(Object count);

  /// No description provided for @property_rooms_standardRoom.
  ///
  /// In en, this message translates to:
  /// **'Standard Room'**
  String get property_rooms_standardRoom;

  /// No description provided for @property_rooms_total.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get property_rooms_total;

  /// No description provided for @property_rooms_viewHotelPhotos.
  ///
  /// In en, this message translates to:
  /// **'View hotel photos'**
  String get property_rooms_viewHotelPhotos;

  /// No description provided for @property_rooms_viewRoomPhotos.
  ///
  /// In en, this message translates to:
  /// **'View room photos'**
  String get property_rooms_viewRoomPhotos;

  /// No description provided for @property_savePercent.
  ///
  /// In en, this message translates to:
  /// **'SAVE {percent}%'**
  String property_savePercent(Object percent);

  /// No description provided for @property_v2_additionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional information'**
  String get property_v2_additionalInfo;

  /// No description provided for @property_v2_availableRooms.
  ///
  /// In en, this message translates to:
  /// **'Available Rooms'**
  String get property_v2_availableRooms;

  /// No description provided for @property_v2_cancellationPolicy.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policy'**
  String get property_v2_cancellationPolicy;

  /// No description provided for @property_v2_darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get property_v2_darkMode;

  /// No description provided for @property_v2_goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get property_v2_goBack;

  /// No description provided for @property_v2_greatStay.
  ///
  /// In en, this message translates to:
  /// **'Great stay'**
  String get property_v2_greatStay;

  /// No description provided for @property_v2_lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get property_v2_lightMode;

  /// No description provided for @property_v2_loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load property'**
  String get property_v2_loadFailed;

  /// No description provided for @property_v2_loadingNearby.
  ///
  /// In en, this message translates to:
  /// **'Loading nearby places…'**
  String get property_v2_loadingNearby;

  /// No description provided for @property_v2_mealPlan.
  ///
  /// In en, this message translates to:
  /// **'Meal plan'**
  String get property_v2_mealPlan;

  /// No description provided for @property_v2_nearbyPlaces.
  ///
  /// In en, this message translates to:
  /// **'Nearby Places'**
  String get property_v2_nearbyPlaces;

  /// No description provided for @property_v2_nextPhoto.
  ///
  /// In en, this message translates to:
  /// **'Next photo'**
  String get property_v2_nextPhoto;

  /// No description provided for @property_v2_notFound.
  ///
  /// In en, this message translates to:
  /// **'Property not found.'**
  String get property_v2_notFound;

  /// No description provided for @property_v2_photoOfProperty.
  ///
  /// In en, this message translates to:
  /// **'Photo of the property'**
  String get property_v2_photoOfProperty;

  /// No description provided for @property_v2_previousPhoto.
  ///
  /// In en, this message translates to:
  /// **'Previous photo'**
  String get property_v2_previousPhoto;

  /// No description provided for @property_v2_price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get property_v2_price;

  /// No description provided for @property_v2_rateOptionsFor.
  ///
  /// In en, this message translates to:
  /// **'Rates for {room}'**
  String property_v2_rateOptionsFor(Object room);

  /// No description provided for @property_v2_roomPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# photo} other {# photos}}'**
  String property_v2_roomPhotoCount(num count);

  /// No description provided for @property_v2_switchToDark.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get property_v2_switchToDark;

  /// No description provided for @property_v2_switchToLight.
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get property_v2_switchToLight;

  /// No description provided for @property_v2_whatGuestsSay.
  ///
  /// In en, this message translates to:
  /// **'What guests say'**
  String get property_v2_whatGuestsSay;

  /// No description provided for @property_weather_feelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels like'**
  String get property_weather_feelsLike;

  /// No description provided for @property_weather_forecast.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get property_weather_forecast;

  /// No description provided for @property_weather_humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get property_weather_humidity;

  /// No description provided for @property_weather_nextHours.
  ///
  /// In en, this message translates to:
  /// **'Next hours'**
  String get property_weather_nextHours;

  /// No description provided for @property_weather_poweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by Google Weather'**
  String get property_weather_poweredBy;

  /// No description provided for @property_weather_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get property_weather_today;

  /// No description provided for @property_weather_tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get property_weather_tomorrow;

  /// No description provided for @property_weather_uv_extreme.
  ///
  /// In en, this message translates to:
  /// **'Extreme'**
  String get property_weather_uv_extreme;

  /// No description provided for @property_weather_uv_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get property_weather_uv_high;

  /// No description provided for @property_weather_uv_low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get property_weather_uv_low;

  /// No description provided for @property_weather_uv_moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get property_weather_uv_moderate;

  /// No description provided for @property_weather_uv_veryHigh.
  ///
  /// In en, this message translates to:
  /// **'Very High'**
  String get property_weather_uv_veryHigh;

  /// No description provided for @property_weather_wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get property_weather_wind;

  /// No description provided for @pwa_addToHomeScreen.
  ///
  /// In en, this message translates to:
  /// **'Add to Home Screen'**
  String get pwa_addToHomeScreen;

  /// No description provided for @pwa_closeGuide.
  ///
  /// In en, this message translates to:
  /// **'Close guide'**
  String get pwa_closeGuide;

  /// No description provided for @pwa_installPrompt_body.
  ///
  /// In en, this message translates to:
  /// **'Add to your home screen for faster access.'**
  String get pwa_installPrompt_body;

  /// No description provided for @pwa_installPrompt_dismiss.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get pwa_installPrompt_dismiss;

  /// No description provided for @pwa_installPrompt_install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get pwa_installPrompt_install;

  /// No description provided for @pwa_installPrompt_title.
  ///
  /// In en, this message translates to:
  /// **'Get the CheapestGo app'**
  String get pwa_installPrompt_title;

  /// No description provided for @reviewsSection_aggregatedNote.
  ///
  /// In en, this message translates to:
  /// **'Guest score is based on aggregated ratings.'**
  String get reviewsSection_aggregatedNote;

  /// No description provided for @reviewsSection_aggregatedScore.
  ///
  /// In en, this message translates to:
  /// **'Aggregated guest score'**
  String get reviewsSection_aggregatedScore;

  /// No description provided for @reviewsSection_anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get reviewsSection_anonymous;

  /// No description provided for @reviewsSection_basedOnReview.
  ///
  /// In en, this message translates to:
  /// **'Based on {count} review'**
  String reviewsSection_basedOnReview(Object count);

  /// No description provided for @reviewsSection_basedOnReviews.
  ///
  /// In en, this message translates to:
  /// **'Based on {count} reviews'**
  String reviewsSection_basedOnReviews(Object count);

  /// No description provided for @reviewsSection_guestReviews.
  ///
  /// In en, this message translates to:
  /// **'Guest reviews'**
  String get reviewsSection_guestReviews;

  /// No description provided for @reviewsSection_loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more reviews'**
  String get reviewsSection_loadMore;

  /// No description provided for @reviewsSection_noReviews.
  ///
  /// In en, this message translates to:
  /// **'No individual reviews available.'**
  String get reviewsSection_noReviews;

  /// No description provided for @reviewsSection_noReviewsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No reviews available'**
  String get reviewsSection_noReviewsAvailable;

  /// No description provided for @reviewsSection_showAllReviews.
  ///
  /// In en, this message translates to:
  /// **'Show all {count} reviews'**
  String reviewsSection_showAllReviews(Object count);

  /// No description provided for @reviewsSection_showLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get reviewsSection_showLess;

  /// No description provided for @reviewsSection_showMore.
  ///
  /// In en, this message translates to:
  /// **'Show More'**
  String get reviewsSection_showMore;

  /// No description provided for @reviewsSection_showingCount.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total} reviews'**
  String reviewsSection_showingCount(Object shown, Object total);

  /// No description provided for @reviewsSection_sort_highestRated.
  ///
  /// In en, this message translates to:
  /// **'Highest rated'**
  String get reviewsSection_sort_highestRated;

  /// No description provided for @reviewsSection_sort_lowestRated.
  ///
  /// In en, this message translates to:
  /// **'Lowest rated'**
  String get reviewsSection_sort_lowestRated;

  /// No description provided for @reviewsSection_sort_newestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get reviewsSection_sort_newestFirst;

  /// No description provided for @reviewsSection_travelerTypes_business.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get reviewsSection_travelerTypes_business;

  /// No description provided for @reviewsSection_travelerTypes_couple.
  ///
  /// In en, this message translates to:
  /// **'Couple'**
  String get reviewsSection_travelerTypes_couple;

  /// No description provided for @reviewsSection_travelerTypes_family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get reviewsSection_travelerTypes_family;

  /// No description provided for @reviewsSection_travelerTypes_friendsGroup.
  ///
  /// In en, this message translates to:
  /// **'Friends/Group'**
  String get reviewsSection_travelerTypes_friendsGroup;

  /// No description provided for @reviewsSection_travelerTypes_solo.
  ///
  /// In en, this message translates to:
  /// **'Solo'**
  String get reviewsSection_travelerTypes_solo;

  /// No description provided for @reviewsSection_verifiedReviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# verified review} other {# verified reviews}}'**
  String reviewsSection_verifiedReviewCount(num count);

  /// No description provided for @reviewsSection_whoStaysHere.
  ///
  /// In en, this message translates to:
  /// **'Who stays here'**
  String get reviewsSection_whoStaysHere;

  /// No description provided for @search_chatPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ask anything — flights, hotels, trip planning...'**
  String get search_chatPlaceholder;

  /// No description provided for @search_chatWithCheap.
  ///
  /// In en, this message translates to:
  /// **'Chat with Cheap'**
  String get search_chatWithCheap;

  /// No description provided for @search_cityAirportPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search cities, airports…'**
  String get search_cityAirportPlaceholder;

  /// No description provided for @search_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get search_clear;

  /// No description provided for @search_destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get search_destination;

  /// No description provided for @search_freeCancel.
  ///
  /// In en, this message translates to:
  /// **'Free cancel'**
  String get search_freeCancel;

  /// No description provided for @search_golf_allCourses.
  ///
  /// In en, this message translates to:
  /// **'All courses →'**
  String get search_golf_allCourses;

  /// No description provided for @search_golf_anyDayNote.
  ///
  /// In en, this message translates to:
  /// **'Leave it open and the course shows its first day with a tee time.'**
  String get search_golf_anyDayNote;

  /// No description provided for @search_golf_courses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get search_golf_courses;

  /// No description provided for @search_golf_fewer.
  ///
  /// In en, this message translates to:
  /// **'Fewer players'**
  String get search_golf_fewer;

  /// No description provided for @search_golf_findCourse.
  ///
  /// In en, this message translates to:
  /// **'Search courses, cities, countries…'**
  String get search_golf_findCourse;

  /// No description provided for @search_golf_howMany.
  ///
  /// In en, this message translates to:
  /// **'How many players?'**
  String get search_golf_howMany;

  /// No description provided for @search_golf_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading courses…'**
  String get search_golf_loading;

  /// No description provided for @search_golf_more.
  ///
  /// In en, this message translates to:
  /// **'More players'**
  String get search_golf_more;

  /// No description provided for @search_golf_noMatch.
  ///
  /// In en, this message translates to:
  /// **'No course matches “{query}”.'**
  String search_golf_noMatch(Object query);

  /// No description provided for @search_golf_none.
  ///
  /// In en, this message translates to:
  /// **'No courses are open for booking yet.'**
  String get search_golf_none;

  /// No description provided for @search_golf_whenPlay.
  ///
  /// In en, this message translates to:
  /// **'When do you want to play?'**
  String get search_golf_whenPlay;

  /// No description provided for @search_hotels.
  ///
  /// In en, this message translates to:
  /// **'Hotels'**
  String get search_hotels;

  /// No description provided for @search_hotelsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search for hotels'**
  String get search_hotelsPlaceholder;

  /// No description provided for @search_imFlexible.
  ///
  /// In en, this message translates to:
  /// **'I\'m flexible'**
  String get search_imFlexible;

  /// No description provided for @search_listView.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get search_listView;

  /// No description provided for @search_mapView.
  ///
  /// In en, this message translates to:
  /// **'Map View'**
  String get search_mapView;

  /// No description provided for @search_metaTitle.
  ///
  /// In en, this message translates to:
  /// **'Search hotels and stays'**
  String get search_metaTitle;

  /// No description provided for @search_nights.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# night} other {# nights}}'**
  String search_nights(num count);

  /// No description provided for @search_noAirportsMatch.
  ///
  /// In en, this message translates to:
  /// **'No airports match “{query}”'**
  String search_noAirportsMatch(Object query);

  /// No description provided for @search_oneWay.
  ///
  /// In en, this message translates to:
  /// **'One-way'**
  String get search_oneWay;

  /// No description provided for @search_pickDates.
  ///
  /// In en, this message translates to:
  /// **'Pick your dates'**
  String get search_pickDates;

  /// No description provided for @search_popularAirports.
  ///
  /// In en, this message translates to:
  /// **'Popular airports'**
  String get search_popularAirports;

  /// No description provided for @search_prose_aDate.
  ///
  /// In en, this message translates to:
  /// **'a date'**
  String get search_prose_aDate;

  /// No description provided for @search_prose_anywhere.
  ///
  /// In en, this message translates to:
  /// **'somewhere amazing'**
  String get search_prose_anywhere;

  /// No description provided for @search_prose_firstOpenDay.
  ///
  /// In en, this message translates to:
  /// **'the first open day'**
  String get search_prose_firstOpenDay;

  /// No description provided for @search_prose_flexibleTrip.
  ///
  /// In en, this message translates to:
  /// **'a flexible trip'**
  String get search_prose_flexibleTrip;

  /// No description provided for @search_prose_flyFrom.
  ///
  /// In en, this message translates to:
  /// **'Fly me from '**
  String get search_prose_flyFrom;

  /// No description provided for @search_prose_forPlayers.
  ///
  /// In en, this message translates to:
  /// **', for '**
  String get search_prose_forPlayers;

  /// No description provided for @search_prose_fromDates.
  ///
  /// In en, this message translates to:
  /// **', from '**
  String get search_prose_fromDates;

  /// No description provided for @search_prose_justMe.
  ///
  /// In en, this message translates to:
  /// **'just me'**
  String get search_prose_justMe;

  /// No description provided for @search_prose_ofUs.
  ///
  /// In en, this message translates to:
  /// **'{count} of us'**
  String search_prose_ofUs(Object count);

  /// No description provided for @search_prose_onDates.
  ///
  /// In en, this message translates to:
  /// **', on '**
  String get search_prose_onDates;

  /// No description provided for @search_prose_onDay.
  ///
  /// In en, this message translates to:
  /// **', on '**
  String get search_prose_onDay;

  /// No description provided for @search_prose_origin.
  ///
  /// In en, this message translates to:
  /// **'wherever you are'**
  String get search_prose_origin;

  /// No description provided for @search_prose_players.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# player} other {# players}}'**
  String search_prose_players(num count);

  /// No description provided for @search_prose_sometime.
  ///
  /// In en, this message translates to:
  /// **'sometime soon'**
  String get search_prose_sometime;

  /// No description provided for @search_prose_stayIn.
  ///
  /// In en, this message translates to:
  /// **'Find me a stay in'**
  String get search_prose_stayIn;

  /// No description provided for @search_prose_teeOffAt.
  ///
  /// In en, this message translates to:
  /// **'Tee off at'**
  String get search_prose_teeOffAt;

  /// No description provided for @search_prose_theCourse.
  ///
  /// In en, this message translates to:
  /// **'the course'**
  String get search_prose_theCourse;

  /// No description provided for @search_prose_to.
  ///
  /// In en, this message translates to:
  /// **' to'**
  String get search_prose_to;

  /// No description provided for @search_prose_withTravelers.
  ///
  /// In en, this message translates to:
  /// **', with '**
  String get search_prose_withTravelers;

  /// No description provided for @search_prose_yourDates.
  ///
  /// In en, this message translates to:
  /// **'your dates'**
  String get search_prose_yourDates;

  /// No description provided for @search_recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get search_recent;

  /// No description provided for @search_results_activeFilters.
  ///
  /// In en, this message translates to:
  /// **'Active Filters:'**
  String get search_results_activeFilters;

  /// No description provided for @search_results_amenitiesSuffix.
  ///
  /// In en, this message translates to:
  /// **'{count} amenities'**
  String search_results_amenitiesSuffix(Object count);

  /// No description provided for @search_results_anyWeek.
  ///
  /// In en, this message translates to:
  /// **'Any week'**
  String get search_results_anyWeek;

  /// No description provided for @search_results_anywhere.
  ///
  /// In en, this message translates to:
  /// **'Anywhere'**
  String get search_results_anywhere;

  /// No description provided for @search_results_boardTypes_AI.
  ///
  /// In en, this message translates to:
  /// **'All Inclusive'**
  String get search_results_boardTypes_AI;

  /// No description provided for @search_results_boardTypes_BB.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get search_results_boardTypes_BB;

  /// No description provided for @search_results_boardTypes_FB.
  ///
  /// In en, this message translates to:
  /// **'Full Board'**
  String get search_results_boardTypes_FB;

  /// No description provided for @search_results_boardTypes_HB.
  ///
  /// In en, this message translates to:
  /// **'Half Board'**
  String get search_results_boardTypes_HB;

  /// No description provided for @search_results_boardTypes_RO.
  ///
  /// In en, this message translates to:
  /// **'Room Only'**
  String get search_results_boardTypes_RO;

  /// No description provided for @search_results_freeCancellation.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation'**
  String get search_results_freeCancellation;

  /// No description provided for @search_results_guestCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, one {guest} other {guests}}'**
  String search_results_guestCount(num count, Object guest, Object guests);

  /// No description provided for @search_results_namePrefix.
  ///
  /// In en, this message translates to:
  /// **'Name: {name}'**
  String search_results_namePrefix(Object name);

  /// No description provided for @search_results_otherCities.
  ///
  /// In en, this message translates to:
  /// **'Other cities:'**
  String get search_results_otherCities;

  /// No description provided for @search_results_ratingPrefix.
  ///
  /// In en, this message translates to:
  /// **'Rating {rating}+'**
  String search_results_ratingPrefix(Object rating);

  /// No description provided for @search_results_reviewsSuffix.
  ///
  /// In en, this message translates to:
  /// **'{count}+ reviews'**
  String search_results_reviewsSuffix(Object count);

  /// No description provided for @search_results_showingHotelsIn.
  ///
  /// In en, this message translates to:
  /// **'Showing hotels in'**
  String get search_results_showingHotelsIn;

  /// No description provided for @search_results_starSuffix.
  ///
  /// In en, this message translates to:
  /// **'{stars} stars'**
  String search_results_starSuffix(Object stars);

  /// No description provided for @search_results_whereTo.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get search_results_whereTo;

  /// No description provided for @search_roundTrip.
  ///
  /// In en, this message translates to:
  /// **'Round-trip'**
  String get search_roundTrip;

  /// No description provided for @search_trending.
  ///
  /// In en, this message translates to:
  /// **'Trending right now'**
  String get search_trending;

  /// No description provided for @search_trendingCities.
  ///
  /// In en, this message translates to:
  /// **'Popular cities'**
  String get search_trendingCities;

  /// No description provided for @search_v2_checkingCount.
  ///
  /// In en, this message translates to:
  /// **'Checking {count}…'**
  String search_v2_checkingCount(Object count);

  /// No description provided for @search_v2_clusterChecking.
  ///
  /// In en, this message translates to:
  /// **'checking {count}…'**
  String search_v2_clusterChecking(Object count);

  /// No description provided for @search_v2_clusterFrom.
  ///
  /// In en, this message translates to:
  /// **'from {price}'**
  String search_v2_clusterFrom(Object price);

  /// No description provided for @search_v2_clusterHotels.
  ///
  /// In en, this message translates to:
  /// **'{count} hotels'**
  String search_v2_clusterHotels(Object count);

  /// No description provided for @search_v2_hideCards.
  ///
  /// In en, this message translates to:
  /// **'Hide cards'**
  String get search_v2_hideCards;

  /// No description provided for @search_v2_hideStayCards.
  ///
  /// In en, this message translates to:
  /// **'Hide stay cards'**
  String get search_v2_hideStayCards;

  /// No description provided for @search_v2_mapLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading map…'**
  String get search_v2_mapLoading;

  /// No description provided for @search_v2_noAccommodations.
  ///
  /// In en, this message translates to:
  /// **'No accommodations found'**
  String get search_v2_noAccommodations;

  /// No description provided for @search_v2_staysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Stays'**
  String search_v2_staysCount(Object count);

  /// No description provided for @search_validation_allHotelFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'All fields are required to search for hotels'**
  String get search_validation_allHotelFieldsRequired;

  /// No description provided for @search_validation_fieldList.
  ///
  /// In en, this message translates to:
  /// **'{fields} and {last}'**
  String search_validation_fieldList(Object fields, Object last);

  /// No description provided for @search_validation_fields_checkInDate.
  ///
  /// In en, this message translates to:
  /// **'check-in date'**
  String get search_validation_fields_checkInDate;

  /// No description provided for @search_validation_fields_checkOutDate.
  ///
  /// In en, this message translates to:
  /// **'check-out date'**
  String get search_validation_fields_checkOutDate;

  /// No description provided for @search_validation_fields_destination.
  ///
  /// In en, this message translates to:
  /// **'destination'**
  String get search_validation_fields_destination;

  /// No description provided for @search_validation_listSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get search_validation_listSeparator;

  /// No description provided for @search_validation_selectField.
  ///
  /// In en, this message translates to:
  /// **'Please select {field}'**
  String search_validation_selectField(Object field);

  /// No description provided for @search_viewStay.
  ///
  /// In en, this message translates to:
  /// **'View Stay'**
  String get search_viewStay;

  /// No description provided for @search_whenFlying.
  ///
  /// In en, this message translates to:
  /// **'When are you flying?'**
  String get search_whenFlying;

  /// No description provided for @seo_faq_a1.
  ///
  /// In en, this message translates to:
  /// **'CheapestGo searches across multiple airlines and global distribution systems to surface the lowest available fares in real time, letting you compare and book in one place.'**
  String get seo_faq_a1;

  /// No description provided for @seo_faq_a2.
  ///
  /// In en, this message translates to:
  /// **'Yes. CheapestGo supports booking flights, hotels, apartments, and unique stays — all from a single platform.'**
  String get seo_faq_a2;

  /// No description provided for @seo_faq_a3.
  ///
  /// In en, this message translates to:
  /// **'Yes, searching and comparing prices on CheapestGo is completely free. You only pay when you book.'**
  String get seo_faq_a3;

  /// No description provided for @seo_faq_a4.
  ///
  /// In en, this message translates to:
  /// **'CheapestGo supports multiple currencies and automatically converts prices based on your preference so you can always see costs in your local currency.'**
  String get seo_faq_a4;

  /// No description provided for @seo_faq_q1.
  ///
  /// In en, this message translates to:
  /// **'How does CheapestGo find cheap flights?'**
  String get seo_faq_q1;

  /// No description provided for @seo_faq_q2.
  ///
  /// In en, this message translates to:
  /// **'Can I book both flights and hotels on CheapestGo?'**
  String get seo_faq_q2;

  /// No description provided for @seo_faq_q3.
  ///
  /// In en, this message translates to:
  /// **'Is CheapestGo free to use?'**
  String get seo_faq_q3;

  /// No description provided for @seo_faq_q4.
  ///
  /// In en, this message translates to:
  /// **'What currencies does CheapestGo support?'**
  String get seo_faq_q4;

  /// No description provided for @seo_homeDescription.
  ///
  /// In en, this message translates to:
  /// **'Discover the best travel deals globally. Plan your flights and hotels easily, save money, and start exploring the world.'**
  String get seo_homeDescription;

  /// No description provided for @seo_homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover and Book Your Next Global Journey'**
  String get seo_homeTitle;

  /// No description provided for @seo_orgDescription.
  ///
  /// In en, this message translates to:
  /// **'CheapestGo is a modern travel booking platform helping travelers find the cheapest flights and hotels worldwide.'**
  String get seo_orgDescription;

  /// No description provided for @support_attach.
  ///
  /// In en, this message translates to:
  /// **'Attach a file'**
  String get support_attach;

  /// No description provided for @support_automated.
  ///
  /// In en, this message translates to:
  /// **'Help Centre · automated'**
  String get support_automated;

  /// No description provided for @support_close.
  ///
  /// In en, this message translates to:
  /// **'Close support chat'**
  String get support_close;

  /// No description provided for @support_empty.
  ///
  /// In en, this message translates to:
  /// **'Send us a message and someone will answer.'**
  String get support_empty;

  /// No description provided for @support_fileExpired.
  ///
  /// In en, this message translates to:
  /// **'no longer stored'**
  String get support_fileExpired;

  /// No description provided for @support_notTranslated.
  ///
  /// In en, this message translates to:
  /// **'Shown as written — this could not be translated.'**
  String get support_notTranslated;

  /// No description provided for @support_open.
  ///
  /// In en, this message translates to:
  /// **'Open support chat'**
  String get support_open;

  /// No description provided for @support_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Type your message'**
  String get support_placeholder;

  /// No description provided for @support_quickHeading.
  ///
  /// In en, this message translates to:
  /// **'Common questions'**
  String get support_quickHeading;

  /// No description provided for @support_quick_changes.
  ///
  /// In en, this message translates to:
  /// **'Cancel or change a booking'**
  String get support_quick_changes;

  /// No description provided for @support_quick_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Where\'s my confirmation?'**
  String get support_quick_confirmation;

  /// No description provided for @support_quick_payment.
  ///
  /// In en, this message translates to:
  /// **'A payment problem'**
  String get support_quick_payment;

  /// No description provided for @support_quick_priceGap.
  ///
  /// In en, this message translates to:
  /// **'The price changed at checkout'**
  String get support_quick_priceGap;

  /// No description provided for @support_quick_refunds.
  ///
  /// In en, this message translates to:
  /// **'When do I get my refund?'**
  String get support_quick_refunds;

  /// No description provided for @support_reference.
  ///
  /// In en, this message translates to:
  /// **'Chat {reference}'**
  String support_reference(Object reference);

  /// No description provided for @support_removeFile.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get support_removeFile;

  /// No description provided for @support_reopens.
  ///
  /// In en, this message translates to:
  /// **'Nobody is at the desk right now. We reply from {when}.'**
  String support_reopens(Object when);

  /// No description provided for @support_reopensToday.
  ///
  /// In en, this message translates to:
  /// **'Nobody is at the desk right now. We reply from {when} today.'**
  String support_reopensToday(Object when);

  /// No description provided for @support_send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get support_send;

  /// No description provided for @support_sendFailed.
  ///
  /// In en, this message translates to:
  /// **'That message did not send. Try again.'**
  String get support_sendFailed;

  /// No description provided for @support_showOriginal.
  ///
  /// In en, this message translates to:
  /// **'Show original'**
  String get support_showOriginal;

  /// No description provided for @support_showTranslation.
  ///
  /// In en, this message translates to:
  /// **'Show translation'**
  String get support_showTranslation;

  /// No description provided for @support_solvedNote.
  ///
  /// In en, this message translates to:
  /// **'Glad that helped. Write to us any time if something else comes up.'**
  String get support_solvedNote;

  /// No description provided for @support_talkToAPerson.
  ///
  /// In en, this message translates to:
  /// **'Talk to a person'**
  String get support_talkToAPerson;

  /// No description provided for @support_thatAnsweredIt.
  ///
  /// In en, this message translates to:
  /// **'That answered it'**
  String get support_thatAnsweredIt;

  /// No description provided for @support_title.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support_title;

  /// No description provided for @support_translating.
  ///
  /// In en, this message translates to:
  /// **'Translating…'**
  String get support_translating;

  /// No description provided for @theme_switchToDark.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get theme_switchToDark;

  /// No description provided for @theme_switchToLight.
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get theme_switchToLight;

  /// No description provided for @topCities_exploreHotels.
  ///
  /// In en, this message translates to:
  /// **'Explore Hotels'**
  String get topCities_exploreHotels;

  /// No description provided for @topCities_headerHighlight.
  ///
  /// In en, this message translates to:
  /// **'Worldwide'**
  String get topCities_headerHighlight;

  /// No description provided for @topCities_headerMain.
  ///
  /// In en, this message translates to:
  /// **'Top Cities'**
  String get topCities_headerMain;

  /// No description provided for @topCities_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Most visited destinations · find hotels instantly'**
  String get topCities_subtitle;

  /// No description provided for @topDestinations_findHotels.
  ///
  /// In en, this message translates to:
  /// **'Find Hotels'**
  String get topDestinations_findHotels;

  /// No description provided for @topDestinations_headerHighlight.
  ///
  /// In en, this message translates to:
  /// **'Worldwide'**
  String get topDestinations_headerHighlight;

  /// No description provided for @topDestinations_headerMain.
  ///
  /// In en, this message translates to:
  /// **'Top Destinations'**
  String get topDestinations_headerMain;

  /// No description provided for @topDestinations_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Iconic experiences from every corner of the globe'**
  String get topDestinations_subtitle;

  /// No description provided for @trips_bookingCard_actions_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get trips_bookingCard_actions_cancel;

  /// No description provided for @trips_bookingCard_actions_details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get trips_bookingCard_actions_details;

  /// No description provided for @trips_bookingCard_actions_map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get trips_bookingCard_actions_map;

  /// No description provided for @trips_bookingCard_actions_modify.
  ///
  /// In en, this message translates to:
  /// **'Modify'**
  String get trips_bookingCard_actions_modify;

  /// No description provided for @trips_bookingCard_actions_receipt.
  ///
  /// In en, this message translates to:
  /// **'Download receipt'**
  String get trips_bookingCard_actions_receipt;

  /// No description provided for @trips_bookingCard_actions_retryRefund.
  ///
  /// In en, this message translates to:
  /// **'Retry refund'**
  String get trips_bookingCard_actions_retryRefund;

  /// No description provided for @trips_bookingCard_adult.
  ///
  /// In en, this message translates to:
  /// **'{count} adult'**
  String trips_bookingCard_adult(Object count);

  /// No description provided for @trips_bookingCard_adults.
  ///
  /// In en, this message translates to:
  /// **'{count} adults'**
  String trips_bookingCard_adults(Object count);

  /// No description provided for @trips_bookingCard_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get trips_bookingCard_cancelled;

  /// No description provided for @trips_bookingCard_child.
  ///
  /// In en, this message translates to:
  /// **'{count} child'**
  String trips_bookingCard_child(Object count);

  /// No description provided for @trips_bookingCard_children.
  ///
  /// In en, this message translates to:
  /// **'{count} children'**
  String trips_bookingCard_children(Object count);

  /// No description provided for @trips_bookingCard_night.
  ///
  /// In en, this message translates to:
  /// **'{count} night'**
  String trips_bookingCard_night(Object count);

  /// No description provided for @trips_bookingCard_nights.
  ///
  /// In en, this message translates to:
  /// **'{count} nights'**
  String trips_bookingCard_nights(Object count);

  /// No description provided for @trips_bookingCard_policyBadges_freeCancellation.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation'**
  String get trips_bookingCard_policyBadges_freeCancellation;

  /// No description provided for @trips_bookingCard_policyBadges_nonRefundable.
  ///
  /// In en, this message translates to:
  /// **'Non-refundable'**
  String get trips_bookingCard_policyBadges_nonRefundable;

  /// No description provided for @trips_bookingCard_policyBadges_partialRefund.
  ///
  /// In en, this message translates to:
  /// **'Partial refund'**
  String get trips_bookingCard_policyBadges_partialRefund;

  /// No description provided for @trips_bookingCard_ratings_excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get trips_bookingCard_ratings_excellent;

  /// No description provided for @trips_bookingCard_ratings_exceptional.
  ///
  /// In en, this message translates to:
  /// **'Exceptional'**
  String get trips_bookingCard_ratings_exceptional;

  /// No description provided for @trips_bookingCard_ratings_good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get trips_bookingCard_ratings_good;

  /// No description provided for @trips_bookingCard_ratings_pleasant.
  ///
  /// In en, this message translates to:
  /// **'Pleasant'**
  String get trips_bookingCard_ratings_pleasant;

  /// No description provided for @trips_bookingCard_ratings_veryGood.
  ///
  /// In en, this message translates to:
  /// **'Very Good'**
  String get trips_bookingCard_ratings_veryGood;

  /// No description provided for @trips_bookingCard_reviews.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String trips_bookingCard_reviews(Object count);

  /// No description provided for @trips_bookingCard_stayDates.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String trips_bookingCard_stayDates(Object from, Object to);

  /// No description provided for @trips_bookingCard_total.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get trips_bookingCard_total;

  /// No description provided for @trips_bookingCard_totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get trips_bookingCard_totalPaid;

  /// No description provided for @trips_bookingCard_tripCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip completed'**
  String get trips_bookingCard_tripCompleted;

  /// No description provided for @trips_bookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get trips_bookingDetails;

  /// No description provided for @trips_cancellationFeeCard_fee.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Fee'**
  String get trips_cancellationFeeCard_fee;

  /// No description provided for @trips_cancellationFeeCard_ifYouCancelNow.
  ///
  /// In en, this message translates to:
  /// **'If you cancel now:'**
  String get trips_cancellationFeeCard_ifYouCancelNow;

  /// No description provided for @trips_cancellationFeeCard_youllReceive.
  ///
  /// In en, this message translates to:
  /// **'You\'ll Receive'**
  String get trips_cancellationFeeCard_youllReceive;

  /// No description provided for @trips_cancellationModal_bookingId.
  ///
  /// In en, this message translates to:
  /// **'Booking ID: {id}'**
  String trips_cancellationModal_bookingId(Object id);

  /// No description provided for @trips_cancellationModal_cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get trips_cancellationModal_cancelBooking;

  /// No description provided for @trips_cancellationModal_cancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling...'**
  String get trips_cancellationModal_cancelling;

  /// No description provided for @trips_cancellationModal_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get trips_cancellationModal_close;

  /// No description provided for @trips_cancellationModal_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cancellation'**
  String get trips_cancellationModal_confirm;

  /// No description provided for @trips_cancellationModal_confirmQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure you want to cancel this booking?'**
  String get trips_cancellationModal_confirmQuestion;

  /// No description provided for @trips_cancellationModal_important.
  ///
  /// In en, this message translates to:
  /// **'Important:'**
  String get trips_cancellationModal_important;

  /// No description provided for @trips_cancellationModal_keepBooking.
  ///
  /// In en, this message translates to:
  /// **'Keep Booking'**
  String get trips_cancellationModal_keepBooking;

  /// No description provided for @trips_cancellationModal_loadingPolicy.
  ///
  /// In en, this message translates to:
  /// **'Loading cancellation policy...'**
  String get trips_cancellationModal_loadingPolicy;

  /// No description provided for @trips_cancellationModal_policyTimeline.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Policy Timeline'**
  String get trips_cancellationModal_policyTimeline;

  /// No description provided for @trips_cancellationModal_retryRefund.
  ///
  /// In en, this message translates to:
  /// **'Retry Refund'**
  String get trips_cancellationModal_retryRefund;

  /// No description provided for @trips_cancellationModal_retryRefundTitle.
  ///
  /// In en, this message translates to:
  /// **'Retry Refund'**
  String get trips_cancellationModal_retryRefundTitle;

  /// No description provided for @trips_cancellationModal_retrying.
  ///
  /// In en, this message translates to:
  /// **'Retrying...'**
  String get trips_cancellationModal_retrying;

  /// No description provided for @trips_cancellationModal_title.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get trips_cancellationModal_title;

  /// No description provided for @trips_cancellationModal_tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get trips_cancellationModal_tryAgain;

  /// No description provided for @trips_cancellationModal_unableTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to Proceed'**
  String get trips_cancellationModal_unableTitle;

  /// No description provided for @trips_cancellationModal_unableToLoadPolicy.
  ///
  /// In en, this message translates to:
  /// **'Unable to load policy'**
  String get trips_cancellationModal_unableToLoadPolicy;

  /// No description provided for @trips_cancellationPolicies_before.
  ///
  /// In en, this message translates to:
  /// **'Before: '**
  String get trips_cancellationPolicies_before;

  /// No description provided for @trips_cancellationPolicies_cancellationFee.
  ///
  /// In en, this message translates to:
  /// **'Cancellation fee: {amount}'**
  String trips_cancellationPolicies_cancellationFee(Object amount);

  /// No description provided for @trips_cancellationPolicies_earlyDepartureDescription.
  ///
  /// In en, this message translates to:
  /// **'{amount} fee applies if you check out before your scheduled date.'**
  String trips_cancellationPolicies_earlyDepartureDescription(Object amount);

  /// No description provided for @trips_cancellationPolicies_earlyDepartureFee.
  ///
  /// In en, this message translates to:
  /// **'Early Departure Fee'**
  String get trips_cancellationPolicies_earlyDepartureFee;

  /// No description provided for @trips_cancellationPolicies_importantNotes.
  ///
  /// In en, this message translates to:
  /// **'Important Notes'**
  String get trips_cancellationPolicies_importantNotes;

  /// No description provided for @trips_cancellationPolicies_noPolicy.
  ///
  /// In en, this message translates to:
  /// **'No specific cancellation policy available. Standard terms apply.'**
  String get trips_cancellationPolicies_noPolicy;

  /// No description provided for @trips_cancellationPolicies_noShowDescription.
  ///
  /// In en, this message translates to:
  /// **'{amount} will be charged if you don\'t check in without cancelling.'**
  String trips_cancellationPolicies_noShowDescription(Object amount);

  /// No description provided for @trips_cancellationPolicies_noShowPenalty.
  ///
  /// In en, this message translates to:
  /// **'No-Show Penalty'**
  String get trips_cancellationPolicies_noShowPenalty;

  /// No description provided for @trips_cancellationPolicies_passed.
  ///
  /// In en, this message translates to:
  /// **'Passed: '**
  String get trips_cancellationPolicies_passed;

  /// No description provided for @trips_eTicket.
  ///
  /// In en, this message translates to:
  /// **'E-Ticket'**
  String get trips_eTicket;

  /// No description provided for @trips_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Ready to explore? Find flights and hotels at the best prices.'**
  String get trips_emptyHint;

  /// No description provided for @trips_emptyState_allTitle.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get trips_emptyState_allTitle;

  /// No description provided for @trips_emptyState_otherDesc.
  ///
  /// In en, this message translates to:
  /// **'Start exploring and book your first trip'**
  String get trips_emptyState_otherDesc;

  /// No description provided for @trips_emptyState_pastTitle.
  ///
  /// In en, this message translates to:
  /// **'No past trips'**
  String get trips_emptyState_pastTitle;

  /// No description provided for @trips_emptyState_upcomingDesc.
  ///
  /// In en, this message translates to:
  /// **'Time to plan your next adventure!'**
  String get trips_emptyState_upcomingDesc;

  /// No description provided for @trips_emptyState_upcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'No upcoming trips'**
  String get trips_emptyState_upcomingTitle;

  /// No description provided for @trips_exploreDestinations.
  ///
  /// In en, this message translates to:
  /// **'Explore destinations'**
  String get trips_exploreDestinations;

  /// No description provided for @trips_flightBookingCard_addBookingNote.
  ///
  /// In en, this message translates to:
  /// **'Add Booking Note'**
  String get trips_flightBookingCard_addBookingNote;

  /// No description provided for @trips_flightBookingCard_airlineBookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Airline booking details'**
  String get trips_flightBookingCard_airlineBookingDetails;

  /// No description provided for @trips_flightBookingCard_airlineDetails.
  ///
  /// In en, this message translates to:
  /// **'Airline details'**
  String get trips_flightBookingCard_airlineDetails;

  /// No description provided for @trips_flightBookingCard_amErrors_cancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Cancellation failed. Please contact support.'**
  String get trips_flightBookingCard_amErrors_cancelFailed;

  /// No description provided for @trips_flightBookingCard_amErrors_duffelCannotCancel.
  ///
  /// In en, this message translates to:
  /// **'This booking cannot be cancelled online. Please contact us at crm@cheapestgo.com to request a manual cancellation.'**
  String get trips_flightBookingCard_amErrors_duffelCannotCancel;

  /// No description provided for @trips_flightBookingCard_amErrors_mystiflyCannotCancel.
  ///
  /// In en, this message translates to:
  /// **'This ticketed booking cannot be cancelled via API. Please email crm@myfarebox.com to request cancellation.'**
  String get trips_flightBookingCard_amErrors_mystiflyCannotCancel;

  /// No description provided for @trips_flightBookingCard_amErrors_networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again.'**
  String get trips_flightBookingCard_amErrors_networkError;

  /// No description provided for @trips_flightBookingCard_arriveAt.
  ///
  /// In en, this message translates to:
  /// **'Arrive at'**
  String get trips_flightBookingCard_arriveAt;

  /// No description provided for @trips_flightBookingCard_assignedSeats.
  ///
  /// In en, this message translates to:
  /// **'Assigned Seats'**
  String get trips_flightBookingCard_assignedSeats;

  /// No description provided for @trips_flightBookingCard_bookingNotes.
  ///
  /// In en, this message translates to:
  /// **'Booking Notes'**
  String get trips_flightBookingCard_bookingNotes;

  /// No description provided for @trips_flightBookingCard_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get trips_flightBookingCard_cancel;

  /// No description provided for @trips_flightBookingCard_cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get trips_flightBookingCard_cancelBooking;

  /// No description provided for @trips_flightBookingCard_cancelModal_baseFareNonRefundable.
  ///
  /// In en, this message translates to:
  /// **'The base fare is non-refundable — only taxes and fees are returned.'**
  String get trips_flightBookingCard_cancelModal_baseFareNonRefundable;

  /// No description provided for @trips_flightBookingCard_cancelModal_cancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling…'**
  String get trips_flightBookingCard_cancelModal_cancelling;

  /// No description provided for @trips_flightBookingCard_cancelModal_cannotCancelOnline.
  ///
  /// In en, this message translates to:
  /// **'This booking cannot be cancelled online. Please contact support.'**
  String get trips_flightBookingCard_cancelModal_cannotCancelOnline;

  /// No description provided for @trips_flightBookingCard_cancelModal_cannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get trips_flightBookingCard_cancelModal_cannotUndo;

  /// No description provided for @trips_flightBookingCard_cancelModal_checkingRefund.
  ///
  /// In en, this message translates to:
  /// **'Checking with airline for live refund amount…'**
  String get trips_flightBookingCard_cancelModal_checkingRefund;

  /// No description provided for @trips_flightBookingCard_cancelModal_confirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel Booking'**
  String get trips_flightBookingCard_cancelModal_confirmCancel;

  /// No description provided for @trips_flightBookingCard_cancelModal_estimatedPenalty.
  ///
  /// In en, this message translates to:
  /// **'Estimated airline penalty: {amount}'**
  String trips_flightBookingCard_cancelModal_estimatedPenalty(Object amount);

  /// No description provided for @trips_flightBookingCard_cancelModal_fareRulesNonRefundable.
  ///
  /// In en, this message translates to:
  /// **'The fare rules indicate this ticket is non-refundable.'**
  String get trips_flightBookingCard_cancelModal_fareRulesNonRefundable;

  /// No description provided for @trips_flightBookingCard_cancelModal_keepBooking.
  ///
  /// In en, this message translates to:
  /// **'Keep Booking'**
  String get trips_flightBookingCard_cancelModal_keepBooking;

  /// No description provided for @trips_flightBookingCard_cancelModal_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get trips_flightBookingCard_cancelModal_loading;

  /// No description provided for @trips_flightBookingCard_cancelModal_networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error fetching cancellation quote.'**
  String get trips_flightBookingCard_cancelModal_networkError;

  /// No description provided for @trips_flightBookingCard_cancelModal_noQuote.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch cancellation quote from airline.'**
  String get trips_flightBookingCard_cancelModal_noQuote;

  /// No description provided for @trips_flightBookingCard_cancelModal_noRefund.
  ///
  /// In en, this message translates to:
  /// **'No refund — this fare is non-refundable per airline policy.'**
  String get trips_flightBookingCard_cancelModal_noRefund;

  /// No description provided for @trips_flightBookingCard_cancelModal_penaltiesDeducted.
  ///
  /// In en, this message translates to:
  /// **'Cancellation penalties set by the airline will be deducted.'**
  String get trips_flightBookingCard_cancelModal_penaltiesDeducted;

  /// No description provided for @trips_flightBookingCard_cancelModal_pnr.
  ///
  /// In en, this message translates to:
  /// **'PNR: {pnr}'**
  String trips_flightBookingCard_cancelModal_pnr(Object pnr);

  /// No description provided for @trips_flightBookingCard_cancelModal_refundEligibility.
  ///
  /// In en, this message translates to:
  /// **'Refund eligibility and amounts are strictly determined by the airline\'s fare rules.'**
  String get trips_flightBookingCard_cancelModal_refundEligibility;

  /// No description provided for @trips_flightBookingCard_cancelModal_refundPolicy.
  ///
  /// In en, this message translates to:
  /// **'Refund Policy:'**
  String get trips_flightBookingCard_cancelModal_refundPolicy;

  /// No description provided for @trips_flightBookingCard_cancelModal_refundTiming.
  ///
  /// In en, this message translates to:
  /// **'If a refund is issued, it typically takes 5–10 business days.'**
  String get trips_flightBookingCard_cancelModal_refundTiming;

  /// No description provided for @trips_flightBookingCard_cancelModal_taxesRefund.
  ///
  /// In en, this message translates to:
  /// **'Taxes & fees refund: {amount}'**
  String trips_flightBookingCard_cancelModal_taxesRefund(Object amount);

  /// No description provided for @trips_flightBookingCard_cancelModal_title.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking?'**
  String get trips_flightBookingCard_cancelModal_title;

  /// No description provided for @trips_flightBookingCard_cancelModal_willReceive.
  ///
  /// In en, this message translates to:
  /// **'You will receive {amount} back.'**
  String trips_flightBookingCard_cancelModal_willReceive(Object amount);

  /// No description provided for @trips_flightBookingCard_cancelModal_zeroRefund.
  ///
  /// In en, this message translates to:
  /// **'You will receive \$0 back if you cancel.'**
  String get trips_flightBookingCard_cancelModal_zeroRefund;

  /// No description provided for @trips_flightBookingCard_cancellationFailed.
  ///
  /// In en, this message translates to:
  /// **'Cancellation failed'**
  String get trips_flightBookingCard_cancellationFailed;

  /// No description provided for @trips_flightBookingCard_changeFlight.
  ///
  /// In en, this message translates to:
  /// **'Change flight'**
  String get trips_flightBookingCard_changeFlight;

  /// No description provided for @trips_flightBookingCard_couldNotLoadTripDetails.
  ///
  /// In en, this message translates to:
  /// **'Could not load trip details'**
  String get trips_flightBookingCard_couldNotLoadTripDetails;

  /// No description provided for @trips_flightBookingCard_departFrom.
  ///
  /// In en, this message translates to:
  /// **'Depart from'**
  String get trips_flightBookingCard_departFrom;

  /// No description provided for @trips_flightBookingCard_details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get trips_flightBookingCard_details;

  /// No description provided for @trips_flightBookingCard_eTicket.
  ///
  /// In en, this message translates to:
  /// **'E-TKT'**
  String get trips_flightBookingCard_eTicket;

  /// No description provided for @trips_flightBookingCard_fareBadges_changeable.
  ///
  /// In en, this message translates to:
  /// **'Changeable'**
  String get trips_flightBookingCard_fareBadges_changeable;

  /// No description provided for @trips_flightBookingCard_fareBadges_checkingFarePolicy.
  ///
  /// In en, this message translates to:
  /// **'Checking fare policy…'**
  String get trips_flightBookingCard_fareBadges_checkingFarePolicy;

  /// No description provided for @trips_flightBookingCard_fareBadges_fareRulesNonRefundable.
  ///
  /// In en, this message translates to:
  /// **'Fare rules: Non-refundable'**
  String get trips_flightBookingCard_fareBadges_fareRulesNonRefundable;

  /// No description provided for @trips_flightBookingCard_fareBadges_freeCancellation.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation'**
  String get trips_flightBookingCard_fareBadges_freeCancellation;

  /// No description provided for @trips_flightBookingCard_fareBadges_nonRefundable.
  ///
  /// In en, this message translates to:
  /// **'Non-refundable after 24 hours'**
  String get trips_flightBookingCard_fareBadges_nonRefundable;

  /// No description provided for @trips_flightBookingCard_fareBadges_refundable.
  ///
  /// In en, this message translates to:
  /// **'Refundable'**
  String get trips_flightBookingCard_fareBadges_refundable;

  /// No description provided for @trips_flightBookingCard_flight.
  ///
  /// In en, this message translates to:
  /// **'Flight'**
  String get trips_flightBookingCard_flight;

  /// No description provided for @trips_flightBookingCard_flightBooking.
  ///
  /// In en, this message translates to:
  /// **'Flight Booking'**
  String get trips_flightBookingCard_flightBooking;

  /// No description provided for @trips_flightBookingCard_flightItinerary.
  ///
  /// In en, this message translates to:
  /// **'Show flight itinerary'**
  String get trips_flightBookingCard_flightItinerary;

  /// No description provided for @trips_flightBookingCard_hideChangeFlight.
  ///
  /// In en, this message translates to:
  /// **'Hide change flight'**
  String get trips_flightBookingCard_hideChangeFlight;

  /// No description provided for @trips_flightBookingCard_hideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide details'**
  String get trips_flightBookingCard_hideDetails;

  /// No description provided for @trips_flightBookingCard_hideFlightItinerary.
  ///
  /// In en, this message translates to:
  /// **'Hide flight itinerary'**
  String get trips_flightBookingCard_hideFlightItinerary;

  /// No description provided for @trips_flightBookingCard_hideRefundQuote.
  ///
  /// In en, this message translates to:
  /// **'Hide refund quote'**
  String get trips_flightBookingCard_hideRefundQuote;

  /// No description provided for @trips_flightBookingCard_hideVoidQuote.
  ///
  /// In en, this message translates to:
  /// **'Hide void quote'**
  String get trips_flightBookingCard_hideVoidQuote;

  /// No description provided for @trips_flightBookingCard_issuedTickets.
  ///
  /// In en, this message translates to:
  /// **'Issued Tickets'**
  String get trips_flightBookingCard_issuedTickets;

  /// No description provided for @trips_flightBookingCard_layover.
  ///
  /// In en, this message translates to:
  /// **'{duration} layover in {airport}'**
  String trips_flightBookingCard_layover(Object duration, Object airport);

  /// No description provided for @trips_flightBookingCard_loadingTripDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading airline details…'**
  String get trips_flightBookingCard_loadingTripDetails;

  /// No description provided for @trips_flightBookingCard_networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again.'**
  String get trips_flightBookingCard_networkError;

  /// No description provided for @trips_flightBookingCard_noRefund.
  ///
  /// In en, this message translates to:
  /// **'No refund issued'**
  String get trips_flightBookingCard_noRefund;

  /// No description provided for @trips_flightBookingCard_nonstop.
  ///
  /// In en, this message translates to:
  /// **'Nonstop'**
  String get trips_flightBookingCard_nonstop;

  /// No description provided for @trips_flightBookingCard_noteAdded.
  ///
  /// In en, this message translates to:
  /// **'Note added successfully.'**
  String get trips_flightBookingCard_noteAdded;

  /// No description provided for @trips_flightBookingCard_notePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter a note for this booking…'**
  String get trips_flightBookingCard_notePlaceholder;

  /// No description provided for @trips_flightBookingCard_originTo.
  ///
  /// In en, this message translates to:
  /// **'{origin} to {destination}'**
  String trips_flightBookingCard_originTo(Object origin, Object destination);

  /// No description provided for @trips_flightBookingCard_passenger.
  ///
  /// In en, this message translates to:
  /// **'{count} passenger'**
  String trips_flightBookingCard_passenger(Object count);

  /// No description provided for @trips_flightBookingCard_passengers.
  ///
  /// In en, this message translates to:
  /// **'{count} passengers'**
  String trips_flightBookingCard_passengers(Object count);

  /// No description provided for @trips_flightBookingCard_pax.
  ///
  /// In en, this message translates to:
  /// **'{count} pax'**
  String trips_flightBookingCard_pax(Object count);

  /// No description provided for @trips_flightBookingCard_penaltyApplied.
  ///
  /// In en, this message translates to:
  /// **'Penalty applied: {amount}'**
  String trips_flightBookingCard_penaltyApplied(Object amount);

  /// No description provided for @trips_flightBookingCard_pnr.
  ///
  /// In en, this message translates to:
  /// **'PNR'**
  String get trips_flightBookingCard_pnr;

  /// No description provided for @trips_flightBookingCard_receipt.
  ///
  /// In en, this message translates to:
  /// **'Download receipt'**
  String get trips_flightBookingCard_receipt;

  /// No description provided for @trips_flightBookingCard_refundFailed.
  ///
  /// In en, this message translates to:
  /// **'Refund failed'**
  String get trips_flightBookingCard_refundFailed;

  /// No description provided for @trips_flightBookingCard_refundNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Refund not available'**
  String get trips_flightBookingCard_refundNotAvailable;

  /// No description provided for @trips_flightBookingCard_refundNotAvailablePolicy.
  ///
  /// In en, this message translates to:
  /// **'Refund not available (airline policy)'**
  String get trips_flightBookingCard_refundNotAvailablePolicy;

  /// No description provided for @trips_flightBookingCard_refundQuote.
  ///
  /// In en, this message translates to:
  /// **'Refund quote'**
  String get trips_flightBookingCard_refundQuote;

  /// No description provided for @trips_flightBookingCard_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get trips_flightBookingCard_retry;

  /// No description provided for @trips_flightBookingCard_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get trips_flightBookingCard_save;

  /// No description provided for @trips_flightBookingCard_seat.
  ///
  /// In en, this message translates to:
  /// **'SEAT'**
  String get trips_flightBookingCard_seat;

  /// No description provided for @trips_flightBookingCard_stateChips_awaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Confirmation'**
  String get trips_flightBookingCard_stateChips_awaitingConfirmation;

  /// No description provided for @trips_flightBookingCard_stateChips_booked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get trips_flightBookingCard_stateChips_booked;

  /// No description provided for @trips_flightBookingCard_stateChips_bookingFailed.
  ///
  /// In en, this message translates to:
  /// **'Booking failed'**
  String get trips_flightBookingCard_stateChips_bookingFailed;

  /// No description provided for @trips_flightBookingCard_stateChips_cancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Cancel failed — retry below'**
  String get trips_flightBookingCard_stateChips_cancelFailed;

  /// No description provided for @trips_flightBookingCard_stateChips_cancelStuck.
  ///
  /// In en, this message translates to:
  /// **'Cancellation stuck — retry below'**
  String get trips_flightBookingCard_stateChips_cancelStuck;

  /// No description provided for @trips_flightBookingCard_stateChips_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get trips_flightBookingCard_stateChips_cancelled;

  /// No description provided for @trips_flightBookingCard_stateChips_contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support to cancel'**
  String get trips_flightBookingCard_stateChips_contactSupport;

  /// No description provided for @trips_flightBookingCard_stateChips_emailToCancel.
  ///
  /// In en, this message translates to:
  /// **'Email crm@myfarebox.com to cancel'**
  String get trips_flightBookingCard_stateChips_emailToCancel;

  /// No description provided for @trips_flightBookingCard_stateChips_flightCompleted.
  ///
  /// In en, this message translates to:
  /// **'Flight completed'**
  String get trips_flightBookingCard_stateChips_flightCompleted;

  /// No description provided for @trips_flightBookingCard_stateChips_flightInProgress.
  ///
  /// In en, this message translates to:
  /// **'Flight in progress'**
  String get trips_flightBookingCard_stateChips_flightInProgress;

  /// No description provided for @trips_flightBookingCard_stateChips_processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get trips_flightBookingCard_stateChips_processing;

  /// No description provided for @trips_flightBookingCard_stateChips_refundFailed.
  ///
  /// In en, this message translates to:
  /// **'Refund Failed'**
  String get trips_flightBookingCard_stateChips_refundFailed;

  /// No description provided for @trips_flightBookingCard_stateChips_refundProcessing.
  ///
  /// In en, this message translates to:
  /// **'Refund processing'**
  String get trips_flightBookingCard_stateChips_refundProcessing;

  /// No description provided for @trips_flightBookingCard_stateChips_refunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get trips_flightBookingCard_stateChips_refunded;

  /// No description provided for @trips_flightBookingCard_stateChips_reissued.
  ///
  /// In en, this message translates to:
  /// **'Reissued'**
  String get trips_flightBookingCard_stateChips_reissued;

  /// No description provided for @trips_flightBookingCard_stateChips_supplierNotFound.
  ///
  /// In en, this message translates to:
  /// **'Supplier record not found'**
  String get trips_flightBookingCard_stateChips_supplierNotFound;

  /// No description provided for @trips_flightBookingCard_stateChips_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get trips_flightBookingCard_stateChips_unknown;

  /// No description provided for @trips_flightBookingCard_stateChips_upcomingFlight.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Flight'**
  String get trips_flightBookingCard_stateChips_upcomingFlight;

  /// No description provided for @trips_flightBookingCard_stop.
  ///
  /// In en, this message translates to:
  /// **'{count} stop'**
  String trips_flightBookingCard_stop(Object count);

  /// No description provided for @trips_flightBookingCard_stops.
  ///
  /// In en, this message translates to:
  /// **'{count} stops'**
  String trips_flightBookingCard_stops(Object count);

  /// No description provided for @trips_flightBookingCard_successBanners_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled successfully.'**
  String get trips_flightBookingCard_successBanners_cancelled;

  /// No description provided for @trips_flightBookingCard_successBanners_refundProcessed.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled. Refund has been processed.'**
  String get trips_flightBookingCard_successBanners_refundProcessed;

  /// No description provided for @trips_flightBookingCard_successBanners_refundProcessing.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled. Refund is being processed — check back shortly.'**
  String get trips_flightBookingCard_successBanners_refundProcessing;

  /// No description provided for @trips_flightBookingCard_totalFlightDuration.
  ///
  /// In en, this message translates to:
  /// **'Total Flight Duration'**
  String get trips_flightBookingCard_totalFlightDuration;

  /// No description provided for @trips_flightBookingCard_totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get trips_flightBookingCard_totalPaid;

  /// No description provided for @trips_flightBookingCard_totalRefund.
  ///
  /// In en, this message translates to:
  /// **'Total Refund'**
  String get trips_flightBookingCard_totalRefund;

  /// No description provided for @trips_flightBookingCard_tripLegs_leg.
  ///
  /// In en, this message translates to:
  /// **'Leg {number}'**
  String trips_flightBookingCard_tripLegs_leg(Object number);

  /// No description provided for @trips_flightBookingCard_tripLegs_outbound.
  ///
  /// In en, this message translates to:
  /// **'Outbound'**
  String get trips_flightBookingCard_tripLegs_outbound;

  /// No description provided for @trips_flightBookingCard_tripLegs_return.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get trips_flightBookingCard_tripLegs_return;

  /// No description provided for @trips_flightBookingCard_tripTypes_multiCity.
  ///
  /// In en, this message translates to:
  /// **'Multi-city'**
  String get trips_flightBookingCard_tripTypes_multiCity;

  /// No description provided for @trips_flightBookingCard_tripTypes_oneWay.
  ///
  /// In en, this message translates to:
  /// **'One-way'**
  String get trips_flightBookingCard_tripTypes_oneWay;

  /// No description provided for @trips_flightBookingCard_tripTypes_roundTrip.
  ///
  /// In en, this message translates to:
  /// **'Round-trip'**
  String get trips_flightBookingCard_tripTypes_roundTrip;

  /// No description provided for @trips_flightBookingCard_voidNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Void not available'**
  String get trips_flightBookingCard_voidNotAvailable;

  /// No description provided for @trips_flightBookingCard_voidNotAvailablePolicy.
  ///
  /// In en, this message translates to:
  /// **'Void not available (airline policy)'**
  String get trips_flightBookingCard_voidNotAvailablePolicy;

  /// No description provided for @trips_flightBookingCard_voidQuote.
  ///
  /// In en, this message translates to:
  /// **'Void quote'**
  String get trips_flightBookingCard_voidQuote;

  /// No description provided for @trips_golfCard_chargedOnConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Charged once the course confirms'**
  String get trips_golfCard_chargedOnConfirmation;

  /// No description provided for @trips_golfCard_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get trips_golfCard_date;

  /// No description provided for @trips_golfCard_empty.
  ///
  /// In en, this message translates to:
  /// **'No golf bookings yet'**
  String get trips_golfCard_empty;

  /// No description provided for @trips_golfCard_notCharged.
  ///
  /// In en, this message translates to:
  /// **'Not charged'**
  String get trips_golfCard_notCharged;

  /// No description provided for @trips_golfCard_refunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded {amount}'**
  String trips_golfCard_refunded(Object amount);

  /// No description provided for @trips_golfCard_status_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get trips_golfCard_status_cancelled;

  /// No description provided for @trips_golfCard_status_confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get trips_golfCard_status_confirmed;

  /// No description provided for @trips_golfCard_status_declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get trips_golfCard_status_declined;

  /// No description provided for @trips_golfCard_status_expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get trips_golfCard_status_expired;

  /// No description provided for @trips_golfCard_status_held.
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment'**
  String get trips_golfCard_status_held;

  /// No description provided for @trips_golfCard_status_requested.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the course'**
  String get trips_golfCard_status_requested;

  /// No description provided for @trips_golfCard_teeTime.
  ///
  /// In en, this message translates to:
  /// **'Tee time'**
  String get trips_golfCard_teeTime;

  /// No description provided for @trips_golfCard_totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total paid'**
  String get trips_golfCard_totalPaid;

  /// No description provided for @trips_golfCard_view.
  ///
  /// In en, this message translates to:
  /// **'View booking'**
  String get trips_golfCard_view;

  /// No description provided for @trips_hotelCancel_alreadyCancelled.
  ///
  /// In en, this message translates to:
  /// **'This booking has already been cancelled.'**
  String get trips_hotelCancel_alreadyCancelled;

  /// No description provided for @trips_hotelCancel_changedBody.
  ///
  /// In en, this message translates to:
  /// **'Time has passed since you opened this, and what you\'d get back is different. Nothing has been cancelled. Please look again.'**
  String get trips_hotelCancel_changedBody;

  /// No description provided for @trips_hotelCancel_changedTitle.
  ///
  /// In en, this message translates to:
  /// **'The amount has changed'**
  String get trips_hotelCancel_changedTitle;

  /// No description provided for @trips_hotelCancel_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get trips_hotelCancel_close;

  /// No description provided for @trips_hotelCancel_confirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get trips_hotelCancel_confirm;

  /// No description provided for @trips_hotelCancel_confirmNoRefund.
  ///
  /// In en, this message translates to:
  /// **'Cancel anyway — no refund'**
  String get trips_hotelCancel_confirmNoRefund;

  /// No description provided for @trips_hotelCancel_confirmRefund.
  ///
  /// In en, this message translates to:
  /// **'Cancel and get {amount} back'**
  String trips_hotelCancel_confirmRefund(Object amount);

  /// No description provided for @trips_hotelCancel_doneNoRefund.
  ///
  /// In en, this message translates to:
  /// **'Your booking is cancelled. Nothing was refunded, as the rate was non-refundable.'**
  String get trips_hotelCancel_doneNoRefund;

  /// No description provided for @trips_hotelCancel_doneRefundFailed.
  ///
  /// In en, this message translates to:
  /// **'Your booking is cancelled, but the refund didn\'t go through. Contact support and we\'ll sort it out.'**
  String get trips_hotelCancel_doneRefundFailed;

  /// No description provided for @trips_hotelCancel_doneRefunded.
  ///
  /// In en, this message translates to:
  /// **'Your booking is cancelled and your refund is on its way. It can take 3–5 business days to appear on your statement.'**
  String get trips_hotelCancel_doneRefunded;

  /// No description provided for @trips_hotelCancel_failed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t cancel this booking. Please try again, or contact support.'**
  String get trips_hotelCancel_failed;

  /// No description provided for @trips_hotelCancel_feeRisesOn.
  ///
  /// In en, this message translates to:
  /// **'The fee goes up on {date}'**
  String trips_hotelCancel_feeRisesOn(Object date);

  /// No description provided for @trips_hotelCancel_freeUntil.
  ///
  /// In en, this message translates to:
  /// **'Free to cancel until {date}'**
  String trips_hotelCancel_freeUntil(Object date);

  /// No description provided for @trips_hotelCancel_fullRefund.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be refunded in full.'**
  String get trips_hotelCancel_fullRefund;

  /// No description provided for @trips_hotelCancel_keep.
  ///
  /// In en, this message translates to:
  /// **'Keep my booking'**
  String get trips_hotelCancel_keep;

  /// No description provided for @trips_hotelCancel_loadError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t check the cancellation terms. Please try again.'**
  String get trips_hotelCancel_loadError;

  /// No description provided for @trips_hotelCancel_loading.
  ///
  /// In en, this message translates to:
  /// **'Checking what you\'d get back…'**
  String get trips_hotelCancel_loading;

  /// No description provided for @trips_hotelCancel_noRefund.
  ///
  /// In en, this message translates to:
  /// **'You won\'t get anything back — this rate isn\'t refundable at this point.'**
  String get trips_hotelCancel_noRefund;

  /// No description provided for @trips_hotelCancel_notCancellable.
  ///
  /// In en, this message translates to:
  /// **'This booking can\'t be cancelled here. Please contact support.'**
  String get trips_hotelCancel_notCancellable;

  /// No description provided for @trips_hotelCancel_paid.
  ///
  /// In en, this message translates to:
  /// **'You paid'**
  String get trips_hotelCancel_paid;

  /// No description provided for @trips_hotelCancel_partialRefund.
  ///
  /// In en, this message translates to:
  /// **'You\'ll get part of your payment back.'**
  String get trips_hotelCancel_partialRefund;

  /// No description provided for @trips_hotelCancel_penalty.
  ///
  /// In en, this message translates to:
  /// **'Cancellation fee'**
  String get trips_hotelCancel_penalty;

  /// No description provided for @trips_hotelCancel_refund.
  ///
  /// In en, this message translates to:
  /// **'You\'ll get back'**
  String get trips_hotelCancel_refund;

  /// No description provided for @trips_hotelCancel_refundRetry.
  ///
  /// In en, this message translates to:
  /// **'This booking is already cancelled, but the refund didn\'t go through. We\'ll try it again now.'**
  String get trips_hotelCancel_refundRetry;

  /// No description provided for @trips_hotelCancel_title.
  ///
  /// In en, this message translates to:
  /// **'Cancel this booking?'**
  String get trips_hotelCancel_title;

  /// No description provided for @trips_hotelCancel_working.
  ///
  /// In en, this message translates to:
  /// **'Cancelling…'**
  String get trips_hotelCancel_working;

  /// No description provided for @trips_hotelConfirmed_confirming.
  ///
  /// In en, this message translates to:
  /// **'Confirming your booking…'**
  String get trips_hotelConfirmed_confirming;

  /// No description provided for @trips_hotelConfirmed_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading your booking…'**
  String get trips_hotelConfirmed_loading;

  /// No description provided for @trips_invoice_downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get trips_invoice_downloadPdf;

  /// No description provided for @trips_invoice_generating.
  ///
  /// In en, this message translates to:
  /// **'Generating…'**
  String get trips_invoice_generating;

  /// No description provided for @trips_invoice_loadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load invoice'**
  String get trips_invoice_loadError;

  /// No description provided for @trips_invoice_pdfError.
  ///
  /// In en, this message translates to:
  /// **'Could not build the PDF. You can still print this page.'**
  String get trips_invoice_pdfError;

  /// No description provided for @trips_invoice_print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get trips_invoice_print;

  /// No description provided for @trips_labels_afterDatePenalty.
  ///
  /// In en, this message translates to:
  /// **'After {date}: penalty of {amount}'**
  String trips_labels_afterDatePenalty(Object date, Object amount);

  /// No description provided for @trips_labels_bookedOn.
  ///
  /// In en, this message translates to:
  /// **'Booked On'**
  String get trips_labels_bookedOn;

  /// No description provided for @trips_labels_checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get trips_labels_checkIn;

  /// No description provided for @trips_labels_checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get trips_labels_checkOut;

  /// No description provided for @trips_labels_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get trips_labels_duration;

  /// No description provided for @trips_labels_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get trips_labels_email;

  /// No description provided for @trips_labels_freeCancelUntil.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation until'**
  String get trips_labels_freeCancelUntil;

  /// No description provided for @trips_labels_freeCancellation.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation available'**
  String get trips_labels_freeCancellation;

  /// No description provided for @trips_labels_guests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get trips_labels_guests;

  /// No description provided for @trips_labels_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get trips_labels_name;

  /// No description provided for @trips_labels_nonRefundable.
  ///
  /// In en, this message translates to:
  /// **'Non-refundable'**
  String get trips_labels_nonRefundable;

  /// No description provided for @trips_labels_paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get trips_labels_paymentMethod;

  /// No description provided for @trips_labels_policyNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policy details not available.'**
  String get trips_labels_policyNotAvailable;

  /// No description provided for @trips_labels_provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get trips_labels_provider;

  /// No description provided for @trips_labels_room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get trips_labels_room;

  /// No description provided for @trips_labels_specialRequests.
  ///
  /// In en, this message translates to:
  /// **'Special Requests'**
  String get trips_labels_specialRequests;

  /// No description provided for @trips_labels_totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get trips_labels_totalPaid;

  /// No description provided for @trips_loadFailed_retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get trips_loadFailed_retry;

  /// No description provided for @trips_loadFailed_title.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your trips'**
  String get trips_loadFailed_title;

  /// No description provided for @trips_modificationModal_discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get trips_modificationModal_discard;

  /// No description provided for @trips_modificationModal_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get trips_modificationModal_email;

  /// No description provided for @trips_modificationModal_emailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'email@example.com'**
  String get trips_modificationModal_emailPlaceholder;

  /// No description provided for @trips_modificationModal_firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get trips_modificationModal_firstName;

  /// No description provided for @trips_modificationModal_firstNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get trips_modificationModal_firstNamePlaceholder;

  /// No description provided for @trips_modificationModal_infoBanner.
  ///
  /// In en, this message translates to:
  /// **'You can update the booking holder\'s name, email, and special requests.'**
  String get trips_modificationModal_infoBanner;

  /// No description provided for @trips_modificationModal_lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get trips_modificationModal_lastName;

  /// No description provided for @trips_modificationModal_lastNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get trips_modificationModal_lastNamePlaceholder;

  /// No description provided for @trips_modificationModal_optional.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get trips_modificationModal_optional;

  /// No description provided for @trips_modificationModal_remarksPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g., Late check-in, extra pillows...'**
  String get trips_modificationModal_remarksPlaceholder;

  /// No description provided for @trips_modificationModal_saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get trips_modificationModal_saveChanges;

  /// No description provided for @trips_modificationModal_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get trips_modificationModal_saving;

  /// No description provided for @trips_modificationModal_specialRequests.
  ///
  /// In en, this message translates to:
  /// **'Special Requests'**
  String get trips_modificationModal_specialRequests;

  /// No description provided for @trips_modificationModal_title.
  ///
  /// In en, this message translates to:
  /// **'Modify Booking'**
  String get trips_modificationModal_title;

  /// No description provided for @trips_myTrips.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get trips_myTrips;

  /// No description provided for @trips_noSegmentDetails.
  ///
  /// In en, this message translates to:
  /// **'No segment details available.'**
  String get trips_noSegmentDetails;

  /// No description provided for @trips_pageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and manage all your bookings.'**
  String get trips_pageSubtitle;

  /// No description provided for @trips_pages_backToBooking.
  ///
  /// In en, this message translates to:
  /// **'Back to booking'**
  String get trips_pages_backToBooking;

  /// No description provided for @trips_pages_ref.
  ///
  /// In en, this message translates to:
  /// **'Ref:'**
  String get trips_pages_ref;

  /// No description provided for @trips_pnr.
  ///
  /// In en, this message translates to:
  /// **'PNR:'**
  String get trips_pnr;

  /// No description provided for @trips_refund_full.
  ///
  /// In en, this message translates to:
  /// **'Full Refund'**
  String get trips_refund_full;

  /// No description provided for @trips_refund_nonRefundable.
  ///
  /// In en, this message translates to:
  /// **'Non-Refundable'**
  String get trips_refund_nonRefundable;

  /// No description provided for @trips_refund_paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get trips_refund_paid;

  /// No description provided for @trips_refund_penalty.
  ///
  /// In en, this message translates to:
  /// **'Penalty'**
  String get trips_refund_penalty;

  /// No description provided for @trips_refund_refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get trips_refund_refund;

  /// No description provided for @trips_refund_summary.
  ///
  /// In en, this message translates to:
  /// **'Refund Summary'**
  String get trips_refund_summary;

  /// No description provided for @trips_requestsForm_label.
  ///
  /// In en, this message translates to:
  /// **'Message to the property'**
  String get trips_requestsForm_label;

  /// No description provided for @trips_requestsForm_placeholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Late check-in after 10 PM, extra bed, high floor…'**
  String get trips_requestsForm_placeholder;

  /// No description provided for @trips_requestsForm_saveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save your request. Please try again.'**
  String get trips_requestsForm_saveError;

  /// No description provided for @trips_requestsForm_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved — the property has been notified.'**
  String get trips_requestsForm_saved;

  /// No description provided for @trips_requestsForm_submit.
  ///
  /// In en, this message translates to:
  /// **'Save request'**
  String get trips_requestsForm_submit;

  /// No description provided for @trips_requestsForm_title.
  ///
  /// In en, this message translates to:
  /// **'Special requests'**
  String get trips_requestsForm_title;

  /// No description provided for @trips_requestsPage_cancelled.
  ///
  /// In en, this message translates to:
  /// **'This booking is cancelled, so special requests can no longer be updated.'**
  String get trips_requestsPage_cancelled;

  /// No description provided for @trips_requestsPage_note.
  ///
  /// In en, this message translates to:
  /// **'Requests are passed to the property but aren\'t guaranteed — availability depends on the hotel.'**
  String get trips_requestsPage_note;

  /// No description provided for @trips_requestsPage_title.
  ///
  /// In en, this message translates to:
  /// **'Special requests'**
  String get trips_requestsPage_title;

  /// No description provided for @trips_sections_cancellationPolicy.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Policy'**
  String get trips_sections_cancellationPolicy;

  /// No description provided for @trips_sections_guestInformation.
  ///
  /// In en, this message translates to:
  /// **'Guest Information'**
  String get trips_sections_guestInformation;

  /// No description provided for @trips_sections_itinerary.
  ///
  /// In en, this message translates to:
  /// **'Itinerary'**
  String get trips_sections_itinerary;

  /// No description provided for @trips_sections_passengers.
  ///
  /// In en, this message translates to:
  /// **'Passengers'**
  String get trips_sections_passengers;

  /// No description provided for @trips_sections_payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get trips_sections_payment;

  /// No description provided for @trips_sections_stayDetails.
  ///
  /// In en, this message translates to:
  /// **'Stay Details'**
  String get trips_sections_stayDetails;

  /// No description provided for @trips_shareForm_blurb.
  ///
  /// In en, this message translates to:
  /// **'Send the confirmation to whoever is travelling with you.'**
  String get trips_shareForm_blurb;

  /// No description provided for @trips_shareForm_sendError.
  ///
  /// In en, this message translates to:
  /// **'Failed to send. Please try again.'**
  String get trips_shareForm_sendError;

  /// No description provided for @trips_shareForm_sendTo.
  ///
  /// In en, this message translates to:
  /// **'Send to'**
  String get trips_shareForm_sendTo;

  /// No description provided for @trips_shareForm_sent.
  ///
  /// In en, this message translates to:
  /// **'Sent to {email}'**
  String trips_shareForm_sent(Object email);

  /// No description provided for @trips_shareForm_sentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent to {email}.'**
  String trips_shareForm_sentTo(Object email);

  /// No description provided for @trips_shareForm_submit.
  ///
  /// In en, this message translates to:
  /// **'Send confirmation'**
  String get trips_shareForm_submit;

  /// No description provided for @trips_shareForm_title.
  ///
  /// In en, this message translates to:
  /// **'Share this booking'**
  String get trips_shareForm_title;

  /// No description provided for @trips_sharePage_note.
  ///
  /// In en, this message translates to:
  /// **'Resend the confirmation email to yourself or anyone else — useful for a travel companion or your own records.'**
  String get trips_sharePage_note;

  /// No description provided for @trips_sharePage_title.
  ///
  /// In en, this message translates to:
  /// **'Share booking confirmation'**
  String get trips_sharePage_title;

  /// No description provided for @trips_status_booked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get trips_status_booked;

  /// No description provided for @trips_status_cancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Cancel Failed'**
  String get trips_status_cancelFailed;

  /// No description provided for @trips_status_cancelPending.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Pending'**
  String get trips_status_cancelPending;

  /// No description provided for @trips_status_cancellationStuck.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Stuck'**
  String get trips_status_cancellationStuck;

  /// No description provided for @trips_status_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get trips_status_cancelled;

  /// No description provided for @trips_status_cancelledProviderMissing.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get trips_status_cancelledProviderMissing;

  /// No description provided for @trips_status_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get trips_status_completed;

  /// No description provided for @trips_status_confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get trips_status_confirmed;

  /// No description provided for @trips_status_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get trips_status_failed;

  /// No description provided for @trips_status_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get trips_status_pending;

  /// No description provided for @trips_status_processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get trips_status_processing;

  /// No description provided for @trips_status_refundFailed.
  ///
  /// In en, this message translates to:
  /// **'Refund Failed'**
  String get trips_status_refundFailed;

  /// No description provided for @trips_status_refundPending.
  ///
  /// In en, this message translates to:
  /// **'Refund Pending'**
  String get trips_status_refundPending;

  /// No description provided for @trips_status_refunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get trips_status_refunded;

  /// No description provided for @trips_status_ticketed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get trips_status_ticketed;

  /// No description provided for @trips_status_ticketing.
  ///
  /// In en, this message translates to:
  /// **'Ticketing'**
  String get trips_status_ticketing;

  /// No description provided for @trips_status_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get trips_status_unknown;

  /// No description provided for @trips_subtitle.
  ///
  /// In en, this message translates to:
  /// **'View and manage your bookings'**
  String get trips_subtitle;

  /// No description provided for @trips_tabs_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get trips_tabs_all;

  /// No description provided for @trips_tabs_past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get trips_tabs_past;

  /// No description provided for @trips_tabs_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get trips_tabs_upcoming;

  /// No description provided for @trips_tabs_wishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get trips_tabs_wishlist;

  /// No description provided for @trips_title.
  ///
  /// In en, this message translates to:
  /// **'My Trips | CheapestGo'**
  String get trips_title;

  /// No description provided for @trips_tripMap_away.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String trips_tripMap_away(Object distance);

  /// No description provided for @trips_tripMap_calculatingDistance.
  ///
  /// In en, this message translates to:
  /// **'Calculating distance…'**
  String get trips_tripMap_calculatingDistance;

  /// No description provided for @trips_tripMap_centerOnHotel.
  ///
  /// In en, this message translates to:
  /// **'Center on hotel'**
  String get trips_tripMap_centerOnHotel;

  /// No description provided for @trips_tripMap_close.
  ///
  /// In en, this message translates to:
  /// **'Close map'**
  String get trips_tripMap_close;

  /// No description provided for @trips_tripMap_determiningLocation.
  ///
  /// In en, this message translates to:
  /// **'Determining your location…'**
  String get trips_tripMap_determiningLocation;

  /// No description provided for @trips_tripMap_driving.
  ///
  /// In en, this message translates to:
  /// **'Driving'**
  String get trips_tripMap_driving;

  /// No description provided for @trips_tripMap_findingHotel.
  ///
  /// In en, this message translates to:
  /// **'Finding hotel…'**
  String get trips_tripMap_findingHotel;

  /// No description provided for @trips_tripMap_flyingIn.
  ///
  /// In en, this message translates to:
  /// **'Flying in'**
  String get trips_tripMap_flyingIn;

  /// No description provided for @trips_tripMap_gettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting your location…'**
  String get trips_tripMap_gettingLocation;

  /// No description provided for @trips_tripMap_locating.
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get trips_tripMap_locating;

  /// No description provided for @trips_tripMap_navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get trips_tripMap_navigate;

  /// No description provided for @trips_tripMap_navigationReady.
  ///
  /// In en, this message translates to:
  /// **'Navigation ready when you land nearby'**
  String get trips_tripMap_navigationReady;

  /// No description provided for @trips_tripMap_navigationStarts.
  ///
  /// In en, this message translates to:
  /// **'Navigation starts when you\'re within 50 km'**
  String get trips_tripMap_navigationStarts;

  /// No description provided for @trips_tripMap_openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get trips_tripMap_openInMaps;

  /// No description provided for @trips_tripMap_saveInMaps.
  ///
  /// In en, this message translates to:
  /// **'Save in Maps'**
  String get trips_tripMap_saveInMaps;

  /// No description provided for @trips_tripMap_toggleTraffic.
  ///
  /// In en, this message translates to:
  /// **'Toggle traffic'**
  String get trips_tripMap_toggleTraffic;

  /// No description provided for @trips_tripMap_tooFar.
  ///
  /// In en, this message translates to:
  /// **'Too far to drive directly'**
  String get trips_tripMap_tooFar;

  /// No description provided for @trips_tripMap_walking.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get trips_tripMap_walking;

  /// No description provided for @trips_v2_backToMyTrips.
  ///
  /// In en, this message translates to:
  /// **'Back to My Bookings'**
  String get trips_v2_backToMyTrips;

  /// No description provided for @trips_v2_downloadETicket.
  ///
  /// In en, this message translates to:
  /// **'Download E-Ticket'**
  String get trips_v2_downloadETicket;

  /// No description provided for @trips_v2_refundNotice.
  ///
  /// In en, this message translates to:
  /// **'Refund eligibility is subject to airline fare rules.'**
  String get trips_v2_refundNotice;

  /// No description provided for @trips_viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get trips_viewDetails;

  /// No description provided for @trips_viewMore.
  ///
  /// In en, this message translates to:
  /// **'View more ({count} remaining)'**
  String trips_viewMore(Object count);

  /// No description provided for @trips_viewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View Receipt'**
  String get trips_viewReceipt;

  /// No description provided for @trips_wishlist_emptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart icon on any flight or hotel to save it here.'**
  String get trips_wishlist_emptyDesc;

  /// No description provided for @trips_wishlist_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved trips yet'**
  String get trips_wishlist_emptyTitle;

  /// No description provided for @trips_wishlist_perPerson.
  ///
  /// In en, this message translates to:
  /// **'per person'**
  String get trips_wishlist_perPerson;

  /// No description provided for @trips_wishlist_removeError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove that item. Please try again.'**
  String get trips_wishlist_removeError;

  /// No description provided for @trips_wishlist_removeFromWishlist.
  ///
  /// In en, this message translates to:
  /// **'Remove from wishlist'**
  String get trips_wishlist_removeFromWishlist;

  /// No description provided for @trips_wishlist_saveToWishlist.
  ///
  /// In en, this message translates to:
  /// **'Save to wishlist'**
  String get trips_wishlist_saveToWishlist;

  /// No description provided for @trips_wishlist_savedOn.
  ///
  /// In en, this message translates to:
  /// **'Saved {date}'**
  String trips_wishlist_savedOn(Object date);

  /// No description provided for @trips_wishlist_searchAgain.
  ///
  /// In en, this message translates to:
  /// **'Search again'**
  String get trips_wishlist_searchAgain;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
