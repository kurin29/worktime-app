import '../models/app_settings.dart';
import '../models/work_record.dart';

class WageResult {
  final double normalHours;
  final double overtimeHours1;
  final double overtimeHours2;
  final double basePay;
  final double overtimePay1;
  final double overtimePay2;
  final double totalPay;

  WageResult({
    required this.normalHours,
    required this.overtimeHours1,
    required this.overtimeHours2,
    required this.basePay,
    required this.overtimePay1,
    required this.overtimePay2,
    required this.totalPay,
  });

  double get overtimeHours => overtimeHours1 + overtimeHours2;
  double get overtimePay => overtimePay1 + overtimePay2;

  static WageResult zero() => WageResult(
        normalHours: 0, overtimeHours1: 0, overtimeHours2: 0, basePay: 0, overtimePay1: 0, overtimePay2: 0, totalPay: 0,
      );
}

class WageCalculator {
  final AppSettings s;
  WageCalculator(this.s);

  double get baseHourlyRate {
    if (s.payDaysPerMonth <= 0 || s.standardHoursPerDay <= 0) return 0;
    return s.monthlyBaseSalary / s.payDaysPerMonth / s.standardHoursPerDay;
  }

  static int _m(String v) {
    final p = v.split(':').map(int.parse).toList();
    return p[0] * 60 + p[1];
  }

  WageResult calculateDay(WorkRecord? r) {
    if (r == null || (r.clockIn == null && r.clockOut == null) || r.leaveType == 1 || r.leaveType == 2) {
      return WageResult.zero();
    }

    final inM = _m(r.clockIn!);
    var outM = _m(r.clockOut!);
    if (outM < inM) outM += 24 * 60;

    final isWeekend = DateTime.parse(r.date).weekday >= 6 || r.leaveType == 3;
    double normalH = 0, ot1H = 0, ot2H = 0;
    double basePay = 0, ot1Pay = 0, ot2Pay = 0;

    if (isWeekend) {
      // 周末全部算加班
      final h = (outM - inM - r.effectiveBreakMinutes) / 60.0;
      ot1H = h.clamp(0, 24);
      ot1Pay = ot1H * s.weekendRate;
    } else {
      final stdOut = _m(s.standardClockOut);
      final phase1End = _m(s.phase1End);

      // 1. 正常工时
      final normEnd = outM < stdOut ? outM : stdOut;
      final norm = normEnd - inM;
      if (norm > 0) normalH = norm / 60.0;

      // 2. 加班段1
      if (outM > stdOut) {
        final o1End = outM < phase1End ? outM : phase1End;
        final o1 = o1End - stdOut;
        if (o1 > 0) ot1H = o1 / 60.0;
      }

      // 3. 加班段2
      if (outM > phase1End) {
        final o2 = outM - phase1End;
        ot2H = o2 / 60.0;
      }

      // 扣除休息时间
      double breakH = r.effectiveBreakMinutes / 60.0;
      if (normalH > 0) {
        if (normalH >= breakH) { normalH -= breakH; breakH = 0; } 
        else { breakH -= normalH; normalH = 0; }
      }
      if (breakH > 0 && ot1H > 0) {
        if (ot1H >= breakH) { ot1H -= breakH; breakH = 0; } 
        else { breakH -= ot1H; ot1H = 0; }
      }
      if (breakH > 0 && ot2H > 0) {
        if (ot2H >= breakH) { ot2H -= breakH; } 
        else { ot2H = 0; }
      }

      basePay = s.isFixedSalary ? (s.monthlyBaseSalary / s.payDaysPerMonth) : (normalH * baseHourlyRate);
      ot1Pay = ot1H * s.phase1Rate;
      ot2Pay = ot2H * s.phase2Rate;
    }

    return WageResult(
      normalHours: normalH.clamp(0, 24),
      overtimeHours1: ot1H.clamp(0, 24),
      overtimeHours2: ot2H.clamp(0, 24),
      basePay: basePay,
      overtimePay1: ot1Pay,
      overtimePay2: ot2Pay,
      totalPay: basePay + ot1Pay + ot2Pay,
    );
  }

  WageResult calculateMonth(List<WorkRecord> list) {
    double nH = 0, ot1H = 0, ot2H = 0, base = 0, ot1 = 0, ot2 = 0;
    double leaveDeduction = 0;
    final dailyPay = s.monthlyBaseSalary / s.payDaysPerMonth;

    for (final r in list) {
      final w = calculateDay(r);
      nH += w.normalHours;
      ot1H += w.overtimeHours1;
      ot2H += w.overtimeHours2;
      ot1 += w.overtimePay1;
      ot2 += w.overtimePay2;

      if (r.leaveType == 1) leaveDeduction += dailyPay * s.personalLeaveRatio;
      if (r.leaveType == 2) leaveDeduction += dailyPay * s.sickLeaveRatio;
    }

    if (s.isFixedSalary) {
      base = (s.monthlyBaseSalary - leaveDeduction).clamp(0, double.infinity);
    } else {
      base = nH * baseHourlyRate;
    }

    return WageResult(
      normalHours: nH,
      overtimeHours1: ot1H,
      overtimeHours2: ot2H,
      basePay: base,
      overtimePay1: ot1,
      overtimePay2: ot2,
      totalPay: base + ot1 + ot2,
    );
  }
}
