# Roboto + KStyles + Gap update

## Step 1 — Add the fonts

1. Create folder `assets/fonts/` at your project root.
2. Drop all six `Roboto-*.ttf` files from this zip's `fonts/` folder into `assets/fonts/`.
3. Replace `pubspec.yaml` at the project root with the one in this zip.
4. Run `flutter pub get`.

Note: `google_fonts` is removed — Roboto is now bundled locally.

## Step 2 — File placements

| File in zip | Destination in project |
|---|---|
| `constants/string_constants.dart` | `lib/core/constants/string_constants.dart` |
| `constants/font_styles.dart`       | `lib/core/constants/font_styles.dart` (new) |
| `constants/text_styles.dart`       | `lib/core/constants/text_styles.dart` (new) |
| `constants/dimensions.dart`        | `lib/core/constants/dimensions.dart` |
| `theme/app_theme.dart`             | `lib/core/theme/app_theme.dart` |
| `widgets/section_header.dart`      | `lib/presentation/widgets/section_header.dart` |
| `widgets/legend_dot.dart`          | `lib/presentation/widgets/legend_dot.dart` |
| `widgets/app_card.dart`            | `lib/presentation/widgets/app_card.dart` |
| `widgets/metric_card.dart`         | `lib/presentation/widgets/metric_card.dart` |
| `widgets/dashboard_app_bar.dart`   | `lib/presentation/widgets/dashboard_app_bar.dart` |
| `widgets/dashboard_bottom_nav.dart`| `lib/presentation/widgets/dashboard_bottom_nav.dart` |
| `widgets/safe_chart_wrapper.dart`  | `lib/presentation/widgets/safe_chart_wrapper.dart` |
| `charts/stacked_area_chart.dart`   | `lib/presentation/widgets/charts/stacked_area_chart.dart` |
| `charts/patient_flow_chart.dart`   | `lib/presentation/widgets/charts/patient_flow_chart.dart` |
| `charts/receipts_payments_chart.dart` | `lib/presentation/widgets/charts/receipts_payments_chart.dart` |
| `charts/donut_chart.dart`          | `lib/presentation/widgets/charts/donut_chart.dart` |
| `charts/category_distribution_bar.dart` | `lib/presentation/widgets/charts/category_distribution_bar.dart` |

## Step 3 — Inside the screens

I haven't regenerated the four screen files (home/emr/accounts/store) here because the diff is mechanical and you can do it in 5 minutes per screen. Two find-and-replace patterns:

### Replace SizedBox spacers with Gap

```dart
// before
const SizedBox(height: 8),
const SizedBox(width: 14),

// after
import 'package:gap/gap.dart';
const Gap(8),
const Gap(14),
```

`Gap` auto-detects whether it's inside a Row or Column. Keep `SizedBox(width: 80, height: 80)` etc. — those are sizing, not spacing.

### Replace Text widgets with KStyles

```dart
// before
const Text(
  'Welcome back',
  style: TextStyle(fontSize: 11, color: AppColors.textLabel),
),

// after
KStyles().reg(
  text: 'Welcome back',
  size: 11,
  color: AppColors.textLabel,
),
```

Pick the right method based on the original `fontWeight`:

| Original `fontWeight` | KStyles method |
|---|---|
| `w300`               | `KStyles().light(...)` |
| `w400` (default)     | `KStyles().reg(...)` |
| `w500`               | `KStyles().med(...)` |
| `w600`               | `KStyles().semiBold(...)` |
| `w700`               | `KStyles().bold(...)` |
| `w800`               | `KStyles().black(...)` |

Add `import '../../../core/constants/text_styles.dart';` at the top of each screen.
