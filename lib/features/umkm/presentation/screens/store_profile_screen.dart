import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/components/loading_widget.dart';
import '../../../../shared/components/error_state_widget.dart';
import '../../../../shared/widgets/app_glass_chrome.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../wallet/data/wallet_repository.dart';
import '../controllers/store_controller.dart';
import '../../data/models/store_model.dart';
import '../widgets/seller_page_ui.dart';

class StoreProfileScreen extends ConsumerStatefulWidget {
  const StoreProfileScreen({super.key});

  @override
  ConsumerState<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends ConsumerState<StoreProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isInit = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _populateForm(StoreModel store) {
    if (_isInit) return;
    _nameController.text = store.businessName;
    _descController.text = store.description;
    _addressController.text = store.address;
    _phoneController.text = store.phone;
    _isInit = true;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final success = await ref
        .read(storeControllerProvider.notifier)
        .updateStoreProfile(
          businessName: _nameController.text.trim(),
          description: _descController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
        );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (success) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil toko berhasil diperbarui'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui profil toko'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Penarikan saldo belum punya endpoint di backend.
  ///
  /// Versi sebelumnya menyebut nominal tetap "Rp 3.840.000", lalu menjawab
  /// "Permintaan penarikan berhasil dikirim" tanpa mengirim apa pun. Orang
  /// yang mempercayainya akan menunggu uang yang tidak pernah diminta.
  Future<void> _withdrawBalance(double balance) {
    return showAppleActionDialog<void>(
      context,
      title: 'Penarikan Saldo Belum Tersedia',
      success: false,
      message:
          'Saldo Anda saat ini ${formatRupiah(balance)}. Penarikan ke '
          'rekening bank masih disiapkan — untuk sementara hubungi pengurus '
          'Kopdes desa Anda.',
      primaryLabel: 'Mengerti',
      onPrimary: () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(storeProfileProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.surfaceSoft,
          body: SellerPageChrome(
            title: 'Toko Anda',
            subtitle: _isEditing
                ? 'Perbarui informasi yang dilihat pembeli'
                : 'Profil, pencairan, dan pengaturan usaha',
            actions: [
              if (!_isEditing)
                GlassIconButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit profil toko',
                  onDark: true,
                  onTap: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                )
              else
                GlassIconButton(
                  icon: Icons.close_rounded,
                  label: 'Batalkan perubahan',
                  onDark: true,
                  onTap: () {
                    setState(() {
                      _isEditing = false;
                      _isInit = false; // Trigger reload of original values
                    });
                  },
                ),
            ],
            body: profileState.when(
              loading: () =>
                  const Center(child: AppleActivityIndicator(size: 28)),
              error: (error, stack) => ErrorStateWidget(
                errorMessage: error.toString(),
                onRetry: () => ref.invalidate(storeProfileProvider),
              ),
              data: (store) {
                _populateForm(store);
                final bool isVerified = store.status == 'ACTIVE';

                return Form(
                  key: _formKey,
                  child: SellerContentBoundary(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        0,
                        AppSpacing.base,
                        0,
                        112,
                      ),
                      children: [
                        SellerSectionCard(
                          child: Row(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryTint,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primarySoft,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.storefront_rounded,
                                      color: AppColors.primary,
                                      size: 34,
                                    ),
                                  ),
                                  if (_isEditing)
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_outlined,
                                        color: AppColors.onPrimary,
                                        size: 14,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: AppSpacing.base),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      store.businessName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.titleMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    SellerStatusBadge(
                                      label: isVerified
                                          ? 'Toko terverifikasi'
                                          : 'Menunggu verifikasi',
                                      color: isVerified
                                          ? AppColors.success
                                          : AppColors.warning,
                                      icon: isVerified
                                          ? Icons.verified_rounded
                                          : Icons.schedule_rounded,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Dompet Toko Card
                        SellerSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Saldo Dompet Toko',
                                        style: AppTypography.captionSmall
                                            .copyWith(
                                              color: AppColors.muted,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Consumer(
                                        builder: (context, ref, _) {
                                          return ref
                                              .watch(walletBalanceProvider)
                                              .when(
                                                loading: () => const SizedBox(
                                                  height: 28,
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child:
                                                        AppleActivityIndicator(
                                                          size: 18,
                                                          color:
                                                              AppColors.primary,
                                                        ),
                                                  ),
                                                ),
                                                // Gagal berarti TIDAK TAHU,
                                                // bukan nol: "Rp0" di kartu
                                                // dompet terbaca seperti uangnya
                                                // habis.
                                                error: (_, __) => Text(
                                                  'Gagal dimuat',
                                                  style: AppTypography
                                                      .titleLarge
                                                      .copyWith(
                                                        color: AppColors.muted
                                                            .withValues(
                                                              alpha: 0.7,
                                                            ),
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 18,
                                                      ),
                                                ),
                                                data: (wallet) => Text(
                                                  formatRupiah(wallet.balance),
                                                  style: AppTypography
                                                      .titleLarge
                                                      .copyWith(
                                                        color: AppColors.ink,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 22,
                                                      ),
                                                ),
                                              );
                                        },
                                      ),
                                    ],
                                  ),
                                  Consumer(
                                    builder: (context, ref, _) {
                                      final balance = ref
                                          .watch(walletBalanceProvider)
                                          .valueOrNull
                                          ?.balance;
                                      return ElevatedButton(
                                        onPressed: balance == null
                                            ? null
                                            : () => _withdrawBalance(balance),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.onPrimary,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          minimumSize: const Size(44, 44),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.button,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Tarik Saldo',
                                          style: AppTypography.buttonSm
                                              .copyWith(
                                                color: AppColors.onPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        SellerSectionCard(
                          title: 'Informasi toko',
                          subtitle: _isEditing
                              ? 'Perubahan akan tampil pada etalase pembeli.'
                              : 'Tekan Edit untuk memperbarui data usaha.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nama Usaha / Toko',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextFormField(
                                controller: _nameController,
                                enabled: _isEditing,
                                decoration: const InputDecoration(
                                  hintText: 'Nama Usaha',
                                ),
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                    ? 'Nama usaha wajib diisi'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),

                              Text(
                                'Deskripsi Usaha',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextFormField(
                                controller: _descController,
                                enabled: _isEditing,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText: 'Deskripsi singkat usaha Anda...',
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              Text(
                                'Alamat Toko',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextFormField(
                                controller: _addressController,
                                enabled: _isEditing,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  hintText: 'Alamat lengkap lokasi usaha',
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              Text(
                                'Nomor Telepon Toko',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextFormField(
                                controller: _phoneController,
                                enabled: _isEditing,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  hintText: 'Nomor HP/WA Toko',
                                ),
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                    ? 'Nomor telepon wajib diisi'
                                    : null,
                              ),

                              if (_isEditing) ...[
                                const SizedBox(height: AppSpacing.lg),
                                ElevatedButton(
                                  onPressed: _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.button,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Simpan Perubahan Profil',
                                    style: AppTypography.buttonMd.copyWith(
                                      color: AppColors.onPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Pengaturan',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildSettingsTile(
                          icon: Icons.local_shipping_outlined,
                          title: 'Metode Pengiriman & Kurir',
                          subtitle: 'Atur kurir lokal KOPDES atau mandiri',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Fitur Pengiriman dikelola oleh KOPDES Admin & Kurir secara otomatis.',
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _buildSettingsTile(
                          icon: Icons.help_outline_rounded,
                          title: 'Pusat Bantuan KOPDES',
                          subtitle: 'Hubungi administrator koperasi',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Silakan hubungi admin di support@kopdes.co',
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _buildSettingsTile(
                          icon: Icons.logout_rounded,
                          title: 'Keluar Dari Akun',
                          titleColor: AppColors.errorText,
                          subtitle: 'Logout dari aplikasi KOPDES',
                          onTap: () {
                            ref.read(authProvider.notifier).logout();
                          },
                        ),
                        const SizedBox(height: AppSpacing.section),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (_isSaving)
          const SellerLoadingScrim(
            child: LoadingWidget(message: 'Menyimpan profil toko...'),
          ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return ApplePressable(
      onTap: onTap,
      semanticLabel: title,
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(AppleRadii.tile),
          border: Border.all(color: AppColors.hairlineSoft),
          boxShadow: AppElevation.subtle,
        ),
        child: ListTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (titleColor ?? AppColors.primary).withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: titleColor ?? AppColors.primary, size: 20),
          ),
          title: Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: titleColor ?? AppColors.ink,
            ),
          ),
          subtitle: Text(subtitle, style: AppTypography.captionSmall),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.muted,
          ),
        ),
      ),
    );
  }
}
