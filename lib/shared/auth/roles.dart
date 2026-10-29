enum Role {
  admin,
  supportAgent,
  user,
  guest;

  static Role fromString(String? raw) {
    return switch (raw?.toLowerCase()) {
      'admin' => Role.admin,
      'support_agent' || 'supportagent' || 'editor' => Role.supportAgent,
      'user' || 'member' || 'viewer' => Role.user,
      _ => Role.guest,
    };
  }
}
