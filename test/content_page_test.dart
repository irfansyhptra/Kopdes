import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/features/content/domain/content_page.dart';

void main() {
  group('ContentPage', () {
    test('mem-parse halaman lengkap', () {
      final page = ContentPage.fromJson({
        'slug': 'manfaat-anggota',
        'title': 'Menjadi Anggota Koperasi',
        'subtitle': 'Hal yang perlu diketahui',
        'sections': [
          {'heading': 'Hak anggota', 'body': 'Menghadiri Rapat Anggota.'},
          {'heading': 'Kewajiban', 'body': 'Mematuhi AD/ART.'},
        ],
        'footnote': 'Ketentuan mengikat adalah AD/ART.',
        'updatedAt': '2026-09-05T00:00:00.000Z',
      });

      expect(page.slug, 'manfaat-anggota');
      expect(page.sections.length, 2);
      expect(page.sections.first.heading, 'Hak anggota');
      expect(page.footnote, isNotNull);
      expect(page.updatedAt, isNotNull);
    });

    // Halaman yang pengurus baru isi sebagian tidak boleh membuat layar rusak.
    test('bagian kosong dibuang, bukan dirender sebagai baris hampa', () {
      final page = ContentPage.fromJson({
        'slug': 'x',
        'title': 'X',
        'sections': [
          {'heading': '', 'body': ''},
          {'heading': 'Ada isi', 'body': 'teks'},
          {'body': 'tanpa judul'},
        ],
      });

      expect(page.sections.length, 2);
      expect(page.sections[1].heading, '');
      expect(page.sections[1].body, 'tanpa judul');
    });

    test('halaman tanpa sections tidak melempar', () {
      final page = ContentPage.fromJson({'slug': 'x', 'title': 'X'});

      expect(page.sections, isEmpty);
      expect(page.subtitle, isNull);
      expect(page.footnote, isNull);
      expect(page.updatedAt, isNull);
    });

    test('sections berbentuk tak terduga diabaikan', () {
      final page = ContentPage.fromJson({
        'slug': 'x',
        'title': 'X',
        'sections': ['bukan objek', 42, null],
      });

      expect(page.sections, isEmpty);
    });
  });

  group('ContentSlugs', () {
    // Harus sama persis dengan CONTENT_SLUGS di backend; kalau melenceng,
    // halaman informasinya 404 tanpa penjelasan.
    test('slug sesuai kesepakatan dengan backend', () {
      expect(ContentSlugs.belanjaLokal, 'belanja-lokal');
      expect(ContentSlugs.manfaatAnggota, 'manfaat-anggota');
    });
  });
}
