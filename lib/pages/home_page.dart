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

  Future<void> _write(Future<WorkRecord> Function(WorkRecord) mutate,
      String msg) async {
    final base = _r ?? WorkRecord(date: _today);
    final updated = await mutate(base);
    await DatabaseHelper.instance.upsertRecord(updated);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _clockIn() async {
    HapticFeedback.mediumImpact();
    final t = DateFormat('HH:mm').format(DateTime.now());
    await _write((r) => Future.value(r.copyWith(clockIn: t)), '上班打卡 $t');
  }

  Future<void> _clockOut() async {
    if (_r?.clockIn == null) return _toast('请先上班打卡');
    HapticFeedback.mediumImpact();
    final t = DateFormat('HH:mm').format(DateTime.now());
    await _write(
        (r) => Future.value(
            r.copyWith(clockOut: t, breakStart: null, breakEnd: null)),
        '下班打卡 $t');
  }

  Future<void> _breakStart() async {
    if (_r?.clockIn == null) return _toast('请先上班打卡');
    HapticFeedback.lightImpact();
    final t = DateFormat('HH:mm').format(DateTime.now());
    await _write((r) => Future.value(r.copyWith(breakStart: t, breakEnd: null)),
        '休息开始 $t');
  }

  Future<void> _breakEnd() async {
    if (_r?.breakStart == null) return _toast('请先开始休息');
    HapticFeedback.lightImpact();
    final t = DateFormat('HH:mm').format(DateTime.now());
    await _write(
        (r) => Future.value(r.copyWith(breakEnd: t)), '休息结束 $t');
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(m),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
      );

  Future<void> _edit() async {
    final r = _r ?? WorkRecord(date: _today);
    final result = await showModalBottomSheet<WorkRecord>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _RecordEditSheet(record: r),
    );
    if (result != null) {
      await DatabaseHelper.instance.upsertRecord(result);
      await _load();
      _toast('记录已更新');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _s == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final w = WageCalculator(_s!).calculateDay(_r);
    final hasIn = _r?.clockIn != null;
    final hasOut = _r?.clockOut != null;
    final onBreak = _r?.breakStart != null && _r?.breakEnd == null;
    final progress = _s!.standardHoursPerDay > 0
        ? (w.normalHours / _s!.standardHoursPerDay).clamp(0.0, 1.0)
        : 0.0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _statusCard(hasIn, hasOut, onBreak, w, progress),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: _btn(hasIn ? '重打上班' : '上班打卡', Icons.login,
                    hasIn ? const Color(0xFF9CA3AF) : const Color(0xFF3B82F6),
                    _clockIn)),
            const SizedBox(width: 10),
            Expanded(
                child: _btn(hasOut ? '重打下班' : '下班打卡', Icons.logout,
                    hasOut ? const Color(0xFF9CA3AF) : const Color(0xFF10B981),
                    _clockOut)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _btn(
                    onBreak
                        ? '休息结束'
                        : (_r?.breakEnd != null ? '重新休息' : '休息开始'),
                    onBreak ? Icons.free_breakfast : Icons.coffee,
                    hasIn ? const Color(0xFFF59E0B) : const Color(0xFFD1D5DB),
                    onBreak ? _breakEnd : _breakStart)),
            const SizedBox(width: 10),
            Expanded(
                child: _btn('编辑记录', Icons.edit_outlined,
                    const Color(0xFF6B7280), _edit)),
          ]),
          const SizedBox(height: 14),
          _summary(w),
        ],
      ),
    );
  }

  Widget _statusCard(
      bool hasIn, bool hasOut, bool onBreak, WageResult w, double progress) {
    final colors = (hasIn && hasOut)
        ? [const Color(0xFF10B981), const Color(0xFF059669)]
        : onBreak
            ? [const Color(0xFFF59E0B), const Color(0xFFEA580C)]
            : hasIn
                ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                : [const Color(0xFFF59E0B), const Color(0xFFEA580C)];
    final statusText = (hasIn && hasOut)
        ? '已完成'
        : onBreak
            ? '休息中'
            : hasIn
                ? '工作中'
                : '未打卡';
    final icon = (hasIn && hasOut)
        ? Icons.check_circle
        : onBreak
            ? Icons.coffee
            : hasIn
                ? Icons.timelapse
                : Icons.warning_amber;

    final now = DateTime.now();
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: colors.first.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(DateFormat('yyyy-MM-dd').format(now),
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            Text(weekdays[now.weekday - 1],
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
          ]),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(statusText,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: _kvWhite('上班', _r?.clockIn ?? '--')),
          Container(
              width: 1,
              height: 36,
              color: Colors.white24,
              margin: const EdgeInsets.symmetric(horizontal: 10)),
          Expanded(child: _kvWhite('下班', _r?.clockOut ?? '--')),
          Container(
              width: 1,
              height: 36,
              color: Colors.white24,
              margin: const EdgeInsets.symmetric(horizontal: 10)),
          Expanded(child: _kvWhite('休息', _breakText())),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 7,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeCap: StrokeCap.round,
                ),
              ),
              if (onBreak)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
              Text('${(progress * 100).toInt()}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('今日工时进度',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                      '${w.normalHours.toStringAsFixed(2)} / ${_s!.standardHoursPerDay.toStringAsFixed(0)} 小时',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                ]),
          ),
        ]),
      ]),
    );
  }

  String _breakText() {
    final r = _r;
    if (r == null || r.breakStart == null) return '--';
    if (r.breakEnd == null) return '${r.breakStart}-…';
    return '${r.breakStart}-${r.breakEnd}';
  }

  Widget _kvWhite(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(v,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
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
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ]),
        ),
      ),
    );
  }

  Widget _summary(WageResult w) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.receipt_long_outlined,
              color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(_s!.isFixedSalary ? '固定月薪模式' : '工时折算模式',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 14),
        _line('正常工时', '${w.normalHours.toStringAsFixed(2)} 小时'),
        _line('加班工时', '${w.overtimeHours.toStringAsFixed(2)} 小时'),
        _line('底薪工资', '¥${w.basePay.toStringAsFixed(2)}'),
        _line('加班工资', '¥${w.overtimePay.toStringAsFixed(2)}'),
        const Divider(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('今日合计',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          Text('¥${w.totalPay.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary)),
        ]),
      ]),
    );
  }

  Widget _line(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(k, style: const TextStyle(color: Color(0xFF6B7280))),
              Text(v, style: const TextStyle(fontWeight: FontWeight.w500)),
            ]),
      );
}

