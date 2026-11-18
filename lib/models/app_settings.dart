class AppSettings {
  final double monthlyBaseSalary;
  final bool isFixedSalary;
  final double payDaysPerMonth;
  final double standardHoursPerDay;
  final String remindTime;
  final bool autoFillEnabled;
  final String autoCheckTime;
  final String fillClockInTime;
  final String fillClockOutTime;

  // 新增：加班与请假配置
  final String standardClockOut; // 正常下班时间，如 18:00
  final String phase1End;        // 第一段加班结束，如 21:00
  final double phase1Rate;       // 第一段时薪
  final double phase2Rate;       // 第二段时薪
  final double weekendRate;      // 周末加班时薪
  final double personalLeaveRatio; // 事假扣款比例（1.0为全额扣）
  final double sickLeaveRatio;     // 病假扣款比例（如0.4为扣40%）

  AppSettings({
    required this.monthlyBaseSalary,
    required this.isFixedSalary,
    required this.payDaysPerMonth,
    required this.standardHoursPerDay,
    required this.remindTime,
    required this.autoFillEnabled,
    required this.autoCheckTime,
    required this.fillClockInTime,
    required this.fillClockOutTime,
    required this.standardClockOut,
    required this.phase1End,
    required this.phase1Rate,
    required this.phase2Rate,
    required this.weekendRate,
    required this.personalLeaveRatio,
    required this.sickLeaveRatio,
  });

  factory AppSettings.defaults() => AppSettings(
        monthlyBaseSalary: 0,
        isFixedSalary: true,
        payDaysPerMonth: 21.75,
        standardHoursPerDay: 8,
        remindTime: '09:00',
        autoFillEnabled: true,
        autoCheckTime: '23:00',
        fillClockInTime: '09:00',
        fillClockOutTime: '18:00',
        standardClockOut: '18:00',
        phase1End: '21:00',
        phase1Rate: 18,
        phase2Rate: 21,
        weekendRate: 24,
        personalLeaveRatio: 1.0,
        sickLeaveRatio: 0.4,
      );

  Map<String, dynamic> toMap() => {
        'id': 1,
        'monthlyBaseSalary': monthlyBaseSalary,
        'isFixedSalary': isFixedSalary ? 1 : 0,
        'payDaysPerMonth': payDaysPerMonth,
        'standardHoursPerDay': standardHoursPerDay,
        'remindTime': remindTime,
        'autoFillEnabled': autoFillEnabled ? 1 : 0,
        'autoCheckTime': autoCheckTime,
        'fillClockInTime': fillClockInTime,
        'fillClockOutTime': fillClockOutTime,
        'standardClockOut': standardClockOut,
        'phase1End': phase1End,
        'phase1Rate': phase1Rate,
        'phase2Rate': phase2Rate,
        'weekendRate': weekendRate,
        'personalLeaveRatio': personalLeaveRatio,
        'sickLeaveRatio': sickLeaveRatio,
      };

  factory AppSettings.fromMap(Map<String, dynamic> m) => AppSettings(
        monthlyBaseSalary: (m['monthlyBaseSalary'] as num?)?.toDouble() ?? 0,
        isFixedSalary: (m['isFixedSalary'] as int? ?? 1) == 1,
        payDaysPerMonth: (m['payDaysPerMonth'] as num?)?.toDouble() ?? 21.75,
        standardHoursPerDay: (m['standardHoursPerDay'] as num?)?.toDouble() ?? 8,
        remindTime: m['remindTime'] as String? ?? '09:00',
        autoFillEnabled: (m['autoFillEnabled'] as int? ?? 1) == 1,
        autoCheckTime: m['autoCheckTime'] as String? ?? '23:00',
        fillClockInTime: m['fillClockInTime'] as String? ?? '09:00',
        fillClockOutTime: m['fillClockOutTime'] as String? ?? '18:00',
        standardClockOut: m['standardClockOut'] as String? ?? '18:00',
        phase1End: m['phase1End'] as String? ?? '21:00',
        phase1Rate: (m['phase1Rate'] as num?)?.toDouble() ?? 18,
        phase2Rate: (m['phase2Rate'] as num?)?.toDouble() ?? 21,
        weekendRate: (m['weekendRate'] as num?)?.toDouble() ?? 24,
        personalLeaveRatio: (m['personalLeaveRatio'] as num?)?.toDouble() ?? 1.0,
        sickLeaveRatio: (m['sickLeaveRatio'] as num?)?.toDouble() ?? 0.4,
      );
}
