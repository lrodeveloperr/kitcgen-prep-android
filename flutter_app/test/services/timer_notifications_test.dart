import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_prep_board/services/timer_notifications.dart';

void main() {
  test('timer notification IDs are salted and collision aware', () {
    final base = resolveTimerNotificationId('task-1', const {});
    final expected = Object.hash('task-1', 'timer_notification') & 0x7fffffff;

    expect(base, expected);
    expect(resolveTimerNotificationId('task-1', const {}), base);
    expect(
      resolveTimerNotificationId('task-1', {base: 'another-task'}),
      (base + 1) & 0x7fffffff,
    );
    expect(
      resolveTimerNotificationId('task-1', const {42: 'task-1'}),
      42,
    );
  });
}