class _RecordEditSheet extends StatefulWidget {
  final WorkRecord record;
  const _RecordEditSheet({required this.record});
  @override
  State<_RecordEditSheet> createState() => _RecordEditSheetState();
}

class _RecordEditSheetState extends State<_RecordEditSheet> {
  String? _in, _out, _bs, _be;
  late final TextEditingController _bm, _om, _note;

  @override
  void initState() {
    super.initState();
    _in = widget.record.clockIn;
    _out = widget.record.clockOut;
    _bs = widget.record.breakStart;
    _be = widget.record.breakEnd;
    _bm = TextEditingController(text: widget.record.breakMinutes.toString());
    _om =
        TextEditingController(text: widget.record.overtimeMinutes.toString());
    _note = TextEditingController(text: widget.record.note ?? '');
  }

  @override
  void dispose() {
    _bm.dispose();
    _om.dispose();
    _note.dispose();
    super.dispose();
  }

  TimeOfDay _t(String? v) {
    if (v == null) return TimeOfDay.now();
    final p = v.split(':').map(int.parse).toList();
    return TimeOfDay(hour: p[0], minute: p[1]);
  }

  Future<String?> _pick(String? cur) async {
    final p = await showTimePicker(context: context, initialTime: _t(cur));
    if (p == null) return null;
    return '${p.hour.toString().padLeft(2, '0')}:${p.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('编辑打卡记录',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _timeTile('上班', _in, () async {
                final v = await _pick(_in);
                if (v != null) setState(() => _in = v);
              })),
              const SizedBox(width: 10),
              Expanded(child: _timeTile('下班', _out, () async {
                final v = await _pick(_out);
                if (v != null) setState(() => _out = v);
              })),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _timeTile('休息开始', _bs, () async {
                final v = await _pick(_bs);
                if (v != null) setState(() => _bs = v);
              })),
              const SizedBox(width: 10),
              Expanded(child: _timeTile('休息结束', _be, () async {
                final v = await _pick(_be);
                if (v != null) setState(() => _be = v);
              })),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: TextField(
                controller: _bm,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '休息分钟（无起止时使用）',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                controller: _om,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '加班分钟',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              )),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              decoration: InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: const Text('取消'),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    widget.record.copyWith(
                      clockIn: _in,
                      clockOut: _out,
                      breakStart: _bs,
                      breakEnd: _be,
                      breakMinutes: int.tryParse(_bm.text) ?? 0,
                      overtimeMinutes: int.tryParse(_om.text) ?? 0,
                      note: _note.text.trim().isEmpty
                          ? null
                          : _note.text.trim(),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: const Text('保存'),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _timeTile(String label, String? v, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF6B7280))),
            const SizedBox(height: 4),
            Text(v ?? '未设置',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: v == null ? const Color(0xFF9CA3AF) : Colors.black)),
          ]),
        ),
      );
}
