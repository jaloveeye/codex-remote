import 'package:codex_remote/services/codex_request_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('upsertCodexRequestHistory는 같은 requestId+status를 교체하고 최신순 유지', () {
    final first = buildCodexRequestHistoryEntry(
      requestId: 'req_1',
      status: 'pending',
      title: 'Need approval',
      summary: 'summary',
      timestampMs: 1000,
    );
    final second = buildCodexRequestHistoryEntry(
      requestId: 'req_1',
      status: 'pending',
      title: 'Need approval (updated)',
      summary: 'summary2',
      timestampMs: 2000,
    );

    final updated = upsertCodexRequestHistory(current: [first], entry: second);
    expect(updated.length, 1);
    expect(updated.first['title'], 'Need approval (updated)');
  });

  test('toApprovalHistoryItem은 resolved를 approved 카드 상태로 매핑한다', () {
    final entry = buildCodexRequestHistoryEntry(
      requestId: 'req_2',
      status: 'resolved',
      title: 'Codex request',
      summary: 'done',
      requestKind: 'command_execution',
      resolvedBy: 'mobile-1',
      timestampMs: 1234,
    );

    final item = toApprovalHistoryItem(entry);
    expect(item['status'], 'approved');
    expect(item['title'], 'Codex 요청 처리');
    expect(item['approvalId'], 'req_2');
  });

  test('toApprovalHistoryItem은 pending을 pending 카드 상태로 매핑한다', () {
    final entry = buildCodexRequestHistoryEntry(
      requestId: 'req_3',
      status: 'pending',
      title: 'Need mobile decision',
      summary: 'pending approval',
      timestampMs: 3000,
    );

    final item = toApprovalHistoryItem(entry);
    expect(item['status'], 'pending');
    expect(item['title'], 'Codex 요청 도착');
  });
}
