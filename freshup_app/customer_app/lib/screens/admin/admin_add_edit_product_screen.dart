import 'dart:io';
import '../../widgets/image_picker_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_network_image.dart';

class AdminAddEditProductScreen extends StatefulWidget {
  final ProductModel? productToEdit;

  const AdminAddEditProductScreen({super.key, this.productToEdit});

  @override
  State<AdminAddEditProductScreen> createState() => _AdminAddEditProductScreenState();
}

class _AdminAddEditProductScreenState extends State<AdminAddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _discountPriceController;
  late TextEditingController _unitController;
  late TextEditingController _stockController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageController;

  int _selectedCategoryId = 1;

  final List<Map<String, String>> _presetImages = [
    {'title': 'Apples', 'url': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=500'},
    {'title': 'Bananas', 'url': 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=500'},
    {'title': 'Tomatoes', 'url': 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=500'},
    {'title': 'Potatoes', 'url': 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=500'},
    {'title': 'Milk', 'url': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=500'},
    {'title': 'Eggs', 'url': 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=500'},
    {'title': 'Bread', 'url': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500'},
    {'title': 'Juice', 'url': 'https://images.unsplash.com/photo-1613478223719-2ab802602423?w=500'},
    {'title': 'Honey', 'url': 'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=500'},
    {'title': 'Cheese', 'url': 'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=500'},
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;

    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController = TextEditingController(text: p != null ? p.price.toStringAsFixed(0) : '');
    _discountPriceController = TextEditingController(
      text: p?.discountPrice != null ? p!.discountPrice!.toStringAsFixed(0) : '',
    );
    _unitController = TextEditingController(text: p?.unit ?? '1 kg');
    _stockController = TextEditingController(text: p != null ? p.stockQty.toString() : '25');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _imageController = TextEditingController(
      text: p?.image ?? 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=500',
    );

    if (p != null) {
      _selectedCategoryId = p.categoryId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) return;

    final admin = context.read<AdminProvider>();
    final catalog = context.read<CatalogProvider>();
    final isEditing = widget.productToEdit != null;

    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final discountPrice = _discountPriceController.text.trim().isNotEmpty
        ? double.tryParse(_discountPriceController.text.trim())
        : null;
    final unit = _unitController.text.trim().isNotEmpty ? _unitController.text.trim() : '1 kg';
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    final description = _descriptionController.text.trim();
    final image = _imageController.text.trim();

    if (isEditing) {
      final updated = ProductModel(
        id: widget.productToEdit!.id,
        categoryId: _selectedCategoryId,
        name: name,
        description: description,
        image: image,
        price: price,
        discountPrice: discountPrice,
        unit: unit,
        stockQty: stock,
        sizes: widget.productToEdit!.sizes,
      );
      admin.updateProduct(updated);
      catalog.upsertProduct(updated);

      ApiService.adminSaveProduct({
        'id': widget.productToEdit!.id,
        'category_id': _selectedCategoryId,
        'name': name,
        'description': description,
        'price': price,
        'discount_price': discountPrice,
        'unit': unit,
        'stock_qty': stock,
        'image': image,
        'is_available': 1,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated $name successfully (Live across store)')),
      );
    } else {
      final tempId = DateTime.now().millisecondsSinceEpoch % 100000;
      final newProduct = ProductModel(
        id: tempId,
        categoryId: _selectedCategoryId,
        name: name,
        description: description,
        image: image,
        price: price,
        discountPrice: discountPrice,
        unit: unit,
        stockQty: stock,
      );
      admin.addProduct(newProduct);
      catalog.upsertProduct(newProduct);

      ApiService.adminSaveProduct({
        'category_id': _selectedCategoryId,
        'name': name,
        'description': description,
        'price': price,
        'discount_price': discountPrice,
        'unit': unit,
        'stock_qty': stock,
        'image': image,
        'is_available': 1,
      }).then((res) {
        if (res['success'] == true && res['data'] != null && res['data']['id'] != null) {
          final realId = int.tryParse(res['data']['id'].toString());
          if (realId != null) {
            catalog.upsertProduct(newProduct.copyWith(id: realId));
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $name to catalog (Live across store)')),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;
    final categories = context.watch<AdminProvider>().categories;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Product' : 'Add New Product',
          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 17),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Preview & Picker
              _buildImageSection(),
              const SizedBox(height: 18),

              // Product Info Form Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Product Name *'),
                    TextFormField(
                      controller: _nameController,
                      validator: (v) => v == null || v.isEmpty ? 'Enter product name' : null,
                      decoration: _buildInputDecoration('e.g. Royal Gala Apples'),
                    ),
                    const SizedBox(height: 16),

                    _buildFieldLabel('Category *'),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedCategoryId,
                      items: categories.map((c) {
                        return DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategoryId = val);
                      },
                      decoration: _buildInputDecoration(''),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Price (Rs) · 0 for Market Rate'),
                              TextFormField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                decoration: _buildInputDecoration('0 (As per Market Rate)'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Discount Price (Rs)'),
                              TextFormField(
                                controller: _discountPriceController,
                                keyboardType: TextInputType.number,
                                decoration: _buildInputDecoration('Optional (299)'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Unit / Pack *'),
                              TextFormField(
                                controller: _unitController,
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                decoration: _buildInputDecoration('1 kg / 500 g / 1 pcs'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Stock Quantity *'),
                              TextFormField(
                                controller: _stockController,
                                keyboardType: TextInputType.number,
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                decoration: _buildInputDecoration('40'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildFieldLabel('Description'),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: _buildInputDecoration('Freshly sourced from verified local farms...'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D5C3A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                  ),
                  child: Text(
                    isEditing ? 'Update Product' : 'Add to Store Catalog',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Product Image *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              InkWell(
                onTap: () => _showImageSourceModal(context),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.collections_rounded, size: 14, color: Color(0xFF0D5C3A)),
                      SizedBox(width: 4),
                      Text(
                        'Browse Catalog',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0D5C3A)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tap Image to Pick
              GestureDetector(
                onTap: () => _showImageSourceModal(context),
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _imageController.text.isNotEmpty
                          ? (_imageController.text.startsWith('http') || _imageController.text.startsWith('assets/') || _imageController.text.startsWith('uploads/')
                              ? AppNetworkImage(
                                  imageUrl: _imageController.text,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  borderRadius: 16,
                                )
                              : Image.file(
                                  File(_imageController.text),
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ))
                          : const Center(
                              child: Icon(Icons.add_photo_alternate_rounded, size: 36, color: Color(0xFF94A3B8)),
                            ),
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D5C3A),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showImageSourceModal(context),
                      icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                      label: const Text(
                        'Upload / Pick from Phone',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D5C3A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap to choose phone photo, file, or 25+ grocery presets',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Quick HD Studio Presets:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _presetImages.map((p) {
                final isSelected = _imageController.text == p['url'];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    selected: isSelected,
                    selectedColor: const Color(0xFFDCFCE7),
                    label: Text(
                      p['title']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? const Color(0xFF0D5C3A) : const Color(0xFF334155),
                      ),
                    ),
                    backgroundColor: const Color(0xFFF1F5F9),
                    onSelected: (_) {
                      setState(() => _imageController.text = p['url']!);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _imageController,
            onChanged: (val) => setState(() {}),
            decoration: _buildInputDecoration('Image URL or Path (assets/... or https://...)'),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

    void _showImageSourceModal(BuildContext context) {
    ImagePickerHelper.showImageSourceSheet(
      context: context,
      folder: 'products',
      onImageSelected: (file, uploadedUrl) {
        setState(() {
          _imageController.text = uploadedUrl ?? file.path;
        });
      },
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0D5C3A), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
