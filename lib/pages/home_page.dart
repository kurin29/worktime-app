import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../db/database_helper.dart';
import '../models/app_settings.dart';
import '../models/work_record.dart';
import '../services/wage_calculator.dart';
import '../services/widget_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AppSettings? _s;
  WorkRecord? _r;
  bool _loading = true;

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await DatabaseHelper.instance.getSettings();
    final r = await DatabaseHelper.instance.getRecordByDate(_today);
    await WidgetService.refreshFromRecord(r);
    if (!mounted) return;
    setState(() {
      _s = s;
      _r = r;
      _loading = false;
    });
  }

  Future<void> _changeStatus(int type) async {
    final base = _r ?? WorkRecord(date: _today);
    final updated = base.copyWith(leaveType: type);
    await DatabaseHelper.instance.upsertRecord(updated);
    await _load();
  }

  Future<void> _write(Future<WorkRecord> Function(WorkRecord) mutate, String msg) async {
    final base = _r ?? WorkRecord(date: _today);
    final updated = await mutate(base);
    await DatabaseHelper.instance.upsertRecord(updated);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _clockIn() async {
    HapticFeedback.mediumImpact();
    final t = DateFormat('HH:mm').format(DateTime.now());
    await _write((r) => Future.value(r.copyWith(clockIn: t, leaveType: 0)), '上班打卡 $t');
  }

  Future<void> _clockOut() async {
    if (_r?.clockIn == null) return _toast('请先上班打卡');
    HapticFeedback.mediumImpact();
    final t = DateFormat('HH:mm').format(DateTime.now());
    await _write((r) => Future.value(r.copyWith(clockOut: t, breakStart: null, breakEnd: null)), '下班打卡 $t');
  }

  Future<void> _breakStart() async {
    if (_r?.clockIn == null) return _toast('请先上班打卡');
    HapticFeedback.lightImpact();
    final t = DateFormat('HH:mm').format(DateTime.now());
    await _write((r) => Future.value(r.copyWith(breakStart: t, breakEnd: null)), '休息开始 $t');
  }

  Future<void> _breakEnd() async {
    if (_r?.breakStart == null) return _toast('请先开始休息');
    HapticFeedback.lightImpact();
    final t = DateFormat('HH:mm').format(DateTime.now());
    await _write((r) => Future.value(r.copyWith(breakEnd: t)), '休息结束 $t');
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      );

  @override
Widget build(BuildContext context) {
  if (_loading || _s == null) return const Center(child: CircularProgressIndicator());
  
  final w = WageCalculator(_s!).calculateDay(_r);
  final hasIn = _r?.clockIn != null;
  final hasOut = _r?.clockOut != null;
  final onBreak = _r?.breakStart != null && _r?.breakEnd == null;
  final status = _r?.leaveType ?? 0;

  return RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statusChip('正常打卡', 0, status, Colors.blue),
            _statusChip('事假', 1, status, Colors.red),
            _statusChip('病假', 2, status, Colors.orange),
            _statusChip('休息日', 3, status, Colors.green),
          ],
        ),
        const SizedBox(height: 14),
        
        if (status == 0) ...[
          _statusCard(hasIn, hasOut, onBreak, w),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _btn(hasIn ? '重打上班' : '上班打卡', Icons.login, hasIn ? const Color(0xFF9CA3AF) : const Color(0xFF3B82F6), _clockIn)),
            const SizedBox(width: 10),
            Expanded(child: _btn(hasOut ? '重打下班' : '下班打卡', Icons.logout, hasOut ? const Color(0xFF9CA3AF) : const Color(0xFF10B981), _clockOut)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _btn(onBreak ? '休息结束' : (_r?.breakEnd != null ? '重新休息' : '休息开始'), onBreak ? Icons.free_breakfast : Icons.coffee, hasIn ? const Color(0xFFF59E0B) : const Color(0xFFD1D5DB), onBreak ? _breakEnd : _breakStart)),
          ]),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(
              children: [
                Icon(status == 1 ? Icons.event_busy : status == 2 ? Icons.local_hospital : Icons.weekend, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                Text('今日状态：${status == 1 ? "事假" : status == 2 ? "病假" : "休息日/全天加班"}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (status == 3)
                  Text('如果有打卡，将自动按周末时薪计算加班费', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          if (status == 3) ...[
             const SizedBox(height: 14),
             Row(children: [
              Expanded(child: _btn(hasIn ? '重打上班' : '上班打卡', Icons.login, hasIn ? const Color(0xFF9CA3AF) : const Color(0xFF3B82F6), _clockIn)),
              const SizedBox(width: 10),
              Expanded(child: _btn(hasOut ? '重打下班' : '下班打卡', Icons.logout, hasOut ? const Color(0xFF9CA3AF) : const Color(0xFF10B981), _clockOut)),
            ]),
          ]
        ],
        const SizedBox(height: 14),
        _summary(w),
      ],
    ),
  );
}

  Widget _statusChip(String label, int type, int current, Color color) {
  final selected = type == current;
  return ChoiceChip(
    label: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black87, fontSize: 13)),
    selected: selected,
    selectedColor: color,
    onSelected: (val) {
      if (val) {
        _changeStatus(type);
      }
    },
  );
}

