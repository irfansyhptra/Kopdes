import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/platform_image.dart';
import '../controllers/product_form_controller.dart';

/// Lebar maksimal form di tablet: baris isian selebar 1000dp sulit dibaca
/// dan memisahkan label dari kolomnya.
const double productFormMaxWidth = 600;

// ─────────────────────────────────────────────────────────────
// Indikator tahap
// ─────────────────────────────────────────────────────────────

class FormStepIndicator extends StatelessWidget {
  final List<String> labels;
  final int current;

  /// Mengetuk tahap yang sudah dilewati membawa kembali ke sana.
  final ValueChanged<int> onTap;

  const FormStepIndicator({
    super.key,
    required this.labels,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++) Expanded(child: _step(i)),
      ],
    );
  }

  Widget _step(int i) {
    final done = i < current;
    final active = i == current;
    final reachable = i <= current;
    final state = done
        ? 'selesai'
        : active
        ? 'sedang diisi'
        : 'belum';

    Widget line(bool visible, bool filled) => Expanded(
      child: Container(
        height: 2,
        color: !visible
            ? Colors.transparent
            : filled
            ? AppColors.primary
            : AppColors.hairline,
      ),
    );

    final content = Column(
      children: [
        Row(
          children: [
            line(i > 0, i <= current),
            SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active || done
                        ? AppColors.primary
                        : AppColors.surfaceStrong,
                  ),
                  alignment: Alignment.center,
                  // Tahap selesai ditandai centang, bukan warna saja.
                  child: done
                      ? const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: AppColors.onPrimary,
                        )
                      : Text(
                          '${i + 1}',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? AppColors.onPrimary
                                : AppColors.muted,
                          ),
                        ),
                ),
              ),
            ),
            line(i < labels.length - 1, i < current),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            labels[i],
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AppColors.primaryText : AppColors.muted,
            ),
          ),
        ),
      ],
    );

    return Semantics(
      label: 'Tahap ${i + 1} dari ${labels.length}, ${labels[i]}, $state',
      button: reachable && !active,
      excludeSemantics: true,
      child: reachable && !active
          ? ApplePressable(onTap: () => onTap(i), child: content)
          : content,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Kolom isian
// ─────────────────────────────────────────────────────────────

/// Label yang selalu terlihat di atas kolom, dengan tanda wajib.
class FieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const FieldLabel(this.text, {super.key, this.required = false});

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodyMedium.copyWith(
      fontSize: 14.5,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        label: required ? '$text, wajib diisi' : text,
        excludeSemantics: true,
        child: Text.rich(
          TextSpan(
            text: text,
            style: style,
            children: [
              if (required)
                TextSpan(
                  text: ' *',
                  style: style.copyWith(color: AppColors.primaryText),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Permukaan abu-abu lembut, garis tipis; merah hanya untuk fokus & galat.
InputDecoration productInputDecoration({
  String? hint,
  String? error,
  Widget? prefix,
  Widget? suffix,
  String? counter,
}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppleRadii.control),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    hintText: hint,
    errorText: error,
    errorMaxLines: 3,
    prefixIcon: prefix,
    suffixIcon: suffix,
    counterText: counter,
    filled: true,
    fillColor: AppColors.surfaceSoft,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.base,
      vertical: 14,
    ),
    enabledBorder: border(AppColors.hairline),
    focusedBorder: border(AppColors.primary, 1.5),
    errorBorder: border(AppColors.errorText),
    focusedErrorBorder: border(AppColors.errorText, 1.5),
    disabledBorder: border(AppColors.hairlineSoft),
    hintStyle: AppTypography.bodyMedium.copyWith(
      fontSize: 15,
      color: AppColors.mutedSoft,
    ),
  );
}

/// Angka dengan pemisah ribuan saat diketik ("15000" → "15.000"). Nilai
/// yang disimpan form tetap angka polos — lihat [digitsOf].
class ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = digitsOf(newValue.text);
    if (digits.isEmpty) return const TextEditingValue();
    final formatted = formatThousands(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// "15.000" → "15000". Nol di depan dibuang.
  static String digitsOf(String text) {
    final d = text.replaceAll(RegExp(r'[^0-9]'), '');
    final trimmed = d.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    // Batas panjang di sini, bukan di LengthLimitingTextInputFormatter:
    // titik pemisah ikut terhitung di sana.
    return trimmed.length > 13 ? trimmed.substring(0, 13) : trimmed;
  }
}

/// Kategori dipilih lewat lembar bawah — daftar panjang di dropdown bawaan
/// sulit digulir di layar 320dp dengan teks besar.
class CategoryField extends StatelessWidget {
  final String? selectedName;
  final bool loading;
  final bool failed;
  final String? error;
  final VoidCallback? onTap;
  final VoidCallback? onRetry;

  const CategoryField({
    super.key,
    required this.selectedName,
    required this.loading,
    required this.failed,
    required this.error,
    required this.onTap,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (failed) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'Kategori belum termuat.',
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 14,
                color: AppColors.errorText,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            child: const Text('Coba Lagi'),
          ),
        ],
      );
    }

    final text = loading
        ? 'Memuat kategori…'
        : (selectedName ?? 'Pilih kategori');
    return Semantics(
      button: true,
      label: 'Kategori, wajib diisi. ${selectedName ?? 'Belum dipilih'}',
      excludeSemantics: true,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(AppleRadii.control),
        child: InputDecorator(
          isEmpty: false,
          decoration: productInputDecoration(
            error: error,
            suffix: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.muted,
            ),
          ),
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 15,
              color: selectedName == null ? AppColors.muted : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Foto
// ─────────────────────────────────────────────────────────────

class PhotoStrip extends StatelessWidget {
  final List<FormPhoto> photos;
  final int max;
  final VoidCallback? onAdd;
  final void Function(int index) onPhotoTap;

  const PhotoStrip({
    super.key,
    required this.photos,
    required this.max,
    required this.onAdd,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Empat petak per baris bila muat; di bawah 72dp petaknya terlalu
        // kecil untuk dikenali, jadi barisnya yang dikurangi.
        const gap = AppSpacing.md;
        var perRow = 4;
        while (perRow > 2 &&
            (constraints.maxWidth - gap * (perRow - 1)) / perRow < 72) {
          perRow--;
        }
        final size = ((constraints.maxWidth - gap * (perRow - 1)) / perRow)
            .clamp(64.0, 112.0);

        final tiles = <Widget>[
          if (photos.length < max)
            _AddTile(size: size, onTap: onAdd, left: max - photos.length),
          for (var i = 0; i < photos.length; i++)
            _PhotoTile(
              size: size,
              photo: photos[i],
              primary: i == 0,
              index: i,
              onTap: () => onPhotoTap(i),
            ),
          // Petak kosong hanya saat belum ada foto, sebagai gambaran ruang.
          if (photos.isEmpty)
            for (var i = 0; i < 2; i++) _GhostTile(size: size),
        ];
        return Wrap(spacing: gap, runSpacing: gap, children: tiles);
      },
    );
  }
}

class _AddTile extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;
  final int left;

  const _AddTile({required this.size, required this.onTap, required this.left});

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      semanticLabel: 'Tambah foto, sisa $left',
      child: CustomPaint(
        painter: _DashedBorder(
          color: AppColors.borderStrong,
          radius: AppleRadii.control,
        ),
        // Lebar tetap, tinggi minimal: pada teks besar labelnya butuh lebih
        // dari satu petak, dan petaknya yang memanjang — bukan labelnya
        // yang terpotong.
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: size,
            maxWidth: size,
            minHeight: size,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppColors.primaryText,
                  size: 26,
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Tambah foto',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.captionSmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostTile extends StatelessWidget {
  final double size;
  const _GhostTile({required this.size});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppleRadii.control),
      ),
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.mutedSoft,
        size: 26,
      ),
    ),
  );
}

