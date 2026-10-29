enum FlagKey {
  newDashboard('new_dashboard'),
  advancedAnalytics('advanced_analytics'),
  chatWonderAi('chatwonder_ai'),
  liveExchangeRates('live_exchange_rates');

  const FlagKey(this.value);
  final String value;
}

abstract interface class FlagEngine {
  bool getFlag(FlagKey key);
}

class LocalFlagEngine implements FlagEngine {
  LocalFlagEngine(Map<FlagKey, bool> initialStore)
      : _store = Map<FlagKey, bool>.from(initialStore);

  final Map<FlagKey, bool> _store;

  @override
  bool getFlag(FlagKey key) => _store[key] ?? false;

  void setFlag(FlagKey key, bool enabled) {
    _store[key] = enabled;
  }
}

final LocalFlagEngine flagEngine = LocalFlagEngine({
  FlagKey.newDashboard: true,
  FlagKey.advancedAnalytics: false,
  FlagKey.chatWonderAi: false,
  FlagKey.liveExchangeRates: true,
});
