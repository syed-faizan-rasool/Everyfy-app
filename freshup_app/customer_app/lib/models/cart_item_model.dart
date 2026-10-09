import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;

  CartItemModel({required this.product, this.quantity = 1});

  double get subtotal => product.finalPrice * quantity;

  Map<String, dynamic> toJson() {
    return {
      'product_id': product.id,
      'name': product.name,
      'price': product.finalPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('product') && json['product'] is Map) {
      return CartItemModel(
        product: ProductModel.fromJson(Map<String, dynamic>.from(json['product'])),
        quantity: json['quantity'] ?? 1,
      );
    }
    return CartItemModel(
      product: ProductModel(
        id: json['product_id'] ?? json['id'] ?? 0,
        categoryId: json['category_id'] ?? 1,
        name: json['name'] ?? json['product_name'] ?? 'Item',
        description: json['description'] ?? '',
        image: json['image'] ?? '',
        price: double.parse((json['price'] ?? json['product_price'] ?? 0).toString()),
        unit: json['unit'] ?? '',
        stockQty: json['stock_qty'] ?? 10,
      ),
      quantity: json['quantity'] ?? 1,
    );
  }
}
