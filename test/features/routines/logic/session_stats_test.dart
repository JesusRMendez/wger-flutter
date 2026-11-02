import 'package:flutter_test/flutter_test.dart';
import 'package:wger/features/routines/logic/session_stats.dart';
import 'package:wger/features/routines/models/log.dart';
import 'package:wger/features/routines/models/session.dart';

import '../../../../test_data/screenshots/routines.dart';

void main() {
  final routine = getScreenshotRoutine();
  final session = routine.sessions.first;

  WorkoutSession earlier(num delta, {int days = 7}) => session.copyWith(
    id: 'earlier-$days',
    datetimeStart: session.datetimeStart.subtract(Duration(days: days)),
    datetimeEnd: session.datetimeEnd!.subtract(Duration(days: days)),
    logs: [for (final Log l in session.logs) l.copyWith(weight: l.weight! + delta)],
  );

  test('estimates the one rep max with the Epley formula', () {
    expect(estimatedOneRepMax(100, 0), 100);
    expect(estimatedOneRepMax(80, 8), closeTo(101.33, 0.01));
  });

  test('a record needs a better set than any earlier session', () {
    final records = deriveRecords(session, [earlier(-2.5)]);
    expect(records, hasLength(2));
    expect(records.first.weight, 80);
    expect(records.first.repetitions, 8);

    expect(deriveRecords(session, [earlier(0)]), isEmpty);
    expect(deriveRecords(session, [earlier(5)]), isEmpty);
  });

  test('the first time of an exercise is a baseline, not a record', () {
    expect(deriveRecords(session, const []), isEmpty);
  });

  test('later sessions do not count as history', () {
    expect(deriveRecords(session, [earlier(-2.5, days: -3)]), isEmpty);
  });

  test('the volume change is measured against the latest earlier session', () {
    expect(volumeChangePercent(session, const []), isNull);
    final change = volumeChangePercent(session, [earlier(-2.5)]);
    expect(change, isNotNull);
    expect(change, greaterThan(0));
    expect(volumeChangePercent(session, [earlier(0)]), 0);
  });
}
