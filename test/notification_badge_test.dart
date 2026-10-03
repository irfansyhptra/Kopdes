import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/storage/api_cache.dart';
import 'package:kopdes/features/home/domain/membership_summary.dart';
import 'package:kopdes/features/notification/data/notification_store.dart';
import 'package:kopdes/features/notification/domain/entities/notification_item.dart';
import 'package:kopdes/features/notification/presentation/providers/notification_provider.dart';

/// ApiCache palsu di memori: menguji penyimpanan notifikasi tanpa Isar.
class _MemoryCache implements ApiCache {
  final Map<String, Object?> rows = {};

  @override
  Future<CachedEntry?> read(String key) async {
    if (!rows.containsKey(key)) return null;
    return CachedEntry(data: rows[key], age: Duration.zero);
  }

  @override
  Future<void> write(String key, Object? data) async => rows[key] = data;

  @override
  Future<void> invalidate(String key) async => rows.remove(key);

  @override
  Future<void> invalidatePrefix(String prefix) async =>
      rows.removeWhere((k, _) => k.startsWith(prefix));
}

NotificationItem _item({
  String id = '1',
  NotificationType type = NotificationType.cartAdded,
  bool isRead = false,
  DateTime? at,
}) => NotificationItem(
  id: id,
  type: type,
  title: 'Masuk Keranjang',
  description: 'Beras Premium (1x) ditambahkan.',
  timestamp: at ?? DateTime(2026, 10, 3, 9),
  isRead: isRead,
);

