import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import 'product_form_ui.dart';
import 'seller_page_ui.dart';
import 'store_page_ui.dart';

/// Kerangka halaman isian di bawah tab Toko: kepala merah, isi yang
/// bergulir, tombol simpan yang naik bersama keyboard, dan penjaga
/// "buang perubahan?" saat kembali.
class StoreFormPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool dirty;
  final bool saving;
  final String saveLabel;
  final VoidCallback? onSave;
  final List<Widget> children;

  const StoreFormPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.dirty,
    required this.saving,
    required this.onSave,
    required this.children,
    this.saveLabel = 'Simpan',
  });

  Future<void> _back(BuildContext context) async {
    if (saving) return;
    if (!dirty) {
      context.pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppleRadii.tile),
        ),
        title: const Text('Buang perubahan?'),
        content: const Text('Perubahan di halaman ini belum disimpan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Lanjut Mengubah'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorText),
            child: const Text('Buang'),
          ),
        ],
      ),
    );
    if (leave == true && context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !dirty && !saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceSoft,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            SellerSubpageHeader(
              title: title,
              subtitle: subtitle,
              onBack: () => _back(context),
            ),
            Expanded(child: StoreSubpageBody(children: children)),
            if (onSave != null || saving)
              FormActionBar(
                primaryLabel: saveLabel,
                onPrimary: onSave,
                primaryBusy: saving,
              ),
          ],
        ),
      ),
    );
  }
}
