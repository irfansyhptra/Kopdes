import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/admin/presentation/widgets/admin_ui.dart';
import 'package:kopdes/shared/widgets/apple_ui.dart';

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required double textScale,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          backgroundColor: AppColors.surfaceSoft,
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: AppleResponsiveGrid(
              minimumItemWidth: 128,
              maxColumns: 4,
              itemExtentBuilder: (context, _) {
                final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
                return 128 + 64 * (scale.clamp(1.0, 2.0) - 1);
              },
              children: const [
                AdminStatCard(
                  title: 'Barang Ritel Aktif',
                  value: '12.450',
                  subtitle: '12.000 produk sedang aktif',
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.primary,
                ),
                AdminStatCard(
                  title: 'Omzet Koperasi',
                  value: 'Rp987.654.321',
                  subtitle: 'Total akumulasi pesanan',
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.primaryActive,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('grid admin tidak meluber pada ${width.toInt()}dp', (
      tester,
    ) async {
      await _pump(tester, width: width, textScale: 1);
      expect(tester.takeException(), isNull);
    });
  }

  for (final scale in [1.3, 1.5, 2.0]) {
    testWidgets('grid admin aman pada teks ${scale}x', (tester) async {
      await _pump(tester, width: 320, textScale: scale);
      expect(tester.takeException(), isNull);
    });
  }
}
