import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/product/presentation/providers/product_provider.dart';

class AdminProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;

  const AdminProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<AdminProductFormScreen> createState() =>
      _AdminProductFormScreenState();
}

class _AdminProductFormScreenState
    extends ConsumerState<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  String? _selectedCategoryId;
  bool _isInitialized = false;
  final List<XFile> _selectedImages = [];
  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(imageQuality: 80);
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $e')));
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih kategori produk'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final price = double.tryParse(_priceController.text) ?? 0.0;
    final stock = int.tryParse(_stockController.text) ?? 0;
    final name = _nameController.text.trim();
    final description = _descController.text.trim();

    bool success = false;
    final isEdit = widget.productId != null;

    if (isEdit) {
      success = await ref
          .read(adminProductActionProvider.notifier)
          .updateProduct(
            id: widget.productId!,
            name: name,
            description: description,
            price: price,
            stock: stock,
            categoryId: _selectedCategoryId,
            newImages: _selectedImages,
          );
    } else {
      success = await ref
          .read(adminProductActionProvider.notifier)
          .createProduct(
            name: name,
            description: description,
            price: price,
            stock: stock,
            categoryId: _selectedCategoryId!,
            images: _selectedImages,
          );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Produk berhasil diperbarui'
                : 'Produk berhasil ditambahkan',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else if (mounted) {
      final state = ref.read(adminProductActionProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operasi gagal: ${state.error ?? "Terjadi kesalahan"}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final actionState = ref.watch(adminProductActionProvider);
    final isEdit = widget.productId != null;

    // Handle pre-populate edit states once
    if (isEdit && !_isInitialized) {
      final detailAsync = ref.watch(productDetailProvider(widget.productId!));
      detailAsync.whenData((product) {
        if (!_isInitialized) {
          _nameController.text = product.name;
          _descController.text = product.description;
          _priceController.text = product.price.toStringAsFixed(0);
          _stockController.text = product.stock.toString();
          _selectedCategoryId = product.categoryId;
          _isInitialized = true;
        }
      });
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(
            backgroundColor: AppColors.canvas,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
              onPressed: () => context.pop(),
            ),
            title: Text(
              isEdit ? 'Ubah Produk' : 'Tambah Produk Baru',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.base),
              children: [
                // Category Dropdown
                categoriesAsync.when(
                  data: (categories) {
                    return DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      dropdownColor: AppColors.canvas,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.ink,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Kategori Produk',
                        prefixIcon: Icon(Icons.category_outlined, size: 20),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Silakan pilih kategori' : null,
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  error: (err, _) => Text(
                    'Gagal memuat kategori: $err',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.base),

                // Name
                TextFormField(
                  controller: _nameController,
                  style: AppTypography.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Nama Produk',
                    prefixIcon: Icon(Icons.shopping_bag_outlined, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama produk tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.base),

                // Description
                TextFormField(
                  controller: _descController,
                  style: AppTypography.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Produk',
                    prefixIcon: Icon(Icons.description_outlined, size: 20),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Deskripsi produk tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.base),

                // Price & Stock row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        style: AppTypography.bodyLarge,
                        decoration: const InputDecoration(
                          labelText: 'Harga (Rp)',
                          prefixIcon: Icon(
                            Icons.monetization_on_outlined,
                            size: 20,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Harga wajib diisi';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Format harga salah';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.base),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        style: AppTypography.bodyLarge,
                        decoration: const InputDecoration(
                          labelText: 'Stok',
                          prefixIcon: Icon(
                            Icons.inventory_2_outlined,
                            size: 20,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Stok wajib diisi';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Format stok salah';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Images Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Gambar Produk (Maks 5)',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(
                        Icons.add_a_photo_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      label: Text(
                        'Pilih Foto',
                        style: AppTypography.buttonSm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _selectedImages.length >= 5
                          ? null
                          : _pickImages,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Selected Images list preview
                _selectedImages.isNotEmpty
                    ? SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            final image = _selectedImages[index];
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.hairline,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.file(
                                    File(image.path),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      )
                    : Container(
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(
                            color: AppColors.hairlineSoft,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Belum ada gambar yang dipilih',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: AppSpacing.xl),

                // Submit Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: Text(
                      isEdit ? 'Perbarui Produk' : 'Simpan Produk Baru',
                      style: AppTypography.buttonMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Global loading overlay
        if (actionState is AsyncLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}
