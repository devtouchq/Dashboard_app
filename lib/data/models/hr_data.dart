import 'package:equatable/equatable.dart';

class HrData extends Equatable {
  final int totalStaff;
  final int present;
  final int onLeave;
  final List<AttendancePoint> attendanceRate;
  final List<DepartmentSlice> staffByDepartment;

  const HrData({
    required this.totalStaff,
    required this.present,
    required this.onLeave,
    required this.attendanceRate,
    required this.staffByDepartment,
  });

  HrData copyWith({
    int? totalStaff,
    int? present,
    int? onLeave,
    List<AttendancePoint>? attendanceRate,
    List<DepartmentSlice>? staffByDepartment,
  }) {
    return HrData(
      totalStaff: totalStaff ?? this.totalStaff,
      present: present ?? this.present,
      onLeave: onLeave ?? this.onLeave,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      staffByDepartment: staffByDepartment ?? this.staffByDepartment,
    );
  }

  @override
  List<Object?> get props =>
      [totalStaff, present, onLeave, attendanceRate, staffByDepartment];
}

class AttendancePoint extends Equatable {
  final String month;
  final double presentPercent;
  final double absentPercent;

  const AttendancePoint({
    required this.month,
    required this.presentPercent,
    required this.absentPercent,
  });

  @override
  List<Object?> get props => [month, presentPercent, absentPercent];
}

class DepartmentSlice extends Equatable {
  final String label;
  final double percent;
  const DepartmentSlice({required this.label, required this.percent});
  @override
  List<Object?> get props => [label, percent];
}
