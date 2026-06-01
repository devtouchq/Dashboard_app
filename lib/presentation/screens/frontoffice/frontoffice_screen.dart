import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/models/dashboard_data.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../widgets/dashboard_scaffold.dart';
import '../../widgets/stat_card.dart';

class FrontofficeScreen extends StatelessWidget {
  const FrontofficeScreen({super.key});

  static const _tag = 'FrontofficeScreen';

  @override
  Widget build(BuildContext context) {
    AppLogger.info(_tag, 'build()');
    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (a, b) =>
          a.data?.frontoffice != b.data?.frontoffice ||
          a.data?.currency != b.data?.currency,
      builder: (context, state) {
        final data = state.data?.frontoffice;
        final currency = state.data?.currency.defaultCurrency ?? 'INR';
        return DashboardScaffold(
          theme: SectionTheme.frontoffice,
          title: 'Front Office Dashboard',
          children: data == null
              ? [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                        child: CircularProgressIndicator(color: Colors.white)),
                  )
                ]
              : [_content(data, currency)],
        );
      },
    );
  }

  Widget _content(FrontofficeData data, String currency) {
    return Column(
      children: [
        StatCardRow(
          cards: [
            StatCard(
              icon: Icons.login_outlined,
              iconColor: DashboardColors.iconBlue,
              value: '${data.totalCheckIn.toInt()}',
              label: 'Total Check-in',
            ),
            StatCard(
              icon: Icons.people_outline,
              iconColor: DashboardColors.iconGreen,
              value: '${data.currentGuests.toInt()}',
              label: 'Current Guests',
            ),
            StatCard(
              icon: Icons.flight_land_outlined,
              iconColor: DashboardColors.iconAmber,
              value: '${data.expectedArrival.toInt()}',
              label: 'Expected Arrival',
            ),
          ],
        ),
        const Gap(12),
        StatCardRow(
          cards: [
            StatCard(
              //collection icon
              icon: Icons.collections_outlined,
              iconColor: DashboardColors.iconOrange,
              value: CurrencyUtils.format(data.totalCollection, currency),
              label: 'Total Collections',
            ),
            StatCard(
              icon: Icons.attach_money,
              iconColor: DashboardColors.iconTeal,
              value: CurrencyUtils.format(data.totalRevenue, currency),
              label: 'Revenue',
            ),
          ],
        ),
      ],
    );
  }
}
