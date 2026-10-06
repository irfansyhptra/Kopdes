import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/features/umkm/data/models/order_model.dart';
import 'package:kopdes/shared/components/order_card.dart';

Map<String, dynamic> _json({
  String status = 'READY_FOR_DELIVERY',
  String fulfillment = 'DELIVERY',
  bool withCustomer = true,
  bool withAddress = true,
  Map<String, dynamic>? delivery,
}) => {
  'id': 'order-12345678',
  'customerId': 'cust-1',
  if (withCustomer)
    'customer': {
      'id': 'cust-1',
      'name': 'Nuraini binti Abdullah Saputra',
      'email': 'nur@contoh.id',
      'phone': '0811',
    },
  'totalAmount': 185000,
  'status': status,
  'paymentMethod': 'COD',
  'paymentStatus': 'PENDING',
  'fulfillment': fulfillment,
  if (withAddress)
    'deliveryAddress': {
      'recipientName': 'Nuraini',
      'phone': '0811',
      'street': 'Jl. Lamgugop No. 14',
      'city': 'Banda Aceh',
      'state': 'Aceh',
      'postalCode': '23115',
    },
  if (delivery != null) 'delivery': delivery,
  'items': [
    {
      'id': 'item-1',
      'quantity': 2,
      'price': 92500,
      'umkmProduct': {
        'id': 'p-1',
        'name': 'Mie Aceh Goreng',
        'categoryId': 'cat-1',
        'price': 92500,
        'stock': 12,
      },
    },
  ],
  'createdAt': '2026-10-06T01:00:00.000Z',
};

Widget _host(OrderModel order, {double width = 390, double scale = 1.0}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 900),
          textScaler: TextScaler.linear(scale),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: width,
              child: OrderCard(order: order, onUpdateStatus: (_) {}),
            ),
          ),
        ),
      ),
    );

void main() {
  group('OrderModel.fromJson', () {
    test('tidak melempar saat pembeli dan alamat tidak dikirim', () {
      // Respons ubah-status dulu hanya berisi kolom Order; cast di model
      // melempar, dan penjual UMKM melihat "gagal" padahal statusnya sudah
      // tersimpan — pesanan COD-nya macet di situ.
      final order = OrderModel.fromJson(
        _json(withCustomer: false, withAddress: false),
      );
      expect(order.customer.name, '');
      expect(order.deliveryAddress.street, '');
      expect(order.status, 'READY_FOR_DELIVERY');
    });

    test('membaca fulfillment dan status pengantaran', () {
      final order = OrderModel.fromJson(
        _json(fulfillment: 'PICKUP', delivery: {'status': 'ASSIGNED'}),
      );
      expect(order.fulfillment, 'PICKUP');
      expect(order.deliveryStatus, 'ASSIGNED');
    });

    test('fulfillment default DELIVERY bila tidak dikirim', () {
      final json = _json()..remove('fulfillment');
      expect(OrderModel.fromJson(json).fulfillment, 'DELIVERY');
    });
  });

  group('OrderCard', () {
    testWidgets('pesanan antar menunggu kurir Kopdes, bukan ditugaskan toko', (
      tester,
    ) async {
      await tester.pumpWidget(_host(OrderModel.fromJson(_json())));
      expect(find.textContaining('Menunggu kurir Kopdes'), findsOneWidget);
      expect(find.text('Butuh Pengantaran'), findsOneWidget);
    });

    testWidgets('kurir yang sudah mengambil disebut namanya', (tester) async {
      final order = OrderModel.fromJson(
        _json(
          delivery: {
            'status': 'ASSIGNED',
            'courier': {'id': 'k-1', 'name': 'Rizal', 'phone': '0812'},
          },
        ),
      );
      await tester.pumpWidget(_host(order));
      expect(find.textContaining('Diambil kurir Rizal'), findsOneWidget);
      expect(find.textContaining('Menunggu kurir'), findsNothing);
    });

    testWidgets('pesanan ambil-sendiri tidak menyebut kurir sama sekali', (
      tester,
    ) async {
      final order = OrderModel.fromJson(
        _json(status: 'PROCESSING', fulfillment: 'PICKUP'),
      );
      await tester.pumpWidget(_host(order));
      expect(find.text('Tandai siap diambil'), findsOneWidget);
      expect(find.textContaining('kurir'), findsNothing);
    });

    testWidgets('alamat kosong tidak meninggalkan baris ", "', (tester) async {
      final order = OrderModel.fromJson(
        _json(fulfillment: 'PICKUP', withAddress: false),
      );
      await tester.pumpWidget(_host(order));
      expect(find.text(', '), findsNothing);
      expect(find.byIcon(Icons.location_on_outlined), findsNothing);
    });

    testWidgets('tidak luber pada 320–768dp dan skala teks 1,0–2,0×', (
      tester,
    ) async {
      for (final width in [320.0, 360.0, 414.0, 768.0]) {
        for (final scale in [1.0, 1.5, 2.0]) {
          await tester.pumpWidget(
            _host(OrderModel.fromJson(_json()), width: width, scale: scale),
          );
          expect(
            tester.takeException(),
            isNull,
            reason: 'luber pada $width dp × $scale×',
          );
        }
      }
    });
  });
}
