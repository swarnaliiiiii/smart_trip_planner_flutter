import 'dart:developer';

class TokenMetrics {
  final int inputTokens;
  final int outputTokens;
  final double estimatedCost;
  final DateTime timestamp;
  final String requestType;

  TokenMetrics({
    required this.inputTokens,
    required this.outputTokens,
    required this.estimatedCost,
    required this.timestamp,
    required this.requestType,
  });

  int get totalTokens => inputTokens + outputTokens;
}

class MetricsManager {
  static final MetricsManager _instance = MetricsManager._internal();
  factory MetricsManager() => _instance;
  MetricsManager._internal();

  final List<TokenMetrics> _metrics = [];
  bool _debugMode = false;

  // Gemini pricing (approximate)
  static const double _inputTokenCostPer1K = 0.00015; // $0.00015 per 1K input tokens
  static const double _outputTokenCostPer1K = 0.0006; // $0.0006 per 1K output tokens

  void setDebugMode(bool enabled) {
    _debugMode = enabled;
  }

  bool get isDebugMode => _debugMode;

  void recordTokenUsage({
    required int inputTokens,
    required int outputTokens,
    required String requestType,
  }) {
    final cost = _calculateCost(inputTokens, outputTokens);
    final metric = TokenMetrics(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      estimatedCost: cost,
      timestamp: DateTime.now(),
      requestType: requestType,
    );

    _metrics.add(metric);
    
    if (_debugMode) {
      log('Token Usage - Input: $inputTokens, Output: $outputTokens, Cost: \$${cost.toStringAsFixed(4)}');
    }
  }

  double _calculateCost(int inputTokens, int outputTokens) {
    final inputCost = (inputTokens / 1000) * _inputTokenCostPer1K;
    final outputCost = (outputTokens / 1000) * _outputTokenCostPer1K;
    return inputCost + outputCost;
  }

  List<TokenMetrics> get allMetrics => List.unmodifiable(_metrics);

  TokenMetrics? get lastMetric => _metrics.isNotEmpty ? _metrics.last : null;

  double get totalCost => _metrics.fold(0.0, (sum, metric) => sum + metric.estimatedCost);

  int get totalTokens => _metrics.fold(0, (sum, metric) => sum + metric.totalTokens);

  void clearMetrics() {
    _metrics.clear();
  }

  // Estimate tokens from text (rough approximation)
  static int estimateTokens(String text) {
    // Rough estimation: 1 token ≈ 4 characters for English text
    return (text.length / 4).ceil();
  }
}