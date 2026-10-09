import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

/// Real-time Catalog Provider for Live Banners, Categories & Products
class CatalogProvider extends ChangeNotifier {
  List<CategoryModel> _categories = [];
  List<ProductModel> _products = [];
  List<BannerModel> _banners = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  int? _selectedCategoryId;

  CatalogProvider() {
    // Initialize with dummy fallback first to avoid blank screen, then fetch live data
    _categories = List.from(DummyData.categories);
    _products = List.from(DummyData.products);
    fetchCatalog();
  }

  List<CategoryModel> get categories => _categories;
  List<ProductModel> get products => _products;
  List<BannerModel> get banners => _banners;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;

  List<ProductModel> get featuredProducts =>
      _products.where((p) => p.isFeatured || (p.discountPrice != null && p.discountPrice! < p.price)).toList();

  List<ProductModel> get filteredProducts {
    List<ProductModel> list = _products;
    if (_selectedCategoryId != null) {
      list = list.where((p) => p.categoryId == _selectedCategoryId).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.unit.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  List<ProductModel> productsByCategory(int categoryId) {
    return _products.where((p) => p.categoryId == categoryId).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  /// Live Sync from Hostinger Backend
  Future<void> fetchCatalog() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        ApiService.getCategories(),
        ApiService.getProducts(),
        ApiService.getBanners(),
      ]);

      final liveCategories = results[0] as List<CategoryModel>;
      final liveProducts = results[1] as List<ProductModel>;
      final liveBanners = results[2] as List<BannerModel>;

      if (liveCategories.isNotEmpty) {
        _categories = liveCategories;
      }
      if (liveProducts.isNotEmpty) {
        _products = liveProducts;
      }
      if (liveBanners.isNotEmpty) {
        _banners = liveBanners;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