void main() {
  group('NotificationStore', () {
    test(
      'kosong sebelum ada apa pun — bukan delapan notifikasi palsu',
      () async {
        final store = NotificationStore(_MemoryCache(), 'u1');
        expect(await store.read(), isEmpty);
      },
    );

    test('bertahan di perangkat antar sesi', () async {
      final cache = _MemoryCache();
      await NotificationStore(cache, 'u1').write([_item()]);

      // Instance baru = aplikasi dibuka ulang.
      final restored = await NotificationStore(cache, 'u1').read();
      expect(restored, hasLength(1));
      expect(restored.single.type, NotificationType.cartAdded);
      expect(restored.single.isRead, isFalse);
    });

    // Keluar dari akun hanya menghapus token, bukan cache. Tanpa kunci per
    // pemilik, notifikasi orang sebelumnya terbaca oleh yang masuk berikutnya.
    test('tidak bocor ke pengguna lain di perangkat yang sama', () async {
      final cache = _MemoryCache();
      await NotificationStore(cache, 'u1').write([_item()]);
      expect(await NotificationStore(cache, 'u2').read(), isEmpty);
    });

    test('terbaru lebih dulu, apa pun urutan simpannya', () async {
      final cache = _MemoryCache();
      await NotificationStore(cache, 'u1').write([
        _item(id: 'lama', at: DateTime(2026, 10, 1)),
        _item(id: 'baru', at: DateTime(2026, 10, 3)),
      ]);
      final rows = await NotificationStore(cache, 'u1').read();
      expect(rows.map((n) => n.id), ['baru', 'lama']);
    });

    test('riwayat dibatasi supaya tidak tumbuh selamanya', () async {
      final cache = _MemoryCache();
      final many = [
        for (var i = 0; i < NotificationStore.maxItems + 50; i++)
          _item(
            id: '$i',
            at: DateTime(2026, 10, 3).add(Duration(minutes: i)),
          ),
      ];
      await NotificationStore(cache, 'u1').write(many);
      expect(
        await NotificationStore(cache, 'u1').read(),
        hasLength(NotificationStore.maxItems),
      );
    });

    // Satu baris rusak atau bertipe tak dikenal tidak boleh menghapus
    // seluruh riwayat seseorang.
    test('baris tak terbaca dilewati, sisanya tetap utuh', () async {
      final cache = _MemoryCache();
      final store = NotificationStore(cache, 'u1');
      await store.write([_item(id: 'baik')]);
      final saved = cache.rows[CacheKeys.notifications('u1')] as List;
      cache.rows[CacheKeys.notifications('u1')] = [
        ...saved,
        {
          'id': 'aneh',
          'type': 'tipeDariVersiLain',
          'title': 'x',
          'timestamp': '2026-10-03T09:00:00.000',
        },
        'bukan objek',
      ];

      final rows = await store.read();
      expect(rows.map((n) => n.id), ['baik']);
    });

    // Lencana kecil tidak boleh menjatuhkan kepala halaman: header pegawai,
    // beranda, dan halaman pesanan semuanya membacanya, dan satu StateError
    // dari Isar di sana mengosongkan seluruh layar.
    test('tanpa penyimpanan tetap jalan, hanya tidak bertahan', () async {
      final store = NotificationStore(null, 'u1');
      expect(await store.read(), isEmpty);
      await store.write([_item()]);
      expect(await store.read(), isEmpty);
      await store.clear();
    });

    test('tipe enum disimpan sebagai nama, bukan indeks', () async {
      final cache = _MemoryCache();
      await NotificationStore(
        cache,
        'u1',
      ).write([_item(type: NotificationType.orderSuccess)]);
      final row = (cache.rows[CacheKeys.notifications('u1')] as List).single;
      expect((row as Map)['type'], 'orderSuccess');
    });
  });

  group('MembershipSummary', () {
    test('bawaannya bukan anggota, nol poin, tanpa jenjang', () {
      const s = MembershipSummary.none;
      expect(s.isMember, isFalse);
      expect(s.balance, isNull);
      expect(s.points, 0);
      // Bukan "Bronze": jenjang terendah pun menyiratkan sudah jadi anggota.
      expect(s.tier, isNull);
    });

    test('jenjang naik mengikuti poin', () {
      MemberTier? tierAt(int points) =>
          MembershipSummary(points: points, isMember: true).tier;

      expect(tierAt(0), MemberTier.bronze);
      expect(tierAt(999), MemberTier.bronze);
      expect(tierAt(1000), MemberTier.silver);
      expect(tierAt(4999), MemberTier.silver);
      expect(tierAt(5000), MemberTier.gold);
      expect(tierAt(9999), MemberTier.gold);
      expect(tierAt(10000), MemberTier.diamond);
    });

    test('poin tanpa keanggotaan tetap tanpa jenjang', () {
      expect(const MembershipSummary(points: 9000).tier, isNull);
    });
  });

  group('lencana notifikasi', () {
    late _MemoryCache cache;
    late ProviderContainer container;

    setUp(() {
      cache = _MemoryCache();
      container = ProviderContainer(
        overrides: [
          // Langsung menimpa store-nya: authProvider akan menarik Dio dan
          // secure storage, yang tidak ada di lingkungan tes.
          notificationStoreProvider.overrideWithValue(
            NotificationStore(cache, 'u1'),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test('mulai dari nol, bukan dari dua yang tidak pernah terjadi', () {
      expect(container.read(unreadNotificationCountProvider), 0);
    });

    test('tiap notifikasi baru menaikkan angkanya', () async {
      final notifier = container.read(notificationsProvider.notifier);

      await notifier.add(
        type: NotificationType.cartAdded,
        title: 'Masuk Keranjang',
        description: 'Beras Premium (1x) ditambahkan.',
      );
      expect(container.read(unreadNotificationCountProvider), 1);

      await notifier.add(
        type: NotificationType.orderSuccess,
        title: 'Pesanan Berhasil',
        description: 'Pesanan Anda sedang disiapkan.',
      );
      expect(container.read(unreadNotificationCountProvider), 2);
    });

    test('dibaca menurunkan angkanya, dan tersimpan', () async {
      final notifier = container.read(notificationsProvider.notifier);
      await notifier.add(
        type: NotificationType.cartAdded,
        title: 'Masuk Keranjang',
        description: 'x',
      );
      final id = container.read(notificationsProvider).single.id;

      await notifier.markAsRead(id);
      expect(container.read(unreadNotificationCountProvider), 0);

      // Benar-benar ditulis ke perangkat, bukan hanya ke state di memori.
      final saved = await NotificationStore(cache, 'u1').read();
      expect(saved.single.isRead, isTrue);
    });

    test('dua notifikasi dalam satu tarikan tetap punya id berbeda', () async {
      final notifier = container.read(notificationsProvider.notifier);
      await notifier.add(
        type: NotificationType.cartAdded,
        title: 'a',
        description: 'a',
      );
      await notifier.add(
        type: NotificationType.cartAdded,
        title: 'b',
        description: 'b',
      );
      final ids = container.read(notificationsProvider).map((n) => n.id);
      expect(ids.toSet(), hasLength(2));
    });

    test('hapus semua mengosongkan perangkat juga', () async {
      final notifier = container.read(notificationsProvider.notifier);
      await notifier.add(
        type: NotificationType.cartAdded,
        title: 'x',
        description: 'x',
      );
      await notifier.clearAll();

      expect(container.read(unreadNotificationCountProvider), 0);
      expect(await NotificationStore(cache, 'u1').read(), isEmpty);
    });
  });
}
