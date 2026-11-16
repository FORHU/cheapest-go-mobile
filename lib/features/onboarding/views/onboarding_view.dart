import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/components/auth_form_widgets.dart';
import 'package:cheapest_go_mobile/features/onboarding/api/onboarding_api.dart';
import 'package:cheapest_go_mobile/features/onboarding/stores/onboarding_store.dart';
import 'package:cheapest_go_mobile/shared/lib/countries.dart';
import 'package:cheapest_go_mobile/shared/stores/ui_store.dart';

/// The setup a newly created account completes before reaching the app. See #62, ADR-0005.
///
/// Two steps, and they are not the same kind of thing. **Preferences** are mandatory: three
/// taps with working defaults that cost a traveller nothing and that the app needs in order to
/// show prices in a currency they read. **Traveller Details** are skippable: demanding a phone
/// number from somebody who has not booked anything is where an install is uninstalled.
///
/// Nothing here is explanatory. Every step stores an answer, which is why it is Onboarding and
/// not a welcome carousel — see CONTEXT.md.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  static const int _stepCount = 2;

  final _detailsFormKey = GlobalKey<FormState>();
  final _birthDate = TextEditingController();
  final _phone = TextEditingController();
  final _nationality = TextEditingController();

  /// What the field shows: the country's name. [_nationality] holds the code that is stored.
  final _nationalityLabel = TextEditingController();

  int _step = 0;
  String _currency = uiSettingsStore.displayCurrency;
  String _language = uiSettingsStore.language;
  bool _emailNotifications = true;
  bool _busy = false;
  String? _failure;

  @override
  void dispose() {
    _birthDate.dispose();
    _phone.dispose();
    _nationality.dispose();
    _nationalityLabel.dispose();
    super.dispose();
  }

  /// Back a step inside the flow; at step one there is nowhere left to go but out of the app.
  ///
  /// Returning false lets the system handle it, which closes the app. Deliberate: the gesture
  /// never becomes a no-op (**Platform Obligation**, CONTEXT.md), and nothing is lost by
  /// leaving — the account exists and the flow resumes on the next launch.
  Future<bool> _onBack() async {
    if (_step == 0) return false;
    setState(() => _step -= 1);
    return true;
  }

  Future<void> _finish({required bool withDetails}) async {
    if (withDetails && !(_detailsFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _failure = null;
    });

    final t = AppLocalizations.of(context)!;
    try {
      // Details first: if this fails the traveller is still in the flow and can correct it.
      // Marking onboarding complete first and then failing here would let them into the app
      // with the step half-answered and no way back to it.
      if (withDetails) {
        await onboardingApi.saveDetails(
          birthDate: _birthDate.text.trim(),
          phone: _phone.text.trim(),
          nationality: _nationality.text.trim(),
        );
      }

      final done = await onboardingStore.complete({
        'displayCurrency': _currency,
        'language': _language,
        'emailNotifications': _emailNotifications,
      });

      if (!mounted) return;
      if (!done) {
        setState(() {
          _busy = false;
          _failure = t.onboarding_saveFailed;
        });
        return;
      }

      // Applied locally only once the server has it, so the app never renders a preference
      // the account does not actually hold.
      await uiSettingsStore.setDisplayCurrency(_currency);
      await uiSettingsStore.setLanguage(_language);

      // The gate re-reads the store and lets them through; this takes them to the app.
      if (mounted) context.go('/');
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = t.onboarding_saveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!await _onBack()) {
          // Nowhere further back inside the flow: let the app close, as back does on any
          // root screen.
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(t.onboarding_title),
          leading: _step == 0
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _busy ? null : () => setState(() => _step -= 1),
                ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _Progress(step: _step, total: _stepCount, label: t.onboarding_step(_step + 1, _stepCount)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _step == 0 ? _buildPreferences(t) : _buildDetails(t),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferences(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeader(title: t.onboarding_preferences_title, subtitle: t.onboarding_preferences_subtitle),
        const SizedBox(height: 24),
        if (_failure != null) ...[
          AuthErrorBanner(message: _failure!),
          const SizedBox(height: 16),
        ],
        _FieldLabel(t.account_preferences_displayCurrency),
        _ChoiceRow(
          // V2's own list, from its CurrencySelector.
          options: const {'USD': r'$ USD', 'KRW': '₩ KRW', 'PHP': '₱ PHP', 'JPY': '¥ JPY', 'CNY': '¥ CNY'},
          value: _currency,
          enabled: !_busy,
          onChanged: (v) => setState(() => _currency = v),
        ),
        const SizedBox(height: 20),
        _FieldLabel(t.account_preferences_language),
        _ChoiceRow(
          options: const {'en': 'English', 'ja': '日本語', 'ko': '한국어', 'zh': '中文'},
          value: _language,
          enabled: !_busy,
          onChanged: (v) => setState(() => _language = v),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _emailNotifications,
          onChanged: _busy ? null : (v) => setState(() => _emailNotifications = v),
          title: Text(t.account_preferences_emailNotifications),
          subtitle: Text(
            t.account_preferences_emailNotificationsHint,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 24),
        AuthSubmitButton(
          label: t.onboarding_continue,
          isLoading: false,
          onPressed: _busy ? () {} : () => setState(() => _step = 1),
        ),
      ],
    );
  }

  Widget _buildDetails(AppLocalizations t) {
    return Form(
      key: _detailsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(title: t.onboarding_details_title, subtitle: t.onboarding_details_subtitle),
          const SizedBox(height: 24),
          if (_failure != null) ...[
            AuthErrorBanner(message: _failure!),
            const SizedBox(height: 16),
          ],
          // A calendar, not a keyboard. Nobody should have to be told the format, and a date
          // that cannot be typed cannot be typed wrongly — the validator below stays as the
          // backstop for a value that arrives any other way.
          AuthTextField(
            controller: _birthDate,
            label: t.onboarding_birthDate,
            icon: Icons.cake_outlined,
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
            readOnly: true,
            onTap: _pickBirthDate,
            validator: (v) => _optional(v, _validateBirthDate, t),
            enabled: !_busy,
          ),
          const SizedBox(height: 16),
          // Nationality before phone, deliberately: choosing it fills the dialling prefix in
          // below, and a field that answers itself should come after the one that answers it.
          //
          // Chosen from the list, not typed. The stored value is the two-letter code every
          // supplier wants; what a traveller reads is the country's name, because almost
          // nobody knows their own ISO code and the ones who guess get it wrong.
          AuthTextField(
            controller: _nationalityLabel,
            label: t.onboarding_nationality,
            icon: Icons.flag_outlined,
            suffixIcon: const Icon(Icons.arrow_drop_down),
            readOnly: true,
            onTap: _pickNationality,
            // Checked against the stored code, not against what the field shows: the field
            // shows "Philippines" and what gets saved is "PH".
            validator: (_) => _optional(_nationality.text, _validateNationality, t),
            enabled: !_busy,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _phone,
            label: t.onboarding_phone,
            hintText: '+639171234567',
            keyboardType: TextInputType.phone,
            icon: Icons.phone_outlined,
            validator: (v) => _optional(v, _validatePhone, t),
            enabled: !_busy,
          ),
          const SizedBox(height: 24),
          AuthSubmitButton(
            label: t.onboarding_finish,
            isLoading: _busy,
            onPressed: () => _finish(withDetails: true),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : () => _finish(withDetails: false),
            child: Text(t.onboarding_skip),
          ),
        ],
      ),
    );
  }

  /// The calendar, opened at a year somebody is plausibly born in rather than at today.
  ///
  /// Scrolling back from this year to 1995 is the difference between a date picker and a
  /// chore, so it starts at thirty years ago and refuses anything outside the range api-v2
  /// would reject anyway.
  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final current = DateTime.tryParse('${_birthDate.text}T00:00:00Z');

    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendar,
      helpText: AppLocalizations.of(context)!.onboarding_birthDate,
    );

    if (picked == null) return;
    setState(() {
      // The format api-v2 stores, built by hand rather than through a locale-aware formatter:
      // this string is a key, not something anybody reads.
      _birthDate.text = '${picked.year.toString().padLeft(4, '0')}'
          '-${picked.month.toString().padLeft(2, '0')}'
          '-${picked.day.toString().padLeft(2, '0')}';
    });
  }

  /// The country list, searchable, because two hundred and forty-nine of them in a plain
  /// dropdown is a scroll nobody finishes.
  Future<void> _pickNationality() async {
    final picked = await showModalBottomSheet<MapEntry<String, String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _CountryPicker(),
    );

    if (picked == null) return;

    final previous = callingCode(_nationality.text);
    final next = callingCode(picked.key);

    setState(() {
      _nationality.text = picked.key;
      _nationalityLabel.text = picked.value;

      // The prefix is offered, never imposed. It fills an empty field, and it replaces a
      // field holding nothing but the last country's prefix — which is somebody correcting
      // the country, not somebody who typed a number. A number already entered is left
      // alone: a traveller may well hold a Philippine passport and a Japanese mobile.
      final current = _phone.text.trim();
      if (next.isNotEmpty && (current.isEmpty || current == previous)) {
        _phone.text = next;
        // The caret goes after the prefix, so typing continues the number rather than
        // landing in front of the plus.
        _phone.selection = TextSelection.collapsed(offset: _phone.text.length);
      }
    });
  }

  /// Every field on this step may be left blank, and is checked only once something is typed.
  /// A half-typed birth date should still be refused rather than sent — the step being
  /// skippable is not a reason to store nonsense.
  String? _optional(String? value, String? Function(String, AppLocalizations) check, AppLocalizations t) {
    final v = (value ?? '').trim();
    return v.isEmpty ? null : check(v, t);
  }

  // The same rules api-v2 enforces in `lib/users/travellerDetails.ts`. Checked here as well so
  // the answer comes back as a message under the field rather than as a failed request.
  String? _validateBirthDate(String v, AppLocalizations t) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) return t.onboarding_birthDateFormat;
    final parsed = DateTime.tryParse('${v}T00:00:00Z');
    if (parsed == null || parsed.toUtc().toIso8601String().substring(0, 10) != v) {
      return t.onboarding_birthDateReal;
    }
    if (v.compareTo(DateTime.now().toUtc().toIso8601String().substring(0, 10)) > 0) {
      return t.onboarding_birthDateFuture;
    }
    return null;
  }

  String? _validatePhone(String v, AppLocalizations t) {
    final cleaned = v.replaceAll(RegExp(r'[\s\-().]'), '');
    return RegExp(r'^\+\d{7,15}$').hasMatch(cleaned) ? null : t.onboarding_phoneFormat;
  }

  String? _validateNationality(String v, AppLocalizations t) {
    return RegExp(r'^[A-Za-z]{2}$').hasMatch(v) ? null : t.onboarding_nationalityFormat;
  }
}

