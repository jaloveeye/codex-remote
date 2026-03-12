import 'dart:math';

int suffixPrefixOverlapLength(String base, String suffixCandidate) {
  final max = min(base.length, suffixCandidate.length);
  for (var i = max; i > 0; i--) {
    if (base.substring(base.length - i) == suffixCandidate.substring(0, i)) {
      return i;
    }
  }
  return 0;
}

String mergeStreamingText({
  required String current,
  required String chunkText,
  required String fullText,
  required bool isReplace,
}) {
  if (isReplace) {
    if (fullText.isNotEmpty) return fullText;
    if (chunkText.isNotEmpty) return chunkText;
    return current;
  }

  if (fullText.isNotEmpty) {
    if (current.isEmpty) return fullText;
    if (fullText == current) return current;
    if (fullText.length >= current.length && fullText.startsWith(current)) {
      return fullText;
    }
  }

  if (chunkText.isEmpty) return current;
  if (current.endsWith(chunkText)) return current;
  if (current.contains(chunkText)) return current;

  final overlap = suffixPrefixOverlapLength(current, chunkText);
  return current + chunkText.substring(overlap);
}
