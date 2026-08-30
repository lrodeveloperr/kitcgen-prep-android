import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_prep_board/services/timer_notifications.dart';

void main() {
  test('timer notification IDs are deterministic and collision aware', () {
    final base = resolveTimerNotificationId('task-1', const {});

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
