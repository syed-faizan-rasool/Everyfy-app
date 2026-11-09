import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  final String? selectedSize;
  final double? customPrice;
  final String? instructions;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    this.selectedSize,
    this.customPrice,
    this.instructions,
  });

  double get unitPrice => customPrice ?? product.finalPrice;
  double get subtotal => unitPrice * quantity;
  String get itemKey => '${product.id}_${selectedSize ?? "default"}';

  String get displayName {
    if (selectedSize != null && selectedSize!.isNotEmpty) {
      return '${product.name} ($selectedSize)';
    }
    return product.name;
  }

  Map<String, dynamic> toJson() {
    String formattedName = displayName;
    if (instructions != null && instructions!.trim().isNotEmpty) {
      formattedName += ' [Note: ${instructions!.trim()}]';
    }
    return {
      'product_id': product.id,
      'name': formattedName,
      'product_name': formattedName,
      'price': unitPrice,
      'product_price': unitPrice,
      'quantity': quantity,
      'subtotal': subtotal,
      'size': selectedSize,
      'instructions': instructions,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final parsedSize = json['size']?.toString() ?? json['selected_size']?.toString();
    final parsedInstructions = json['instructions']?.toString() ?? json['special_instructions']?.toString();
    final parsedPrice = json['price'] != null
        ? double.tryParse(json['price'].toString())
        : (json['product_price'] != null ? double.tryParse(json['product_price'].toString()) : null);

    if (json.containsKey('product') && json['product'] is Map) {
      return CartItemModel(
        product: ProductModel.fromJson(Map<String, dynamic>.from(json['product'])),
        quantity: json['quantity'] ?? 1,
        selectedSize: parsedSize,
        customPrice: parsedPrice,
        instructions: parsedInstructions,
      );
    }
    return CartItemModel(
      product: ProductModel(
        id: json['product_id'] ?? json['id'] ?? 0,
        categoryId: json['category_id'] ?? 1,
        name: json['name'] ?? json['product_name'] ?? 'Item',
        description: json['description'] ?? '',
        image: json['image'] ?? '',
        price: parsedPrice ?? 0.0,
        unit: json['unit'] ?? '',
        stockQty: json['stock_qty'] ?? 10,
      ),
      quantity: json['quantity'] ?? 1,
      selectedSize: parsedSize,
      customPrice: parsedPrice,
      instructions: parsedInstructions,
    );
  }
}