class _PhotoTile extends StatelessWidget {
  final double size;
  final FormPhoto photo;
  final bool primary;
  final int index;
  final VoidCallback onTap;

  const _PhotoTile({
    required this.size,
    required this.photo,
    required this.primary,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cache = (size * dpr).round();
    final image = photo.isRemote
        ? Image.network(
            photo.url!,
            fit: BoxFit.cover,
            cacheWidth: cache,
            errorBuilder: (_, __, ___) => const _BrokenImage(),
          )
        : platformImage(
            photo.path!,
            fit: BoxFit.cover,
            cacheWidth: cache,
            errorBuilder: (_, __, ___) => const _BrokenImage(),
          );

    final status = switch (photo.status) {
      PhotoStatus.uploading => 'sedang diunggah',
      PhotoStatus.failed => 'gagal diunggah',
      PhotoStatus.uploaded when !photo.isRemote => 'terunggah',
      _ => null,
    };

    return ApplePressable(
      onTap: onTap,
      semanticLabel:
          'Foto ${index + 1}${primary ? ', foto utama' : ''}'
          '${status != null ? ', $status' : ''}. Ketuk untuk mengatur',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppleRadii.control),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: AppColors.surfaceSoft, child: image),
              if (primary)
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: _Badge(text: 'Utama', color: AppColors.ink),
                ),
              if (photo.status == PhotoStatus.uploading)
                const ColoredBox(
                  color: Color(0x66FFFFFF),
                  child: Center(child: AppleActivityIndicator(size: 20)),
                ),
              if (photo.status == PhotoStatus.failed)
                ColoredBox(
                  color: const Color(0x99FFFFFF),
                  child: Center(
                    child: _Badge(text: 'Gagal', color: AppColors.errorText),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrokenImage extends StatelessWidget {
  const _BrokenImage();

  @override
  Widget build(BuildContext context) => const Center(
    child: Icon(Icons.broken_image_outlined, color: AppColors.mutedSoft),
  );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text(
      text,
      style: AppTypography.captionSmall.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.onPrimary,
      ),
    ),
  );
}

class _DashedBorder extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorder({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ).deflate(0.6),
      );
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) =>
      old.color != color || old.radius != radius;
}

