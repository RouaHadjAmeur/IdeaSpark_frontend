class DecomposeResponse {
  final String idea;
  final DecomposedPrompts result;
  final String rawOutput;
  final double durationSeconds;
  final bool modelLoaded;

  DecomposeResponse({
    required this.idea,
    required this.result,
    required this.rawOutput,
    required this.durationSeconds,
    required this.modelLoaded,
  });

  factory DecomposeResponse.fromJson(Map<String, dynamic> json) {
    return DecomposeResponse(
      idea: json['idea'] ?? '',
      result: DecomposedPrompts.fromJson(json['result'] ?? {}),
      rawOutput: json['raw_output'] ?? '',
      durationSeconds: (json['duration_seconds'] ?? 0.0).toDouble(),
      modelLoaded: json['model_loaded'] ?? false,
    );
  }
}

class DecomposedPrompts {
  final String sloganPrompt;
  final String videoPrompt;
  final String productIdeaPrompt;

  DecomposedPrompts({
    required this.sloganPrompt,
    required this.videoPrompt,
    required this.productIdeaPrompt,
  });

  factory DecomposedPrompts.fromJson(Map<String, dynamic> json) {
    return DecomposedPrompts(
      sloganPrompt: json['slogan_prompt'] ?? '',
      videoPrompt: json['video_prompt'] ?? '',
      productIdeaPrompt: json['product_idea_prompt'] ?? '',
    );
  }
}
