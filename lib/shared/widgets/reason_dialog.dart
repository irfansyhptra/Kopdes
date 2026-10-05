import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// Menanyakan satu alasan, lalu mengembalikannya (null bila dibatalkan).
///
/// Controller-nya dimiliki widget di dalam dialog, bukan pemanggilnya.
/// Membuangnya tepat setelah `showDialog` kembali terlihat rapi tetapi
/// salah: dialognya masih beranimasi menutup dan `TextField`-nya masih
/// memakai controller itu — crash "used after being disposed".
Future<String?> askReason(
  BuildContext context, {
  required String title,
  required String label,
  String? message,
  String? hint,
  String confirmLabel = 'Kirim',
  int minLength = 5,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ReasonDialog(
      title: title,
      label: label,
      message: message,
      hint: hint,
      confirmLabel: confirmLabel,
      minLength: minLength,
    ),
  );
}

class _ReasonDialog extends StatefulWidget {
  final String title;
  final String label;
  final String? message;
  final String? hint;
  final String confirmLabel;
  final int minLength;

  const _ReasonDialog({
    required this.title,
    required this.label,
    required this.confirmLabel,
    required this.minLength,
    this.message,
    this.hint,
  });

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _valid => _controller.text.trim().length >= widget.minLength;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.message != null) ...[
            Text(widget.message!),
            const SizedBox(height: AppSpacing.md),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        // Mati sampai alasannya terisi: tombol yang bisa ditekan lalu diam
        // membuat orang menekannya berulang-ulang.
        TextButton(
          onPressed: _valid
              ? () => Navigator.pop(context, _controller.text.trim())
              : null,
          style: TextButton.styleFrom(foregroundColor: AppColors.errorText),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
