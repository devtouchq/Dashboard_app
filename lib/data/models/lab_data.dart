import 'package:equatable/equatable.dart';

class LabData extends Equatable {
  final int totalTests;
  final int pending;
  final int completed;
  final List<MonthlyTestPoint> monthlyTests;
  final List<TestTypeItem> testsByType;

  const LabData({
    required this.totalTests,
    required this.pending,
    required this.completed,
    required this.monthlyTests,
    required this.testsByType,
  });

  LabData copyWith({
    int? totalTests,
    int? pending,
    int? completed,
    List<MonthlyTestPoint>? monthlyTests,
    List<TestTypeItem>? testsByType,
  }) {
    return LabData(
      totalTests: totalTests ?? this.totalTests,
      pending: pending ?? this.pending,
      completed: completed ?? this.completed,
      monthlyTests: monthlyTests ?? this.monthlyTests,
      testsByType: testsByType ?? this.testsByType,
    );
  }

  @override
  List<Object?> get props =>
      [totalTests, pending, completed, monthlyTests, testsByType];
}

class MonthlyTestPoint extends Equatable {
  final String month;
  final int count;

  const MonthlyTestPoint({required this.month, required this.count});

  @override
  List<Object?> get props => [month, count];
}

class TestTypeItem extends Equatable {
  final String type;
  final int count;

  const TestTypeItem({required this.type, required this.count});

  @override
  List<Object?> get props => [type, count];
}
