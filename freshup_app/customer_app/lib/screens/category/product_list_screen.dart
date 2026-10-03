import 'package:flutter/material.dart';
import '../../data/dummy_data.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/animated_widgets.dart';
import '../../widgets/product_card.dart';

class ProductListScreen extends StatefulWidget {
  final CategoryModel category;
  const ProductListScreen({super.key, required this.category});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late CategoryModel _selectedCategory;
  String _selectedFilter = 'All'; // 'All', 'Offers', 'Under Rs 200'

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category;
  }

  @override
  Widget build(BuildContext context) {
    List<ProductModel> products = DummyData.productsByCategory(_selectedCategory.id);

    if (_selectedFilter == 'Offers') {
      products = products.where((p) => p.hasDiscount).toList();
    } else if (_selectedFilter == 'Under Rs 200') {
      products = products.where((p) => p.finalPrice <= 200).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCategory.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Category selector horizontal strip
          Container(
            height: 52,
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: DummyData.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = DummyData.categories[i];
                final isSelected = cat.id == _selectedCategory.id;
                return BouncingButton(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                      _selectedFilter = 'All';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      ),
                    ),
                    child: Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Sub-filter tabs (All, Offers, Under Rs 200)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                _filterPill('All'),
                const SizedBox(width: 8),
                _filterPill('Offers'),
                const SizedBox(width: 8),
                _filterPill('Under Rs 200'),
              ],
            ),
          ),

          // Products Count Indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${products.length} Products available',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Product Grid or Empty State
          Expanded(
            child: products.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.inventory_2_outlined,
                    title: 'No products found',
                    description: 'There are no items matching this filter in ${_selectedCategory.name}.',
                    buttonText: 'Show All ${_selectedCategory.name}',
                    onButtonPressed: () {
                      setState(() => _selectedFilter = 'All');
                    },
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: products.length,
                    itemBuilder: (_, i) => ProductCard(
                      product: products[i],
                      heroPrefix: 'cat_${_selectedCategory.id}',
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterPill(String filter) {
    final isSelected = _selectedFilter == filter;
    return BouncingButton(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          filter,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
