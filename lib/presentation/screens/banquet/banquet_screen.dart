import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/currency_utils.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../../widgets/stat_card.dart';

class BanquetScreen extends StatelessWidget {
  const BanquetScreen({super.key});

  static const _tag = 'BanquetScreen';

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (a, b) =>
          a.data?.banquet != b.data?.banquet ||
          a.data?.currency != b.data?.currency,
      builder: (context, state) {
        final data = state.data?.banquet;
        final currency = state.data?.currency.defaultCurrency ?? 'INR';
        return DashboardScaffold(
          theme: SectionTheme.banquet,
          title: 'Banquet Dashboard',
          children: data == null
              ? [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                        child: CircularProgressIndicator(color: Colors.white)),
                  )
                ]
              : [
                  StatCardRow(
                    cards: [
                      StatCard(
                        icon: Icons.event_outlined,
                        iconColor: DashboardColors.iconPink,
                        value: '${data.totalFunctions.toInt()}',
                        label: 'Functions',
                      ),
                      StatCard(
                        icon: Icons.book_online_outlined,
                        iconColor: DashboardColors.iconPurple,
                        value: '${data.totalReservations.toInt()}',
                        label: 'Reservations',
                      ),
                    ],
                  ),
                  const Gap(35),
                  StatCardRow(
                    cards: [
                      StatCard(
                        icon: Icons.money_off_outlined,
                        iconColor: DashboardColors.iconGreen,
                        value: CurrencyUtils.format(
                            data.totalCollection, currency),
                        label: 'Collections',
                      ),
                      StatCard(
                        icon: Icons.attach_money,
                        iconColor: DashboardColors.iconGreen,
                        value:
                            CurrencyUtils.format(data.totalRevenue, currency),
                        label: 'Revenue',
                      ),
                    ],
                  ),
                ],
        );
      },
    );
  }
}
