class VoiceAction {
  final String intent;
  final int? index;
  final String? destination;
  final String? topic;

  VoiceAction({
    required this.intent,
    this.index,
    this.destination,
    this.topic,
  });

  factory VoiceAction.fromJson(Map<String, dynamic> json) {
    return VoiceAction(
      intent: json['intent'] as String,
      index: json['index'] != null ? json['index'] as int : null,
      destination: json['destination'] as String?,
      topic: json['topic'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'intent': intent,
      if (index != null) 'index': index,
      if (destination != null) 'destination': destination,
      if (topic != null) 'topic': topic,
    };
  }
}

class VoiceParseResponse {
  final List<VoiceAction> actions;
  final bool requiresConfirmation;
  final String? confirmationKey;
  final String say;

  VoiceParseResponse({
    required this.actions,
    required this.requiresConfirmation,
    this.confirmationKey,
    required this.say,
  });

  factory VoiceParseResponse.fromJson(Map<String, dynamic> json) {
    return VoiceParseResponse(
      actions: (json['actions'] as List<dynamic>?)
              ?.map((e) => VoiceAction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? false,
      confirmationKey: json['confirmationKey'] as String?,
      say: json['say'] as String? ?? 'OK',
    );
  }
}

class VoiceConfirmResponse {
  final bool confirmed;
  final List<VoiceAction>? actions;
  final String say;

  VoiceConfirmResponse({
    required this.confirmed,
    this.actions,
    required this.say,
  });

  factory VoiceConfirmResponse.fromJson(Map<String, dynamic> json) {
    return VoiceConfirmResponse(
      confirmed: json['confirmed'] as bool? ?? false,
      actions: (json['actions'] as List<dynamic>?)
          ?.map((e) => VoiceAction.fromJson(e as Map<String, dynamic>))
          .toList(),
      say: json['say'] as String? ?? '',
    );
  }
}
