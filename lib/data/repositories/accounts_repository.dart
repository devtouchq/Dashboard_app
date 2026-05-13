import '../../core/constants/string_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/accounts_data.dart';

class AccountsRepository {
  // ignore: unused_field
  final DioClient _client;

  AccountsRepository(this._client);

  Future<AccountsData> fetchDashboard() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const AccountsData(
      totalRevenue: 45230,
      expenses: 26000,
      netProfit: 19230,
      revenueTrendPercent: 12,
      expensesTrendPercent: 5,
      netProfitTrendPercent: 18,
      revenueVsExpenses: [
        MonthlyRevenuePoint(month: 'Jan', revenue: 22000, expenses: 15000),
        MonthlyRevenuePoint(month: 'Feb', revenue: 28000, expenses: 17000),
        MonthlyRevenuePoint(month: 'Mar', revenue: 32000, expenses: 20000),
        MonthlyRevenuePoint(month: 'Apr', revenue: 36000, expenses: 22000),
        MonthlyRevenuePoint(month: 'May', revenue: 41000, expenses: 24000),
        MonthlyRevenuePoint(month: 'Jun', revenue: 45000, expenses: 26000),
      ],
      expenseBreakdown: [
        ExpenseSlice(label: StringConstants.salaries, amount: 15000),
        ExpenseSlice(label: StringConstants.supplies, amount: 6000),
        ExpenseSlice(label: StringConstants.utilities, amount: 3000),
        ExpenseSlice(label: StringConstants.other, amount: 2000),
      ],
    );
  }
}
