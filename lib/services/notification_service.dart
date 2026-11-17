import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../db/database_helper.dart';

class NotificationService {
  static final _p = FlutterLocalNotificationsPlugin();
  static const _dailyId = 1001;
  static const _autoId = 2001;

  static Future<void> init() async {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (_) {}

    await _p.initialize(
      const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher')),
      onDidReceiveNotificationResponse: (r) => _handle(r.actionId),
      onDidReceiveBackgroundNotificationResponse: onBgAction,
    );

    await _p
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> _handle(String? action) async {
    if (action == 'cancel_checkin') {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await DatabaseHelper.instance.deleteRecordByDate(today);
    }
    // confirm_checkin：保留记录，无需操作
  }

  static Future<void> scheduleDailyReminder(String hhmm) async {
    await _p.cancel(_dailyId);
    final parts = hhmm.split(':').map(int.parse).toList();
    final now = DateTime.now();
    var at = DateTime(now.year, now.month, now.day, parts[0], parts[1]);
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));

    await _p.zonedSchedule(
      _dailyId,
      '打卡提醒',
      '别忘了记录今天的上下班时间',
      tz.TZDateTime.from(at, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_checkin', '每日打卡提醒',
          importance: Importance.high, priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> showAutoCheckInPrompt(String date) async {
    await _p.show(
      _autoId,
      '今日未打卡',
      '已自动补卡 $date，请确认',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'auto_checkin_channel', '自动补卡确认',
          importance: Importance.high, priority: Priority.high,
          actions: [
            AndroidNotificationAction('confirm_checkin', '确定打卡',
                showsUserInterface: false, cancelNotification: true),
            AndroidNotificationAction('cancel_checkin', '取消打卡',
                showsUserInterface: false, cancelNotification: true),
          ],
        ),
      ),
      payload: 'auto_checkin',
    );
  }
}

@pragma('vm:entry-point')
void onBgAction(NotificationResponse r) async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService._handle(r.actionId);
}
