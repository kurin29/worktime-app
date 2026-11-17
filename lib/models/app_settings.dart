class AppSettings {
  final double monthlyBaseSalary;
  final bool isFixedSalary;
  final double payDaysPerMonth;
  final double standardHoursPerDay;
  final double overtimeHourlyRate;
  final String remindTime;
  final bool autoFillEnabled;
  final String autoCheckTime;
  final String fillClockInTime;
  final String fillClockOutTime;

  AppSettings({
    required this.monthlyBaseSalary,
    required this.isFixedSalary,
    required this.payDaysPerMonth,
    required this.standardHoursPerDay,
    required this.overtimeHourlyRate,
    required this.remindTime,
    required this.autoFillEnabled,
    required this.autoCheckTime,
    required this.fillClockInTime,
    required this.fillClockOutTime,
  });

  factory AppSettings.defaults() => AppSettings(
        monthlyBaseSalary: 0,
        isFixedSalary: true,
        payDaysPerMonth: 21.75,
        standardHoursPerDay: 8,
        overtimeHourlyRate: 0,
        remindTime: '09:00',
        autoFillEnabled: true,
        autoCheckTime: '23:00',
        fillClockInTime: '09:00',
        fillClockOutTime: '18:00',
      );

  Map<String, dynamic> toMap() => {
        'id': 1,
        'monthlyBaseSalary': monthlyBaseSalary,
        'isFixedSalary': isFixedSalary ? 1 : 0,
        'payDaysPerMonth': payDaysPerMonth,
        'standardHoursPerDay': standardHoursPerDay,
        'overtimeHourlyRate': overtimeHourlyRate,
        'remindTime': remindTime,
        'autoFillEnabled': autoFillEnabled ? 1 : 0,
        'autoCheckTime': autoCheckTime,
        'fillClockInTime': fillClockInTime,
        'fillClockOutTime': fillClockOutTime,
      };

  factory AppSettings.fromMap(Map<String, dynamic> m) => AppSettings(
        monthlyBaseSalary: (m['monthlyBaseSalary'] as num?)?.toDouble() ?? 0,
        isFixedSalary: (m['isFixedSalary'] as int? ?? 1) == 1,
        payDaysPerMonth: (m['payDaysPerMonth'] as num?)?.toDouble() ?? 21.75,
        standardHoursPerDay:
            (m['standardHoursPerDay'] as num?)?.toDouble() ?? 8,
        overtimeHourlyRate:
            (m['overtimeHourlyRate'] as num?)?.toDouble() ?? 0,
        remindTime: m['remindTime'] as String? ?? '09:00',
        autoFillEnabled: (m['autoFillEnabled'] as int? ?? 1) == 1,
        autoCheckTime: m['autoCheckTime'] as String? ?? '23:00',
        fillClockInTime: m['fillClockInTime'] as String? ?? '09:00',
        fillClockOutTime: m['fillClockOutTime'] as String? ?? '18:00',
      );
}
