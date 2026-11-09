import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_network_image.dart';
import 'admin_add_edit_product_screen.dart';

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  String _searchQuery = '';
  int _selectedCategoryId = 0; // 0 for All
  String _stockFilter = 'All'; // 'All', 'Low Stock', 'Out of Stock'

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final allProducts = admin.products;
    final categories = admin.categories;

    final filteredProducts = allProducts.where((p) {
      // Category filter
      if (_selectedCategoryId != 0 && p.categoryId != _selectedCategoryId) {
        return false;
      }

      // Stock status filter
      if (_stockFilter == 'Low Stock' && (p.stockQty > 10 || p.stockQty == 0)) {
        return false;
      }
      if (_stockFilter == 'Out of Stock' && p.stockQty > 0) {
        return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return p.name.toLowerCase().contains(q) || p.description.toLowerCase().contains(q);
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Inventory & Catalog',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF0D5C3A), size: 26),
            tooltip: 'Add Product',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminAddEditProductScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminAddEditProductScreen()),
          );
        },
        backgroundColor: const Color(0xFF0D5C3A),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Product', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: Column(
        children: [
          // Filter Controls Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Search bar
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search products by name...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),

                // Stock Status Tabs
                Row(
                  children: [
                    _buildStockTabPill('All (${allProducts.length})', 'All'),
                    const SizedBox(width: 8),
                    _buildStockTabPill(
                      'Low Stock (${allProducts.where((p) => p.stockQty <= 10 && p.stockQty > 0).length})',
                      'Low Stock',
                      activeColor: const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 8),
                    _buildStockTabPill(
                      'Out of Stock (${allProducts.where((p) => p.stockQty == 0).length})',
                      'Out of Stock',
                      activeColor: const Color(0xFFDC2626),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: const Text('All Categories', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          selected: _selectedCategoryId == 0,
                          selectedColor: const Color(0xFF1E293B),
                          labelStyle: TextStyle(
                            color: _selectedCategoryId == 0 ? Colors.white : const Color(0xFF475569),
                          ),
                          onSelected: (_) => setState(() => _selectedCategoryId = 0),
                        ),
                      ),
                      ...categories.map((c) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(c.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                              selected: _selectedCategoryId == c.id,
                              selectedColor: const Color(0xFF0D5C3A),
                              labelStyle: TextStyle(
                                color: _selectedCategoryId == c.id ? Colors.white : const Color(0xFF475569),
                              ),
                              onSelected: (_) => setState(() => _selectedCategoryId = c.id),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: filteredProducts.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                    itemCount: filteredProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final product = filteredProducts[idx];
                      return _buildProductCard(context, admin, product);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockTabPill(String label, String value, {Color activeColor = const Color(0xFF0D5C3A)}) {
    final isSelected = _stockFilter == value;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _stockFilter = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeColor : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? activeColor : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, AdminProvider admin, ProductModel product) {
    final category = admin.categories.firstWhere(
      (c) => c.id == product.categoryId,
      orElse: () => admin.categories.first,
    );

    final isLowStock = product.stockQty <= 10 && product.stockQty > 0;
    final isOutOfStock = product.stockQty == 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOutOfStock
              ? const Color(0xFFFECACA)
              : (isLowStock ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 64,
                  height: 64,
                  color: const Color(0xFFF8FAFC),
                  child: Center(
                    child: AppNetworkImage(
                      imageUrl: product.image,
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                      errorWidget: Container(
                        width: 64,
                        height: 64,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF64748B)),
                          padding: EdgeInsets.zero,
                          onSelected: (action) {
                            if (action == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminAddEditProductScreen(productToEdit: product),
                                ),
                              );
                            } else if (action == 'delete') {
                              _confirmDeleteProduct(context, admin, product);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 16, color: Color(0xFF2563EB)),
                                  SizedBox(width: 8),
                                  Text('Edit Details'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                                  SizedBox(width: 8),
                                  Text('Delete Product', style: TextStyle(color: Color(0xFFDC2626))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${category.name} · ${product.unit}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          product.finalPrice > 0
                              ? 'Rs ${product.finalPrice.toStringAsFixed(0)}'
                              : 'As per Market Rate',
                          style: TextStyle(
                            fontSize: product.finalPrice > 0 ? 15 : 12,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0D5C3A),
                          ),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 6),
                          Text(
                            'Rs ${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 18, color: Color(0xFFF1F5F9)),

          // Bottom Bar: Stock status & Quick +/- Stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Stock status badge
              _buildStockBadge(product.stockQty),

              // Inline Stepper
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, size: 16, color: Color(0xFF334155)),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      onPressed: product.stockQty > 0
                          ? () => admin.adjustStock(product.id, -1)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '${product.stockQty}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF0D5C3A)),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      onPressed: () => admin.adjustStock(product.id, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockBadge(int qty) {
    if (qty == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Out of Stock',
          style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w800),
        ),
      );
    } else if (qty <= 10) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Low Stock ($qty left)',
          style: const TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.w800),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'In Stock ($qty)',
        style: const TextStyle(color: Color(0xFF15803D), fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          const Text(
            'No matching products found',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          const Text('Try adjusting your search or category filter', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(BuildContext context, AdminProvider admin, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text('Are you sure you want to remove "${product.name}" from your catalog?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              admin.deleteProduct(product.id);
              context.read<CatalogProvider>().removeProduct(product.id);
              ApiService.adminDeleteProduct(product.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Removed ${product.name} from catalog')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
