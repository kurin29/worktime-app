import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../db/database_helper.dart';
import '../models/work_record.dart';

class WidgetService {
  static const _provider = 'WorktimeWidgetProvider';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId('group.com.example.worktime_app');
    HomeWidget.registerInteractivityCallback(widgetBgCallback);
  }

  static Future<void> refreshFromRecord(WorkRecord? r) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await HomeWidget.saveWidgetData<String>('widget_date', today);
    await HomeWidget.saveWidgetData<String>('widget_status', _status(r));
    await HomeWidget.saveWidgetData<String>('widget_in', r?.clockIn ?? '--');
    await HomeWidget.saveWidgetData<String>('widget_out', r?.clockOut ?? '--');
    await HomeWidget.saveWidgetData<String>('widget_break', _break(r));
    await HomeWidget.updateWidget(androidName: _provider);
  }

  static String _status(WorkRecord? r) {
    if (r == null) return '未打卡';
    if (r.breakStart != null && r.breakEnd == null) return '休息中';
    if (r.clockIn != null && r.clockOut == null) return '工作中';
    if (r.clockIn != null && r.clockOut != null) return '已完成';
    return '未打卡';
  }

  static String _break(WorkRecord? r) {
    if (r == null) return '--';
    if (r.breakStart != null && r.breakEnd != null) return '${r.breakStart}-${r.breakEnd}';
    if (r.breakStart != null) return '${r.breakStart}-…';
    return '--';
  }
}

@pragma('vm:entry-point')
Future<void> widgetBgCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (uri == null) return;

  final now = DateFormat('HH:mm').format(DateTime.now());
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  var record = await DatabaseHelper.instance.getRecordByDate(today);
  final path = uri.toString();

  if (path.endsWith('clock_in')) {
    if (record?.clockIn != null) return;
    record = (record ?? WorkRecord(date: today)).copyWith(clockIn: now);
    await DatabaseHelper.instance.upsertRecord(record);
  } else if (path.endsWith('clock_out')) {
    if (record?.clockIn == null || record?.clockOut != null) return;
    record = record!.copyWith(clockOut: now);
    await DatabaseHelper.instance.upsertRecord(record);
  }

  final latest = await DatabaseHelper.instance.getRecordByDate(today);
  await WidgetService.refreshFromRecord(latest);
}
