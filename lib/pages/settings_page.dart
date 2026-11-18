import 'package:flutter/material.dart';

import '../db/database_helper.dart';
import '../models/app_settings.dart';
import '../services/auto_checkin_service.dart';
import '../services/notification_service.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback onSaved;
  const SettingsPage({super.key, required this.onSaved});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _salary = TextEditingController();
  final _days = TextEditingController();
  final _std = TextEditingController();

  bool _loading = true;
  bool _fixed = true;
  String _remind = '09:00';
  bool _auto = true;
  String _autoTime = '23:00';
  String _fillIn = '09:00';
  String _fillOut = '18:00';

  String _stdOut = '18:00';
  String _phase1End = '21:00';
  final _p1Rate = TextEditingController();
  final _p2Rate = TextEditingController();
  final _satRate = TextEditingController();
  final _sunRate = TextEditingController();
  final _perLeave = TextEditingController();
  final _sickLeave = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    _salary.dispose(); _days.dispose(); _std.dispose();
    _p1Rate.dispose(); _p2Rate.dispose(); _satRate.dispose(); _sunRate.dispose();
    _perLeave.dispose(); _sickLeave.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await DatabaseHelper.instance.getSettings();
    _salary.text = s.monthlyBaseSalary.toString();
    _days.text = s.payDaysPerMonth.toString();
    _std.text = s.standardHoursPerDay.toString();
    _p1Rate.text = s.phase1Rate.toString();
    _p2Rate.text = s.phase2Rate.toString();
    _satRate.text = s.saturdayRate.toString();
    _sunRate.text = s.sundayRate.toString();
    _perLeave.text = s.personalLeaveRatio.toString();
    _sickLeave.text = s.sickLeaveRatio.toString();
    if (!mounted) return;
    setState(() {
      _fixed = s.isFixedSalary; _remind = s.remindTime; _auto = s.autoFillEnabled;
      _autoTime = s.autoCheckTime; _fillIn = s.fillClockInTime; _fillOut = s.fillClockOutTime;
      _stdOut = s.standardClockOut; _phase1End = s.phase1End; _loading = false;
    });
  }

  Future<void> _pick(String cur, ValueChanged<String> cb) async {
    final p = cur.split(':').map(int.parse).toList();
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: p[0], minute: p[1]));
    if (t == null) return;
    cb('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
  }

  Future<void> _save() async {
    final s = AppSettings(
      monthlyBaseSalary: double.tryParse(_salary.text.trim()) ?? 0,
      isFixedSalary: _fixed, payDaysPerMonth: double.tryParse(_days.text.trim()) ?? 21.75,
      standardHoursPerDay: double.tryParse(_std.text.trim()) ?? 8,
      remindTime: _remind, autoFillEnabled: _auto, autoCheckTime: _autoTime,
      fillClockInTime: _fillIn, fillClockOutTime: _fillOut,
      standardClockOut: _stdOut, phase1End: _phase1End,
      phase1Rate: double.tryParse(_p1Rate.text.trim()) ?? 18,
      phase2Rate: double.tryParse(_p2Rate.text.trim()) ?? 21,
      saturdayRate: double.tryParse(_satRate.text.trim()) ?? 24,
      sundayRate: double.tryParse(_sunRate.text.trim()) ?? 26,
      personalLeaveRatio: double.tryParse(_perLeave.text.trim()) ?? 1.0,
      sickLeaveRatio: double.tryParse(_sickLeave.text.trim()) ?? 0.4,
    );
    await DatabaseHelper.instance.saveSettings(s);
    await NotificationService.scheduleDailyReminder(s.remindTime);
    await AutoCheckInService.scheduleNext();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('设置已保存'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('基础规则', [
          _field(_salary, '月基本工资', null, '¥ '),
          SwitchListTile(title: const Text('固定月薪模式'), subtitle: Text(_fixed ? '月汇总扣除事病假，其余固定' : '按正常工时折算底薪'), value: _fixed, onChanged: (v) => setState(() => _fixed = v)),
          _field(_days, '每月计薪天数', '默认 21.75'),
          _field(_std, '每日标准工时', '默认 8 小时'),
        ]),
        const SizedBox(height: 12),
        _section('加班与分段工资', [
          ListTile(title: const Text('标准下班时间'), subtitle: const Text('此后的时间记为加班'), trailing: Text(_stdOut, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)), onTap: () => _pick(_stdOut, (v) => setState(() => _stdOut = v))),
          ListTile(title: const Text('第一段加班结束时间'), subtitle: const Text('下班到此时段为一段'), trailing: Text(_phase1End, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)), onTap: () => _pick(_phase1End, (v) => setState(() => _phase1End = v))),
          _field(_p1Rate, '第一段加班时薪', '如 18:00-21:00', '¥ '),
          _field(_p2Rate, '第二段加班时薪', '如 21:00 之后', '¥ '),
          _field(_satRate, '周六加班时薪', '全天按时薪计', '¥ '),
          _field(_sunRate, '周日加班时薪', '全天按时薪计', '¥ '),
        ]),
        const SizedBox(height: 12),
        _section('请假扣款设置', [
          _field(_perLeave, '事假扣除比例', '1.0 为扣 100% 日薪'),
          _field(_sickLeave, '病假扣除比例', '如 0.4 为扣 40% 日薪'),
        ]),
        const SizedBox(height: 12),
        _section('提醒与自动补卡', [
          ListTile(title: const Text('提醒时间'), trailing: Text(_remind, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)), onTap: () => _pick(_remind, (v) => setState(() => _remind = v))),
          SwitchListTile(title: const Text('启用每晚自动补卡'), value: _auto, onChanged: (v) => setState(() => _auto = v)),
          _tile('检查时间', _autoTime, _auto, () => _pick(_autoTime, (v) => setState(() => _autoTime = v))),
          _tile('补卡上班时间', _fillIn, _auto, () => _pick(_fillIn, (v) => setState(() => _fillIn = v))),
          _tile('补卡下班时间', _fillOut, _auto, () => _pick(_fillOut, (v) => setState(() => _fillOut = v))),
        ]),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: _save, icon: const Icon(Icons.check), label: const Text('保存设置'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), letterSpacing: 0.5))),
      ...children,
    ]),
  );

  Widget _field(TextEditingController c, String label, String? helper, [String? prefix]) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: label, helperText: helper, prefixText: prefix, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
  );

  Widget _tile(String title, String value, bool enabled, VoidCallback onTap) => ListTile(
    enabled: enabled, title: Text(title), trailing: Text(value, style: TextStyle(color: enabled ? Theme.of(context).colorScheme.primary : const Color(0xFF9CA3AF), fontWeight: FontWeight.w600)), onTap: enabled ? onTap : null,
  );
}