Widget _statusCard(bool hasIn, bool hasOut, bool onBreak, WageResult w) {
  final isWeekend = DateTime.now().weekday >= 6;
  final colors = (hasIn && hasOut) ? [const Color(0xFF10B981), const Color(0xFF059669)] : onBreak ? [const Color(0xFFF59E0B), const Color(0xFFEA580C)] : hasIn ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)] : [const Color(0xFFF59E0B), const Color(0xFFEA580C)];
  final statusText = (hasIn && hasOut) ? '已完成' : onBreak ? '休息中' : hasIn ? '工作中' : '未打卡';

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: colors.first.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(DateFormat('yyyy-MM-dd EEEE', 'zh').format(DateTime.now()), style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(20)),
          child: Text(statusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: _kvWhite('上班', _r?.clockIn ?? '--')),
        Container(width: 1, height: 36, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 10)),
        Expanded(child: _kvWhite('下班', _r?.clockOut ?? '--')),
        Container(width: 1, height: 36, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 10)),
        Expanded(child: _kvWhite('休息', _breakText())),
      ]),
      const SizedBox(height: 18),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _miniStat('正常工时', w.normalHours, Colors.white),
          _miniStat(isWeekend ? '周末加班' : '一阶加班', w.overtimeHours1, Colors.white),
          if (!isWeekend) _miniStat('二阶加班', w.overtimeHours2, Colors.white),
        ],
      )
    ]),
  );
}

Widget _miniStat(String label, double val, Color color) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
    const SizedBox(height: 4),
    Text('${val.toStringAsFixed(1)} h', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
  ],
);

String _breakText() {
  final r = _r;
  if (r == null || r.breakStart == null) return '--';
  if (r.breakEnd == null) return '${r.breakStart}-…';
  return '${r.breakStart}-${r.breakEnd}';
}

Widget _kvWhite(String k, String v) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(k, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    const SizedBox(height: 4),
    Text(v, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
  ],
);

Widget _btn(String label, IconData icon, Color color, VoidCallback onTap) {
  return Material(
    color: color,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    ),
  );
}

    Widget _summary(WageResult w) {
    final isWeekend = DateTime.now().weekday >= 6 || _r?.leaveType == 3;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.receipt_long_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(_s!.isFixedSalary ? '固定月薪模式' : '工时折算模式', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 14),
        _line('正常工时', '${w.normalHours.toStringAsFixed(2)} 小时', '¥${w.basePay.toStringAsFixed(2)}'),
        if (!isWeekend && w.overtimeHours1 > 0)
          _line('一阶加班', '${w.overtimeHours1.toStringAsFixed(2)} 小时', '¥${w.overtimePay1.toStringAsFixed(2)}'),
        if (!isWeekend && w.overtimeHours2 > 0)
          _line('二阶加班', '${w.overtimeHours2.toStringAsFixed(2)} 小时', '¥${w.overtimePay2.toStringAsFixed(2)}'),
        if (isWeekend && w.overtimeHours1 > 0)
          _line('周末加班', '${w.overtimeHours1.toStringAsFixed(2)} 小时', '¥${w.overtimePay1.toStringAsFixed(2)}'),
        const Divider(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('今日合计', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          Text('¥${w.totalPay.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        ]),
      ]),
    );
  }

  Widget _line(String k, String h, String money) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: Color(0xFF6B7280))),
            Row(children: [
              Text(h, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              const SizedBox(width: 10),
              Text(money, style: const TextStyle(fontWeight: FontWeight.w500)),
            ]),
          ],
        ),
      );
}
