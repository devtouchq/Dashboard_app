import '../../core/network/dio_client.dart';
import '../models/accounts_data.dart';

class AccountsRepository {
  final DioClient _client;

  AccountsRepository(this._client);

  Future<AccountsData> fetchAccounts() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return const AccountsData(
      netPosition: 60400000,
      debiters: 61232078,
      crediters: -6817071,
      cashFlow: [
        CashFlowPoint(label: '9AM', receipts: 200, payments: 100),
        CashFlowPoint(label: '11AM', receipts: 380, payments: 160),
        CashFlowPoint(label: '1PM', receipts: 320, payments: 220),
        CashFlowPoint(label: '3PM', receipts: 540, payments: 180),
        CashFlowPoint(label: '5PM', receipts: 460, payments: 280),
        CashFlowPoint(label: '7PM', receipts: 720, payments: 220),
        CashFlowPoint(label: '9PM', receipts: 600, payments: 320),
      ],
      checkIn: 117,
      currentGuests: 0,
      expected: 0,
      checkOut: 0,
      totalCollection: 2227,
      collectionSlices: [
        CollectionSlice(mode: 'Cheque', percent: 100),
        CollectionSlice(mode: 'Cash', percent: 0),
        CollectionSlice(mode: 'UPI', percent: 0),
      ],
    );
  }
}
