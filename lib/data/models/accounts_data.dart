import 'package:equatable/equatable.dart';

class CashFlowPoint extends Equatable {
  final String label;
  final double receipts;
  final double payments;

  const CashFlowPoint({
    required this.label,
    required this.receipts,
    required this.payments,
  });

  CashFlowPoint copyWith({String? label, double? receipts, double? payments}) {
    return CashFlowPoint(
      label: label ?? this.label,
      receipts: receipts ?? this.receipts,
      payments: payments ?? this.payments,
    );
  }

  @override
  List<Object?> get props => [label, receipts, payments];
}

class CollectionSlice extends Equatable {
  final String mode; // Cheque, Cash, UPI
  final double percent;

  const CollectionSlice({required this.mode, required this.percent});

  CollectionSlice copyWith({String? mode, double? percent}) {
    return CollectionSlice(
      mode: mode ?? this.mode,
      percent: percent ?? this.percent,
    );
  }

  @override
  List<Object?> get props => [mode, percent];
}

class AccountsData extends Equatable {
  final double netPosition;
  final double debiters;
  final double crediters;
  final List<CashFlowPoint> cashFlow;
  final int checkIn;
  final int currentGuests;
  final int expected;
  final int checkOut;
  final double totalCollection;
  final List<CollectionSlice> collectionSlices;

  const AccountsData({
    required this.netPosition,
    required this.debiters,
    required this.crediters,
    required this.cashFlow,
    required this.checkIn,
    required this.currentGuests,
    required this.expected,
    required this.checkOut,
    required this.totalCollection,
    required this.collectionSlices,
  });

  AccountsData copyWith({
    double? netPosition,
    double? debiters,
    double? crediters,
    List<CashFlowPoint>? cashFlow,
    int? checkIn,
    int? currentGuests,
    int? expected,
    int? checkOut,
    double? totalCollection,
    List<CollectionSlice>? collectionSlices,
  }) {
    return AccountsData(
      netPosition: netPosition ?? this.netPosition,
      debiters: debiters ?? this.debiters,
      crediters: crediters ?? this.crediters,
      cashFlow: cashFlow ?? this.cashFlow,
      checkIn: checkIn ?? this.checkIn,
      currentGuests: currentGuests ?? this.currentGuests,
      expected: expected ?? this.expected,
      checkOut: checkOut ?? this.checkOut,
      totalCollection: totalCollection ?? this.totalCollection,
      collectionSlices: collectionSlices ?? this.collectionSlices,
    );
  }

  @override
  List<Object?> get props => [
        netPosition,
        debiters,
        crediters,
        cashFlow,
        checkIn,
        currentGuests,
        expected,
        checkOut,
        totalCollection,
        collectionSlices,
      ];
}
