import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

/// Satu alamat di buku alamat pengguna (`model Address`).
class Address {
  final String id;
  final String title;
  final String recipientName;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final bool isDefault;

  const Address({
    required this.id,
    required this.title,
    required this.recipientName,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.isDefault,
  });

  /// "Jl. …, Kota, Provinsi 23115".
  String get oneLine => '$street, $city, $state $postalCode';

  factory Address.fromJson(Map<String, dynamic> j) => Address(
    id: j['id'] as String? ?? '',
    title: j['title'] as String? ?? '',
    recipientName: j['recipientName'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    street: j['street'] as String? ?? '',
    city: j['city'] as String? ?? '',
    state: j['state'] as String? ?? '',
    postalCode: j['postalCode'] as String? ?? '',
    isDefault: j['isDefault'] == true,
  );
}

/// Isian alamat — kunci sama dengan `CreateAddressDto`.
class AddressInput {
  final String title;
  final String recipientName;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final bool isDefault;

  const AddressInput({
    required this.title,
    required this.recipientName,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'recipientName': recipientName,
    'phone': phone,
    'street': street,
    'city': city,
    'state': state,
    'postalCode': postalCode,
    'isDefault': isDefault,
  };
}

/// Buku alamat. Tanpa cache: alamat yang baru diubah harus langsung
/// dipakai checkout, dan daftarnya kecil.
class AddressRepository {
  final Dio dio;
  const AddressRepository(this.dio);

  Future<List<Address>> list() async {
    final r = await dio.get('/addresses');
    final raw = (r.data as Map<String, dynamic>)['addresses'] as List? ?? [];
    return raw.whereType<Map<String, dynamic>>().map(Address.fromJson).toList();
  }

  Future<Address> create(AddressInput input) async {
    final r = await dio.post('/addresses', data: input.toJson());
    return Address.fromJson(
      (r.data as Map<String, dynamic>)['address'] as Map<String, dynamic>,
    );
  }

  Future<Address> update(String id, AddressInput input) async {
    final r = await dio.put('/addresses/$id', data: input.toJson());
    return Address.fromJson(
      (r.data as Map<String, dynamic>)['address'] as Map<String, dynamic>,
    );
  }

  Future<Address> makeDefault(String id) async {
    final r = await dio.put('/addresses/$id', data: {'isDefault': true});
    return Address.fromJson(
      (r.data as Map<String, dynamic>)['address'] as Map<String, dynamic>,
    );
  }

  /// Ditolak server bila alamatnya sudah dipakai pesanan.
  Future<void> remove(String id) => dio.delete('/addresses/$id');
}

final addressRepositoryProvider = Provider<AddressRepository>(
  (ref) => AddressRepository(ref.watch(dioProvider)),
);

/// Alamat utama lebih dulu (urutan dari server).
final addressesProvider = FutureProvider<List<Address>>(
  (ref) => ref.watch(addressRepositoryProvider).list(),
);
