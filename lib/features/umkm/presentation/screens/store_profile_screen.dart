import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/components/loading_widget.dart';
import '../../../../shared/components/error_state_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../controllers/store_controller.dart';
import '../../data/models/store_model.dart';

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

    final success = await ref.read(storeControllerProvider.notifier).updateStoreProfile(
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

  void _withdrawBalance() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Tarik Saldo Dompet'),
          content: const Text(
            'Saldo sebesar Rp 3.840.000 akan ditransfer ke rekening bank terdaftar Anda. Apakah Anda ingin melanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Permintaan penarikan saldo berhasil dikirim. Proses verifikasi 1-2 hari kerja.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Tarik Saldo'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(storeProfileProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(
            title: const Text('Profil Toko & Pengaturan'),
            centerTitle: true,
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                )
              else
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _isInit = false; // Trigger reload of original values
                    });
                  },
                ),
            ],
          ),
          body: profileState.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (error, stack) => ErrorStateWidget(
              errorMessage: error.toString(),
              onRetry: () => ref.invalidate(storeProfileProvider),
            ),
            data: (store) {
              _populateForm(store);
              final bool isVerified = store.status == 'ACTIVE';

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  children: [
                    // Shop Logo & Status
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTint,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary, width: 2),
                                ),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  color: AppColors.primary,
                                  size: 44,
                                ),
                              ),
                              if (_isEditing)
                                Container(
                                  padding: const EdgeInsets.all(6),
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
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            store.businessName,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isVerified
                                  ? AppColors.success.withOpacity(0.08)
                                  : AppColors.warning.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              isVerified ? 'Toko Terverifikasi ✓' : 'Verifikasi Pending ⌛',
                              style: AppTypography.badge.copyWith(
                                color: isVerified ? AppColors.success : AppColors.warning,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Dompet Toko Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppElevation.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Saldo Dompet Toko',
                                    style: AppTypography.captionSmall.copyWith(
                                      color: AppColors.onDark.withOpacity(0.6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Rp 3.840.000',
                                    style: AppTypography.titleLarge.copyWith(
                                      color: AppColors.onDark,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 22,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: _withdrawBalance,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.button),
                                  ),
                                ),
                                child: Text(
                                  'Tarik Saldo',
                                  style: AppTypography.buttonSm.copyWith(
                                    color: AppColors.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Store Profile Form Fields
                    Text(
                      'Nama Usaha / Toko',
                      style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.ink),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _nameController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        hintText: 'Nama Usaha',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Nama usaha wajib diisi' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Text(
                      'Deskripsi Usaha',
                      style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.ink),
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
                      style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.ink),
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
                      style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.ink),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _phoneController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'Nomor HP/WA Toko',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Nomor telepon wajib diisi' : null,
                    ),
                    
                    if (_isEditing) ...[
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button),
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
                    
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(),
                    const SizedBox(height: AppSpacing.lg),

                    // Additional Settings / Navigation Items
                    _buildSettingsTile(
                      icon: Icons.local_shipping_outlined,
                      title: 'Metode Pengiriman & Kurir',
                      subtitle: 'Atur kurir lokal KOPDES atau mandiri',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fitur Pengiriman dikelola oleh KOPDES Admin & Kurir secara otomatis.')),
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
                          const SnackBar(content: Text('Silakan hubungi admin di support@kopdes.co')),
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
              );
            },
          ),
        ),
        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: LoadingWidget(message: 'Menyimpan profil toko...'),
            ),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: ListTile(
        leading: Icon(icon, color: titleColor ?? AppColors.primary),
        title: Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: titleColor ?? AppColors.ink,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.captionSmall,
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        onTap: onTap,
      ),
    );
  }
}
