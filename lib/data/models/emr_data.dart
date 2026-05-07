import 'package:equatable/equatable.dart';

class PatientFlowItem extends Equatable {
  final String label; // Total, IP, OP, New, Repeat
  final int value;

  const PatientFlowItem({required this.label, required this.value});

  PatientFlowItem copyWith({String? label, int? value}) {
    return PatientFlowItem(
      label: label ?? this.label,
      value: value ?? this.value,
    );
  }

  @override
  List<Object?> get props => [label, value];
}

class EmrData extends Equatable {
  final int currentPatients;
  final int totalPatients;
  final int registration;
  final int consultation;
  final int bedsOccupied;
  final int malePatients;
  final int femalePatients;
  final int ipPatients;
  final int opPatients;
  final int newPatients;
  final int repeaterPatients;
  final List<PatientFlowItem> patientFlow;

  const EmrData({
    required this.currentPatients,
    required this.totalPatients,
    required this.registration,
    required this.consultation,
    required this.bedsOccupied,
    required this.malePatients,
    required this.femalePatients,
    required this.ipPatients,
    required this.opPatients,
    required this.newPatients,
    required this.repeaterPatients,
    required this.patientFlow,
  });

  EmrData copyWith({
    int? currentPatients,
    int? totalPatients,
    int? registration,
    int? consultation,
    int? bedsOccupied,
    int? malePatients,
    int? femalePatients,
    int? ipPatients,
    int? opPatients,
    int? newPatients,
    int? repeaterPatients,
    List<PatientFlowItem>? patientFlow,
  }) {
    return EmrData(
      currentPatients: currentPatients ?? this.currentPatients,
      totalPatients: totalPatients ?? this.totalPatients,
      registration: registration ?? this.registration,
      consultation: consultation ?? this.consultation,
      bedsOccupied: bedsOccupied ?? this.bedsOccupied,
      malePatients: malePatients ?? this.malePatients,
      femalePatients: femalePatients ?? this.femalePatients,
      ipPatients: ipPatients ?? this.ipPatients,
      opPatients: opPatients ?? this.opPatients,
      newPatients: newPatients ?? this.newPatients,
      repeaterPatients: repeaterPatients ?? this.repeaterPatients,
      patientFlow: patientFlow ?? this.patientFlow,
    );
  }

  @override
  List<Object?> get props => [
        currentPatients,
        totalPatients,
        registration,
        consultation,
        bedsOccupied,
        malePatients,
        femalePatients,
        ipPatients,
        opPatients,
        newPatients,
        repeaterPatients,
        patientFlow,
      ];
}
