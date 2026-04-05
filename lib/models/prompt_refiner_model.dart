class PromptRefinerResult {
  final String result;
  final bool modelLoaded;

  PromptRefinerResult({
    required this.result,
    required this.modelLoaded,
  });

  factory PromptRefinerResult.fromJson(Map<String, dynamic> json) {
    return PromptRefinerResult(
      result: json['result']?.toString() ?? '',
      modelLoaded: json['model_loaded'] == true,
    );
  }
}