// ─────────────────────────────────────────────────────────────
// Bilah tindakan bawah
// ─────────────────────────────────────────────────────────────

class FormActionBar extends StatelessWidget {
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool secondaryBusy;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryBusy;

  const FormActionBar({
    super.key,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryBusy = false,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final busy = primaryBusy || secondaryBusy;
    final primary = FilledButton(
      onPressed: busy ? null : onPrimary,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.55),
        disabledForegroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppleRadii.control),
        ),
      ),
      child: _ButtonContent(
        label: primaryLabel,
        busy: primaryBusy,
        color: AppColors.onPrimary,
      ),
    );
    final secondary = secondaryLabel == null
        ? null
        : OutlinedButton(
            onPressed: busy ? null : onSecondary,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: AppColors.primaryText,
              side: const BorderSide(color: AppColors.primaryText),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppleRadii.control),
              ),
            ),
            child: _ButtonContent(
              label: secondaryLabel!,
              busy: secondaryBusy,
              color: AppColors.primaryText,
            ),
          );

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(top: BorderSide(color: AppColors.hairlineSoft)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.base,
          AppSpacing.md,
          AppSpacing.base,
          AppSpacing.md,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: productFormMaxWidth),
            child: LayoutBuilder(
              builder: (context, c) {
                final scale = MediaQuery.textScalerOf(context).scale(1);
                // Dua tombol berdampingan selama labelnya muat; selebihnya
                // bertumpuk — tombol utama di bawah, paling dekat ke jempol.
                final sideBySide =
                    secondary == null || c.maxWidth / 2 >= 150 * scale;
                if (secondary == null) return primary;
                return sideBySide
                    ? Row(
                        children: [
                          Expanded(child: secondary),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: primary),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          secondary,
                          const SizedBox(height: AppSpacing.sm),
                          primary,
                        ],
                      );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  final String label;
  final bool busy;
  final Color color;

  const _ButtonContent({
    required this.label,
    required this.busy,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.buttonMd.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
    if (!busy) return text;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: text),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Kartu & tinjauan
// ─────────────────────────────────────────────────────────────

class FormCard extends StatelessWidget {
  final Widget child;
  const FormCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.base),
    decoration: BoxDecoration(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(AppleRadii.tile),
      border: Border.all(color: AppColors.hairlineSoft),
    ),
    child: child,
  );
}

class FormSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const FormSectionTitle(this.title, {super.key, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Satu baris "label — nilai" di tahap Tinjau.
class ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool muted;

  const ReviewRow(this.label, this.value, {super.key, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              fontSize: 12.5,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 15,
              fontWeight: muted ? FontWeight.w400 : FontWeight.w600,
              color: muted ? AppColors.muted : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
