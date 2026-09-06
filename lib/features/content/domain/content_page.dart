/// Satu bagian isi halaman informasi.
class ContentSection {
  final String heading;
  final String body;

  const ContentSection({required this.heading, required this.body});

  factory ContentSection.fromJson(Map<String, dynamic> json) => ContentSection(
    heading: json['heading'] as String? ?? '',
    body: json['body'] as String? ?? '',
  );
}

/// Halaman informasi yang isinya dikelola dari backend.
///
/// Untuk materi keanggotaan koperasi, isinya sengaja **tidak** ditulis di
/// aplikasi: syarat, kewajiban, dan mekanisme simpanan mengikuti AD/ART dan
/// hanya boleh diisi pengurus koperasi.
class ContentPage {
  final String slug;
  final String title;
  final String? subtitle;
  final List<ContentSection> sections;
  final String? footnote;
  final DateTime? updatedAt;

  const ContentPage({
    required this.slug,
    required this.title,
    required this.sections,
    this.subtitle,
    this.footnote,
    this.updatedAt,
  });

  factory ContentPage.fromJson(Map<String, dynamic> json) => ContentPage(
    slug: json['slug'] as String? ?? '',
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String?,
    sections: (json['sections'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ContentSection.fromJson)
        .where((s) => s.heading.isNotEmpty || s.body.isNotEmpty)
        .toList(growable: false),
    footnote: json['footnote'] as String?,
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
  );
}

/// Slug yang dirujuk aplikasi. Sama dengan `CONTENT_SLUGS` di backend.
class ContentSlugs {
  static const String belanjaLokal = 'belanja-lokal';
  static const String manfaatAnggota = 'manfaat-anggota';
}
