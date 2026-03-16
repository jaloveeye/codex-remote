import 'package:flutter_test/flutter_test.dart';
import 'package:codex_remote/services/streaming_text_merge.dart';

void main() {
  group('mergeStreamingText', () {
    test('isReplace=true이면 fullText를 우선 사용한다', () {
      final merged = mergeStreamingText(
        current: 'hello',
        chunkText: 'ignored',
        fullText: 'hello world',
        isReplace: true,
      );

      expect(merged, 'hello world');
    });

    test('fullText가 current를 prefix로 포함하면 fullText로 확장한다', () {
      final merged = mergeStreamingText(
        current: 'hello',
        chunkText: ' world',
        fullText: 'hello world',
        isReplace: false,
      );

      expect(merged, 'hello world');
    });

    test('동일 chunk 재수신 시 중복 누적하지 않는다', () {
      final merged = mergeStreamingText(
        current: 'hello world',
        chunkText: ' world',
        fullText: '',
        isReplace: false,
      );

      expect(merged, 'hello world');
    });

    test('current 내부에 이미 포함된 chunk는 무시한다', () {
      final merged = mergeStreamingText(
        current: 'hello world',
        chunkText: 'world',
        fullText: '',
        isReplace: false,
      );

      expect(merged, 'hello world');
    });

    test('겹치는 suffix/prefix는 overlap만큼 제거해 병합한다', () {
      final merged = mergeStreamingText(
        current: 'Using',
        chunkText: 'ing-super',
        fullText: '',
        isReplace: false,
      );

      expect(merged, 'Using-super');
    });

    test('chunk가 비어있으면 current를 그대로 유지한다', () {
      final merged = mergeStreamingText(
        current: 'keep',
        chunkText: '',
        fullText: '',
        isReplace: false,
      );

      expect(merged, 'keep');
    });
  });
}