/// How far through, stated as a bar and in words.
///
/// Both, because the bar alone says "some of the way" and a traveller who cannot leave wants
/// to know how much is left.
class _Progress extends StatelessWidget {
  const _Progress({required this.step, required this.total, required this.label});

  final int step;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (step + 1) / total,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

/// A row of chips, one chosen. Wraps rather than scrolls, so nothing is hidden off-screen on a
/// step somebody cannot skip.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.options,
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final Map<String, String> options;
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in options.entries)
          ChoiceChip(
            label: Text(entry.value),
            selected: entry.key == value,
            onSelected: enabled ? (_) => onChanged(entry.key) : null,
          ),
      ],
    );
  }
}

/// The country list, with a search box. See #62.
///
/// A sheet rather than a dropdown menu: a dropdown of two hundred and forty-nine countries
/// opens a list nobody scrolls to the end of, and the one thing a traveller always knows is
/// how their own country is spelled.
class _CountryPicker extends StatefulWidget {
  const _CountryPicker();

  @override
  State<_CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<_CountryPicker> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final matches = searchCountries(_query.text);

    return Padding(
      // Lifted above the keyboard, which covers the bottom half of the list once the search
      // box has focus — and the search box is the first thing anybody touches here.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _query,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: t.onboarding_nationality,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Expanded(
              child: matches.isEmpty
                  ? Center(child: Text(t.errors_notFound))
                  : ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, i) {
                        final country = matches[i];
                        return ListTile(
                          dense: true,
                          title: Text(country.value),
                          // The prefix is shown here because picking a country fills it into
                          // the phone field: this is where that becomes visible, rather than
                          // as something that silently happens afterwards.
                          trailing: Text(
                            '${country.key}  ${callingCode(country.key)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          onTap: () => Navigator.of(context).pop(country),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
