import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'db/database_helper.dart';
import 'pages/calendar_page.dart';
import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'services/auto_checkin_service.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. 立即启动 UI，绝不卡白屏！
  runApp(const App());

  // 2. 延迟一帧后再悄悄初始化插件，哪怕报错也不影响界面
  Future.delayed(Duration.zero, () async {
    await _initServices();
  });
}

Future<void> _initServices() async {
  // 用 try-catch 包裹每一项，防止某个插件初始化失败导致崩溃
  try {
    await initializeDateFormatting('zh');
  } catch (e) {
    debugPrint('intl init error: $e');
  }

  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('notification init error: $e');
  }

  try {
    await AutoCheckInService.init();
  } catch (e) {
    debugPrint('auto checkin init error: $e');
  }

  try {
    await WidgetService.init();
  } catch (e) {
    debugPrint('widget init error: $e');
  }

  try {
    final s = await DatabaseHelper.instance.getSettings();
    
    try {
      await NotificationService.scheduleDailyReminder(s.remindTime);
    } catch (e) {
      debugPrint('schedule reminder error: $e');
    }
    
    try {
      await AutoCheckInService.scheduleNext();
    } catch (e) {
      debugPrint('schedule auto checkin error: $e');
    }
    
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rec = await DatabaseHelper.instance.getRecordByDate(today);
    
    try {
      await WidgetService.refreshFromRecord(rec);
    } catch (e) {
      debugPrint('widget refresh error: $e');
    }
  } catch (e) {
    debugPrint('data init error: $e');
  }
}

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _i = 0;
  int _tick = 0;
  void _refresh() => setState(() => _tick++);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '工时工资',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3B82F6),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
      ),
      home: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _i,
            children: [
              HomePage(key: ValueKey('h$_tick')),
              CalendarPage(key: ValueKey('c$_tick')),
              SettingsPage(key: ValueKey('s$_tick'), onSaved: _refresh),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _i,
          onDestinationSelected: (v) => setState(() {
            _i = v;
            _tick++;
          }),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.timer_outlined),
                selectedIcon: Icon(Icons.timer),
                label: '打卡'),
            NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: '日历'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: '设置'),
          ],
        ),
      ),
    );
  }
}
