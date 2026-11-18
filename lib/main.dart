import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'db/database_helper.dart';
import 'pages/calendar_page.dart';
import 'pages/home_page.dart'; // 👈 就是这一行，确保它存在
import 'pages/settings_page.dart';
import 'services/auto_checkin_service.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const App());

  Future.delayed(Duration.zero, () async {
    await _initServices();
  });
}

Future<void> _initServices() async {
  try { await initializeDateFormatting('zh'); } catch (e) { debugPrint('$e'); }
  try { await NotificationService.init(); } catch (e) { debugPrint('$e'); }
  try { await AutoCheckInService.init(); } catch (e) { debugPrint('$e'); }
  try { await WidgetService.init(); } catch (e) { debugPrint('$e'); }

  try {
    final s = await DatabaseHelper.instance.getSettings();
    try { await NotificationService.scheduleDailyReminder(s.remindTime); } catch (e) { debugPrint('$e'); }
    try { await AutoCheckInService.scheduleNext(); } catch (e) { debugPrint('$e'); }
    
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rec = await DatabaseHelper.instance.getRecordByDate(today);
    try { await WidgetService.refreshFromRecord(rec); } catch (e) { debugPrint('$e'); }
  } catch (e) {
    debugPrint('$e');
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
