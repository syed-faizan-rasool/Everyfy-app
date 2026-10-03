import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../providers/admin_provider.dart';

class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final categories = admin.categories;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Manage Categories',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0D5C3A), size: 24),
            onPressed: () => _openAddCategoryDialog(context, admin),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, idx) {
          final cat = categories[idx];
          final productCount = admin.products.where((p) => p.categoryId == cat.id).length;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    cat.image,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(Icons.category_outlined, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$productCount products in stock',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                  onPressed: () => _openEditCategoryDialog(context, admin, cat),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openAddCategoryDialog(BuildContext context, AdminProvider admin) {
    final nameController = TextEditingController();
    final imageController = TextEditingController(
      text: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Category', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Category Name', hintText: 'e.g. Organic Herbs'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: imageController,
              decoration: const InputDecoration(labelText: 'Image URL', hintText: 'https://...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                admin.addCategory(
                  CategoryModel(
                    id: DateTime.now().millisecondsSinceEpoch,
                    name: nameController.text.trim(),
                    image: imageController.text.trim(),
                  ),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added category ${nameController.text.trim()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D5C3A)),
            child: const Text('Add Category'),
          ),
        ],
      ),
    );
  }

  void _openEditCategoryDialog(BuildContext context, AdminProvider admin, CategoryModel cat) {
    final nameController = TextEditingController(text: cat.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Category', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Category Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                admin.updateCategory(
                  CategoryModel(id: cat.id, name: nameController.text.trim(), image: cat.image),
                );
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D5C3A)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
