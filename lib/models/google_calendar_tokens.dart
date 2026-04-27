/// Model for storing Google Calendar OAuth tokens
class GoogleCalendarTokens {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  const GoogleCalendarTokens({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  factory GoogleCalendarTokens.fromJson(Map<String, dynamic> json) {
    return GoogleCalendarTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    };
  }

  /// Check if the access token is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Create a copy with updated fields
  GoogleCalendarTokens copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) {
    return GoogleCalendarTokens(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
