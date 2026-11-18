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

  final String standardClockOut;
  final String phase1End;
  final double phase1Rate;
  final double phase2Rate;
  final double saturdayRate; // 周六时薪
  final double sundayRate;   // 周日时薪
  final double personalLeaveRatio;
  final double sickLeaveRatio;

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
    required this.saturdayRate,
    required this.sundayRate,
    required this.personalLeaveRatio,
    required this.sickLeaveRatio,
  });

  factory AppSettings.defaults() => AppSettings(
        monthlyBaseSalary: 0, isFixedSalary: true, payDaysPerMonth: 21.75, standardHoursPerDay: 8,
        remindTime: '09:00', autoFillEnabled: true, autoCheckTime: '23:00', fillClockInTime: '09:00', fillClockOutTime: '18:00',
        standardClockOut: '18:00', phase1End: '21:00', phase1Rate: 18, phase2Rate: 21,
        saturdayRate: 24, sundayRate: 26, personalLeaveRatio: 1.0, sickLeaveRatio: 0.4,
      );

  Map<String, dynamic> toMap() => {
        'id': 1, 'monthlyBaseSalary': monthlyBaseSalary, 'isFixedSalary': isFixedSalary ? 1 : 0,
        'payDaysPerMonth': payDaysPerMonth, 'standardHoursPerDay': standardHoursPerDay,
        'remindTime': remindTime, 'autoFillEnabled': autoFillEnabled ? 1 : 0, 'autoCheckTime': autoCheckTime,
        'fillClockInTime': fillClockInTime, 'fillClockOutTime': fillClockOutTime,
        'standardClockOut': standardClockOut, 'phase1End': phase1End, 'phase1Rate': phase1Rate, 'phase2Rate': phase2Rate,
        'saturdayRate': saturdayRate, 'sundayRate': sundayRate,
        'personalLeaveRatio': personalLeaveRatio, 'sickLeaveRatio': sickLeaveRatio,
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
        saturdayRate: (m['saturdayRate'] as num?)?.toDouble() ?? 24,
        sundayRate: (m['sundayRate'] as num?)?.toDouble() ?? 26,
        personalLeaveRatio: (m['personalLeaveRatio'] as num?)?.toDouble() ?? 1.0,
        sickLeaveRatio: (m['sickLeaveRatio'] as num?)?.toDouble() ?? 0.4,
      );
}
