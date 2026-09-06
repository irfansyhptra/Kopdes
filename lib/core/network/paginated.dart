import 'response_wrapper.dart';

/// Satu halaman hasil beserta metadata paginasinya.
///
/// Backend sudah mengirim `meta { total, page, limit, totalPages }` dan
/// [ApiMetadata] sudah bisa mem-parse-nya — tapi sebelumnya tidak ada satu pun
/// pemanggil yang membacanya, sehingga aplikasi tidak pernah tahu masih ada
/// halaman berikutnya atau tidak.
class Paginated<T> {
  final List<T> items;
  final int page;
  final int totalPages;
  final int total;

  const Paginated({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  const Paginated.empty()
    : items = const [],
      page = 1,
      totalPages = 1,
      total = 0;

  bool get hasMore => page < totalPages;

  /// Parse `{ "<itemsKey>": [...], "meta": {...} }`.
  factory Paginated.fromJson(
    dynamic json,
    String itemsKey,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final map = json is Map<String, dynamic> ? json : const {};
    final rawItems = map[itemsKey] as List? ?? const [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(fromItem)
        .toList(growable: false);

    final rawMeta = map['meta'];
    final meta = rawMeta is Map<String, dynamic>
        ? ApiMetadata.fromJson(rawMeta)
        : null;

    return Paginated<T>(
      items: items,
      page: meta?.page ?? 1,
      // Tanpa meta, anggap ini satu-satunya halaman — lebih baik berhenti
      // memuat daripada meminta halaman yang tidak ada tanpa henti.
      totalPages: meta?.totalPages ?? 1,
      total: meta?.total ?? items.length,
    );
  }

  Paginated<R> map<R>(R Function(T) convert) => Paginated<R>(
    items: items.map(convert).toList(growable: false),
    page: page,
    totalPages: totalPages,
    total: total,
  );

  /// Gabungkan halaman berikutnya ke daftar yang sudah ada.
  Paginated<T> append(Paginated<T> next) => Paginated<T>(
    items: [...items, ...next.items],
    page: next.page,
    totalPages: next.totalPages,
    total: next.total,
  );
}
