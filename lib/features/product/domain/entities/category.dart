class Category {
  final String id;
  final String name;
  final String? description;

  /// Kelompok kategori dari backend: `FOOD` atau `RETAIL`.
  ///
  /// Menentukan baris filter mana yang menampilkannya di Marketplace.
  /// Default `RETAIL` agar kategori baru tetap muncul di salah satu baris,
  /// bukan hilang dari keduanya.
  final String group;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.group = 'RETAIL',
  });
}
