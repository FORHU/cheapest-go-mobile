/// Where an account stands with onboarding. See #62 and ADR-0005.
///
/// Three states told apart by two markers, read out of `profiles.preferences`. The server
/// writes the start as the account is created; this app writes the completion.
enum OnboardingStatus {
  /// Nothing known yet — preferences have not been fetched. The gate waits rather than
  /// guessing, because both wrong guesses are bad: one walls an existing user out of the app
  /// they already use, the other lets a new one past a flow they must finish.
  unknown,

  /// Neither marker. An account made before onboarding existed — **Grandfathered** in
  /// CONTEXT.md. It goes straight in.
  notRequired,

  /// A start without a completion: registered, and either still in the flow or closed the app
  /// partway through it. It resumes.
  required,

  /// Both markers. Finished, and never shown again.
  completed,
}

/// The two markers as they sit inside the preferences blob.
class OnboardingMarkers {
  const OnboardingMarkers({this.startedAt, this.completedAt});

  final String? startedAt;
  final String? completedAt;

  /// The key the markers sit under. Matches `ONBOARDING_KEY` in api-v2's `lib/users/onboarding.ts`.
  static const String key = 'onboarding';

  OnboardingStatus get status {
    if (completedAt != null) return OnboardingStatus.completed;
    if (startedAt != null) return OnboardingStatus.required;
    return OnboardingStatus.notRequired;
  }

  /// Reads the markers out of a preferences blob.
  ///
  /// Tolerant of anything else under the key. Preferences are a blob the web may replace
  /// wholesale, so a malformed value means "not stated" rather than an error — and "not
  /// stated" is the grandfathered reading, which lets somebody into the app rather than
  /// trapping them in a flow.
  factory OnboardingMarkers.fromPreferences(Map<String, dynamic>? preferences) {
    final raw = preferences?[key];
    if (raw is! Map) return const OnboardingMarkers();

    String? at(String field) {
      final value = raw[field];
      return value is String && value.isNotEmpty ? value : null;
    }

    return OnboardingMarkers(startedAt: at('startedAt'), completedAt: at('completedAt'));
  }

  /// The markers written back, with this moment as the completion.
  Map<String, dynamic> completedNow({DateTime? now}) => {
        if (startedAt != null) 'startedAt': startedAt,
        'completedAt': (now ?? DateTime.now().toUtc()).toIso8601String(),
      };
}
