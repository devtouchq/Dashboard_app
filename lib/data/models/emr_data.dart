import 'package:equatable/equatable.dart';

class EmrData extends Equatable {
  final int totalPatients;
  final int appointments;
  final int activeCases;
  final List<MonthlyGrowthPoint> monthlyGrowth;
  final int outpatientCount;
  final int inpatientCount;
  final int emergencyCount;

  const EmrData({
    required this.totalPatients,
    required this.appointments,
    required this.activeCases,
    required this.monthlyGrowth,
    required this.outpatientCount,
    required this.inpatientCount,
    required this.emergencyCount,
  });

  EmrData copyWith({
    int? totalPatients,
    int? appointments,
    int? activeCases,
    List<MonthlyGrowthPoint>? monthlyGrowth,
    int? outpatientCount,
    int? inpatientCount,
    int? emergencyCount,
  }) {
    return EmrData(
      totalPatients: totalPatients ?? this.totalPatients,
      appointments: appointments ?? this.appointments,
      activeCases: activeCases ?? this.activeCases,
      monthlyGrowth: monthlyGrowth ?? this.monthlyGrowth,
      outpatientCount: outpatientCount ?? this.outpatientCount,
      inpatientCount: inpatientCount ?? this.inpatientCount,
      emergencyCount: emergencyCount ?? this.emergencyCount,
    );
  }

  @override
  List<Object?> get props => [
        totalPatients,
        appointments,
        activeCases,
        monthlyGrowth,
        outpatientCount,
        inpatientCount,
        emergencyCount,
      ];
}

class MonthlyGrowthPoint extends Equatable {
  final String month;
  final int patients;

  const MonthlyGrowthPoint({required this.month, required this.patients});

  @override
  List<Object?> get props => [month, patients];
}
