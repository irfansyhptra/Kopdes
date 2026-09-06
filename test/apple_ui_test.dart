import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/shared/widgets/apple_ui.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  // Regresi: indikator overscroll Android meregangkan piksel teratas — di
  // Beranda & Marketplace itu gradien merah header, yang tampak sebagai
  // kilatan merah saat halaman ditarik ke paling atas.
  testWidgets('AppScrollBehavior tidak memasang indikator overscroll', (
    tester,
  ) async {
    const behavior = AppScrollBehavior();
    late Widget wrapped;
    const marker = SizedBox.shrink();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            wrapped = behavior.buildOverscrollIndicator(
              context,
              marker,
              const ScrollableDetails(direction: AxisDirection.down),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(identical(wrapped, marker), isTrue);
  });

  group('formatRupiah', () {
    test('memberi pemisah ribuan dan tidak menampilkan desimal', () {
      expect(formatRupiah(0), 'Rp0');
      expect(formatRupiah(999), 'Rp999');
      expect(formatRupiah(1000), 'Rp1.000');
      expect(formatRupiah(64000), 'Rp64.000');
      expect(formatRupiah(1234567), 'Rp1.234.567');
      expect(formatRupiah(15500.4), 'Rp15.500');
    });
  });

  testWidgets('AppleListGroup menyisipkan n-1 separator', (tester) async {
    await tester.pumpWidget(
      _wrap(const AppleListGroup(children: [Text('a'), Text('b'), Text('c')])),
    );
    expect(find.byType(Divider), findsNWidgets(2));

    await tester.pumpWidget(_wrap(const AppleListGroup(children: [Text('a')])));
    expect(find.byType(Divider), findsNothing);

    await tester.pumpWidget(_wrap(const AppleListGroup(children: [])));
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('AppleAddButton nonaktif saat onTap null', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(AppleAddButton(onTap: () => taps++)));
    await tester.tap(find.byType(AppleAddButton));
    expect(taps, 1);

    await tester.pumpWidget(_wrap(const AppleAddButton()));
    await tester.tap(find.byType(AppleAddButton), warnIfMissed: false);
    expect(taps, 1); // tetap 1: tombol mati tidak memicu apa pun
  });

  testWidgets('AppleProductTile menampilkan harga coret & badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 180,
          height: 280,
          child: AppleProductTile(
            imageUrl: '',
            title: 'Beras Premium',
            price: 'Rp64.000',
            originalPrice: 'Rp80.000',
            badge: '-20%',
          ),
        ),
      ),
    );
    expect(find.text('Beras Premium'), findsOneWidget);
    expect(find.text('Rp64.000'), findsOneWidget);
    expect(find.text('-20%'), findsOneWidget);

    final struck = tester.widget<Text>(find.text('Rp80.000'));
    expect(struck.style?.decoration, TextDecoration.lineThrough);
  });
}
