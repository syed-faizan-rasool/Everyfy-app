import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/meta_analytics_service.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItemModel> _items = {}; // key: itemKey

  List<CartItemModel> get items => _items.values.toList();
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.values.fold(0.0, (sum, item) => sum + item.subtotal);
  bool get isEmpty => _items.isEmpty;

  /// Total quantity of a product in the cart across all its size variants
  int quantityOf(int productId) {
    return _items.values
        .where((item) => item.product.id == productId)
        .fold(0, (sum, item) => sum + item.quantity);
  }

  /// Specific quantity of a size variant
  int quantityOfVariant(int productId, String? size) {
    final key = '${productId}_${size ?? "default"}';
    return _items[key]?.quantity ?? 0;
  }

  void addToCart(
    ProductModel product, {
    String? size,
    double? price,
    String? instructions,
    int quantity = 1,
  }) {
    final key = '${product.id}_${size ?? "default"}';
    if (_items.containsKey(key)) {
      _items[key]!.quantity += quantity;
    } else {
      _items[key] = CartItemModel(
        product: product,
        quantity: quantity,
        selectedSize: size,
        customPrice: price,
        instructions: instructions,
      );
    }
    // Meta Tracking Event: AddToCart
    MetaAnalyticsService.logAddToCart(
      id: product.id.toString(),
      title: product.name,
      price: price ?? product.effectivePrice,
      quantity: quantity,
      currency: 'PKR',
    );
    notifyListeners();
  }

  void decreaseQuantity(ProductModel product, {String? size}) {
    final key = '${product.id}_${size ?? "default"}';
    if (_items.containsKey(key)) {
      if (_items[key]!.quantity > 1) {
        _items[key]!.quantity--;
      } else {
        _items.remove(key);
      }
      notifyListeners();
      return;
    }

    // Fallback: decrease first matching item with this product ID
    final matchingKey = _items.keys.firstWhere(
      (k) => _items[k]!.product.id == product.id,
      orElse: () => '',
    );
    if (matchingKey.isNotEmpty) {
      if (_items[matchingKey]!.quantity > 1) {
        _items[matchingKey]!.quantity--;
      } else {
        _items.remove(matchingKey);
      }
      notifyListeners();
    }
  }

  void decreaseCartItem(CartItemModel item) {
    final key = item.itemKey;
    if (_items.containsKey(key)) {
      if (_items[key]!.quantity > 1) {
        _items[key]!.quantity--;
      } else {
        _items.remove(key);
      }
      notifyListeners();
    }
  }

  void removeItem(int productId) {
    _items.removeWhere((_, item) => item.product.id == productId);
    notifyListeners();
  }

  void removeCartItem(CartItemModel item) {
    _items.remove(item.itemKey);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
