import 'package:equatable/equatable.dart';

class FrontofficeData extends Equatable {
  final int checkIns;
  final int inQueue;
  final int completed;
  final List<HourlyTrafficPoint> hourlyTraffic;
  final List<InquiryTypeItem> inquiriesByType;

  const FrontofficeData({
    required this.checkIns,
    required this.inQueue,
    required this.completed,
    required this.hourlyTraffic,
    required this.inquiriesByType,
  });

  FrontofficeData copyWith({
    int? checkIns,
    int? inQueue,
    int? completed,
    List<HourlyTrafficPoint>? hourlyTraffic,
    List<InquiryTypeItem>? inquiriesByType,
  }) {
    return FrontofficeData(
      checkIns: checkIns ?? this.checkIns,
      inQueue: inQueue ?? this.inQueue,
      completed: completed ?? this.completed,
      hourlyTraffic: hourlyTraffic ?? this.hourlyTraffic,
      inquiriesByType: inquiriesByType ?? this.inquiriesByType,
    );
  }

  @override
  List<Object?> get props =>
      [checkIns, inQueue, completed, hourlyTraffic, inquiriesByType];
}

class HourlyTrafficPoint extends Equatable {
  final String hour;
  final int visitors;
  const HourlyTrafficPoint({required this.hour, required this.visitors});
  @override
  List<Object?> get props => [hour, visitors];
}

class InquiryTypeItem extends Equatable {
  final String type;
  final int count;
  const InquiryTypeItem({required this.type, required this.count});
  @override
  List<Object?> get props => [type, count];
}
