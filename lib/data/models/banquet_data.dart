import 'package:equatable/equatable.dart';

class BanquetData extends Equatable {
  final int totalEvents;
  final int thisMonth;
  final double revenue;
  final List<MonthlyRevenuePoint> revenueTrend;
  final List<EventTypeItem> eventsByType;

  const BanquetData({
    required this.totalEvents,
    required this.thisMonth,
    required this.revenue,
    required this.revenueTrend,
    required this.eventsByType,
  });

  BanquetData copyWith({
    int? totalEvents,
    int? thisMonth,
    double? revenue,
    List<MonthlyRevenuePoint>? revenueTrend,
    List<EventTypeItem>? eventsByType,
  }) {
    return BanquetData(
      totalEvents: totalEvents ?? this.totalEvents,
      thisMonth: thisMonth ?? this.thisMonth,
      revenue: revenue ?? this.revenue,
      revenueTrend: revenueTrend ?? this.revenueTrend,
      eventsByType: eventsByType ?? this.eventsByType,
    );
  }

  @override
  List<Object?> get props =>
      [totalEvents, thisMonth, revenue, revenueTrend, eventsByType];
}

class MonthlyRevenuePoint extends Equatable {
  final String month;
  final double revenue;
  const MonthlyRevenuePoint({required this.month, required this.revenue});
  @override
  List<Object?> get props => [month, revenue];
}

class EventTypeItem extends Equatable {
  final String type;
  final int count;
  const EventTypeItem({required this.type, required this.count});
  @override
  List<Object?> get props => [type, count];
}
