import 'dart:math';

/// Evaluation metrics for speech recognition accuracy.
class SttEvaluationMetrics {
  final double wer; // Word Error Rate (0.0 to 1.0+)
  final double cer; // Character Error Rate (0.0 to 1.0+)
  final int substitutions;
  final int deletions;
  final int insertions;
  final int referenceWords;

  const SttEvaluationMetrics({
    required this.wer,
    required this.cer,
    required this.substitutions,
    required this.deletions,
    required this.insertions,
    required this.referenceWords,
  });

  Map<String, dynamic> toJson() => {
        'wer': double.parse(wer.toStringAsFixed(4)),
        'cer': double.parse(cer.toStringAsFixed(4)),
        'substitutions': substitutions,
        'deletions': deletions,
        'insertions': insertions,
        'referenceWords': referenceWords,
      };
}

/// Computes standard Word Error Rate (WER) using Levenshtein alignment on tokenized words.
/// WER = (Substitutions + Deletions + Insertions) / N_reference
double computeWER(String reference, String hypothesis) {
  final refWords = reference
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .toList();
  final hypWords = hypothesis
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .toList();

  if (refWords.isEmpty) {
    return hypWords.isEmpty ? 0.0 : 1.0;
  }

  final dp = List.generate(
    refWords.length + 1,
    (i) => List.filled(hypWords.length + 1, 0),
  );

  for (int i = 0; i <= refWords.length; i++) dp[i][0] = i;
  for (int j = 0; j <= hypWords.length; j++) dp[0][j] = j;

  for (int i = 1; i <= refWords.length; i++) {
    for (int j = 1; j <= hypWords.length; j++) {
      if (refWords[i - 1] == hypWords[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1];
      } else {
        dp[i][j] = 1 + min(dp[i - 1][j - 1], min(dp[i - 1][j], dp[i][j - 1]));
      }
    }
  }

  return dp[refWords.length][hypWords.length] / refWords.length.toDouble();
}

/// Computes Character Error Rate (CER) on normalized text.
double computeCER(String reference, String hypothesis) {
  final refChars = reference.trim().toLowerCase().split('');
  final hypChars = hypothesis.trim().toLowerCase().split('');

  if (refChars.isEmpty) {
    return hypChars.isEmpty ? 0.0 : 1.0;
  }

  final dp = List.generate(
    refChars.length + 1,
    (i) => List.filled(hypChars.length + 1, 0),
  );

  for (int i = 0; i <= refChars.length; i++) dp[i][0] = i;
  for (int j = 0; j <= hypChars.length; j++) dp[0][j] = j;

  for (int i = 1; i <= refChars.length; i++) {
    for (int j = 1; j <= hypChars.length; j++) {
      if (refChars[i - 1] == hypChars[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1];
      } else {
        dp[i][j] = 1 + min(dp[i - 1][j - 1], min(dp[i - 1][j], dp[i][j - 1]));
      }
    }
  }

  return dp[refChars.length][hypChars.length] / refChars.length.toDouble();
}
