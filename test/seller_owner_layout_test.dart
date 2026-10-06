import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/umkm/data/models/inventory_model.dart';
import 'package:kopdes/features/umkm/data/models/order_item_model.dart';
import 'package:kopdes/features/umkm/data/models/order_model.dart';
import 'package:kopdes/features/umkm/presentation/widgets/seller_page_ui.dart';
import 'package:kopdes/shared/components/inventory_card.dart';
import 'package:kopdes/shared/components/order_card.dart';
import 'package:kopdes/shared/widgets/app_glass_chrome.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 320,
  double height = 900,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(backgroundColor: AppColors.surfaceSoft, body: child),
      ),
    ),
  );
  await tester.pump();
}

OrderModel _order({String status = 'READY_FOR_DELIVERY'}) => OrderModel(
  id: 'order-1234567890',
  customerId: 'customer-1',
  customer: const CustomerInfo(
    id: 'customer-1',
    name: 'Muhammad Abdurrahman Syahputra',
    email: 'pembeli@example.com',
    phone: '081234567890',
  ),
  totalAmount: 1250000,
  status: status,
  paymentMethod: 'TRANSFER',
  paymentStatus: 'PAID',
  deliveryAddress: const AddressInfo(
    recipientName: 'Muhammad Abdurrahman Syahputra',
    phone: '081234567890',
    street: 'Jalan Teuku Nyak Arief Nomor 123',
    city: 'Banda Aceh',
    state: 'Aceh',
    postalCode: '23115',
  ),
  items: const [
    OrderItemModel(
      id: 'item-1',
      orderId: 'order-1234567890',
      umkmProductId: 'product-1',
      quantity: 12,
      price: 125000,
    ),
  ],
  createdAt: DateTime(2026, 10, 3, 10, 30),
  courier: const CourierInfo(
    id: 'courier-1',
    name: 'Kurir Desa Lamteh',
    phone: '081200000000',
  ),
);

void main() {
  group('chrome halaman pemilik UMKM', () {
    for (final width in [320.0, 390.0, 768.0]) {
      testWidgets('aman pada lebar ${width.toInt()}dp', (tester) async {
        await _pump(
          tester,
          SellerPageChrome(
            title: 'Stok & Inventaris',
            subtitle: 'Jaga produk tetap siap dipesan oleh pelanggan desa',
            actions: const [
              GlassIconButton(
                icon: Icons.refresh_rounded,
                label: 'Perbarui data',
                onDark: true,
              ),
            ],
            body: const Center(child: Text('Konten')),
          ),
          width: width,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('header tetap aman pada skala teks 2x', (tester) async {
      await _pump(
        tester,
        const SellerPageChrome(
          title: 'Produk Toko',
          subtitle: 'Kelola etalase dan ketersediaan produk',
          body: Center(child: Text('Konten')),
        ),
        width: 320,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('kartu operasional UMKM', () {
    testWidgets('editor stok tidak meluber pada 320dp', (tester) async {
      await _pump(
        tester,
        InventoryCard(
          inventory: const InventoryModel(
            productId: 'p1',
            productName: 'Kopi Arabika Gayo Premium Kemasan 500 Gram',
            stock: 3,
            categoryName: 'Minuman Olahan',
          ),
          onUpdateStock: (_) {},
        ),
      );

      await tester.tap(find.text('Perbarui stok'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Simpan jumlah stok'), findsOneWidget);
    });

    testWidgets('pesanan dengan dua chat aman pada teks 1.5x', (tester) async {
      await _pump(
        tester,
        SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: OrderCard(
            order: _order(),
            onChatBuyer: () {},
            onChatCourier: () {},
            onUpdateStatus: (_) {},
            onTap: () {},
          ),
        ),
        textScale: 1.5,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Butuh Pengantaran'), findsOneWidget);
      expect(find.text('Chat Pembeli'), findsOneWidget);
      expect(find.text('Chat Kurir'), findsOneWidget);
    });

    testWidgets('pesanan diproses dapat mengajukan pengantaran', (
      tester,
    ) async {
      await _pump(
        tester,
        SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: OrderCard(
            order: _order(status: 'PROCESSING'),
            onUpdateStatus: (_) {},
            onTap: () {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Ajukan pengantaran'), findsOneWidget);
    });
  });
}
