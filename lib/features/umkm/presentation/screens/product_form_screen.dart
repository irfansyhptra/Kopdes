import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/components/loading_widget.dart';
import '../../../../shared/components/error_state_widget.dart';
import '../controllers/product_controller.dart';
import '../../data/models/product_model.dart';
import 'product_detail_screen.dart'; // To use the detail provider

class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;
  const ProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  
  String? _selectedCategoryId;
  List<XFile> _newImages = [];
  List<String> _existingImageUrls = [];
  bool _isInit = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _populateForm(ProductModel product) {
    if (_isInit) return;
    _nameController.text = product.name;
    _descController.text = product.description;
    _priceController.text = product.price.toStringAsFixed(0);
    _stockController.text = product.stock.toString();
    _selectedCategoryId = product.categoryId;
    _existingImageUrls = product.images.map((img) => img.url).toList();
    _isInit = true;
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final totalImages = _existingImageUrls.length + _newImages.length;
    if (totalImages >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal 5 gambar diperbolehkan'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          final spaceLeft = 5 - totalImages;
          _newImages.addAll(images.take(spaceLeft));
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking images: $e');
      }
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih kategori produk'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final name = _nameController.text.trim();
    final description = _descController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    final categoryId = _selectedCategoryId!;

    bool success;
    if (widget.productId != null) {
      success = await ref.read(productControllerProvider.notifier).updateProduct(
            id: widget.productId!,
            name: name,
            description: description,
            price: price,
            stock: stock,
            categoryId: categoryId,
            newImages: _newImages,
          );
      // Invalidate specific detail provider to see edits
      ref.invalidate(sellerProductDetailProvider(widget.productId!));
    } else {
      success = await ref.read(productControllerProvider.notifier).createProduct(
            name: name,
            description: description,
            price: price,
            stock: stock,
            categoryId: categoryId,
            images: _newImages,
          );
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.productId != null
                  ? 'Produk berhasil diperbarui'
                  : 'Produk berhasil ditambahkan',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(); // Go back
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan, silakan coba lagi'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(sellerCategoriesProvider);
    final isEdit = widget.productId != null;

    if (isEdit) {
      final detailState = ref.watch(sellerProductDetailProvider(widget.productId!));
      return detailState.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
        error: (err, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Produk')),
          body: ErrorStateWidget(
            errorMessage: err.toString(),
            onRetry: () => ref.invalidate(sellerProductDetailProvider(widget.productId!)),
          ),
        ),
        data: (product) {
          _populateForm(product);
          return _buildFormScaffold(categoriesState);
        },
      );
    }

    return _buildFormScaffold(categoriesState);
  }

  Widget _buildFormScaffold(AsyncValue<List<dynamic>> categoriesState) {
    final isEdit = widget.productId != null;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(
            title: Text(isEdit ? 'Edit Produk UMKM' : 'Tambah Produk Baru'),
            centerTitle: true,
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.base),
              children: [
                // Product Name Field
                Text(
                  'Nama Produk',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Kopi Bubuk Arabika 250gr',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama produk wajib diisi';
                    }
                    if (val.trim().length < 3) {
                      return 'Nama produk minimal 3 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Category Dropdown
                Text(
                  'Kategori Produk',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                categoriesState.when(
                  data: (categories) {
                    return DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      hint: const Text('Pilih Kategori'),
                      items: categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                        });
                      },
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (err, _) => Text(
                    'Gagal memuat kategori',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Row for Price & Stock
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Harga (Rp)',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: 15000',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Harga wajib diisi';
                              }
                              final price = double.tryParse(val.trim());
                              if (price == null || price <= 0) {
                                return 'Harga harus bernilai positif';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Stock
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jumlah Stok',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: 50',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Stok wajib diisi';
                              }
                              final stock = int.tryParse(val.trim());
                              if (stock == null || stock < 0) {
                                return 'Stok tidak boleh negatif';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Description
                Text(
                  'Deskripsi Produk',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: 'Jelaskan keunggulan, rasa, kemasan, atau detail produk Anda...',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Image Upload Area
                Text(
                  'Foto Produk (Maksimal 5 Foto)',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildImagePickerArea(),
                const SizedBox(height: AppSpacing.xl),

                // Submit Button
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: Text(
                    isEdit ? 'Simpan Perubahan' : 'Tambah Produk Sekarang',
                    style: AppTypography.buttonMd.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.section),
              ],
            ),
          ),
        ),
        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: LoadingWidget(message: 'Sedang menyimpan produk...'),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePickerArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: _pickImages,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary, width: 1.5, style: BorderStyle.none),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 28),
                    SizedBox(height: 4),
                    Text(
                      'Pilih Foto',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Render existing images (when editing)
                    ...List.generate(_existingImageUrls.length, (idx) {
                      final url = _existingImageUrls[idx];
                      return Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(
                                image: NetworkImage(url),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: AppColors.error, size: 20),
                            onPressed: () => _removeExistingImage(idx),
                          ),
                        ],
                      );
                    }),
                    // Render newly picked images
                    ...List.generate(_newImages.length, (idx) {
                      final file = _newImages[idx];
                      return Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(
                                image: FileImage(File(file.path)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: AppColors.error, size: 20),
                            onPressed: () => _removeNewImage(idx),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_existingImageUrls.isEmpty && _newImages.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Rekomendasi: Tambahkan minimal 1 foto produk',
            style: AppTypography.captionSmall.copyWith(color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}
