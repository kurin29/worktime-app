import '../models/app_settings.dart';
import '../models/work_record.dart';

class WageResult {
  final double normalHours, overtimeHours, basePay, overtimePay, totalPay;
  WageResult({
    required this.normalHours,
    required this.overtimeHours,
    required this.basePay,
    required this.overtimePay,
    required this.totalPay,
  });
  static WageResult zero() => WageResult(
      normalHours: 0, overtimeHours: 0, basePay: 0, overtimePay: 0, totalPay: 0);
}

class WageCalculator {
  final AppSettings s;
  WageCalculator(this.s);

  double get baseHourlyRate {
    if (s.payDaysPerMonth <= 0 || s.standardHoursPerDay <= 0) return 0;
    return s.monthlyBaseSalary / s.payDaysPerMonth / s.standardHoursPerDay;
  }

  double get overtimeRate =>
      s.overtimeHourlyRate > 0 ? s.overtimeHourlyRate : baseHourlyRate;

  WageResult calculateDay(WorkRecord? r) {
    if (r == null || (r.clockIn == null && r.clockOut == null)) {
      return WageResult.zero();
    }
    final base = s.isFixedSalary
        ? s.monthlyBaseSalary / s.payDaysPerMonth
        : r.normalHours * baseHourlyRate;
    final ot = r.overtimeHours * overtimeRate;
    return WageResult(
      normalHours: r.normalHours,
      overtimeHours: r.overtimeHours,
      basePay: base,
      overtimePay: ot,
      totalPay: base + ot,
    );
  }

  WageResult calculateMonth(List<WorkRecord> list) {
    final nH = list.fold<double>(0, (a, e) => a + e.normalHours);
    final oH = list.fold<double>(0, (a, e) => a + e.overtimeHours);
    final base = s.isFixedSalary ? s.monthlyBaseSalary : nH * baseHourlyRate;
    final ot = oH * overtimeRate;
    return WageResult(
        normalHours: nH,
        overtimeHours: oH,
        basePay: base,
        overtimePay: ot,
        totalPay: base + ot);
  }
}
