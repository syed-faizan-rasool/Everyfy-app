import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  final Map<int, CartItemModel> _items = {}; // key: product.id

  List<CartItemModel> get items => _items.values.toList();
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.values.fold(0.0, (sum, item) => sum + item.subtotal);
  bool get isEmpty => _items.isEmpty;

  int quantityOf(int productId) => _items[productId]?.quantity ?? 0;

  void addToCart(ProductModel product) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity++;
    } else {
      _items[product.id] = CartItemModel(product: product);
    }
    notifyListeners();
  }

  void decreaseQuantity(ProductModel product) {
    if (!_items.containsKey(product.id)) return;
    if (_items[product.id]!.quantity > 1) {
      _items[product.id]!.quantity--;
    } else {
      _items.remove(product.id);
    }
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
