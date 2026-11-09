class ProductSizeOption {
  final String name;
  final double price;
  final String? subtitle;

  const ProductSizeOption({
    required this.name,
    required this.price,
    this.subtitle,
  });

  factory ProductSizeOption.fromJson(Map<String, dynamic> json) {
    return ProductSizeOption(
      name: json['name']?.toString() ?? '',
      price: double.tryParse((json['price'] ?? 0).toString()) ?? 0.0,
      subtitle: json['subtitle']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      if (subtitle != null) 'subtitle': subtitle,
    };
  }
}

class ProductModel {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final String image;
  final double price;
  final double? discountPrice;
  final String unit; // e.g. "1 kg", "500 g", "1 pcs"
  final int stockQty;
  final List<ProductSizeOption> sizes;

  ProductModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.image,
    required this.price,
    this.discountPrice,
    required this.unit,
    required this.stockQty,
    this.sizes = const [],
  });

  ProductModel copyWith({
    int? id,
    int? categoryId,
    String? name,
    String? description,
    String? image,
    double? price,
    double? discountPrice,
    String? unit,
    int? stockQty,
    List<ProductSizeOption>? sizes,
  }) {
    return ProductModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      unit: unit ?? this.unit,
      stockQty: stockQty ?? this.stockQty,
      sizes: sizes ?? this.sizes,
    );
  }

  double get finalPrice => discountPrice ?? price;
  double get effectivePrice => finalPrice;
  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  bool get inStock => stockQty > 0;
  bool get isFeatured => hasDiscount;
  bool get isPriceDecided => price > 0;
  String get formattedPrice => isPriceDecided ? 'Rs ${finalPrice.toStringAsFixed(0)}' : 'Rs: as per market price';

  /// Returns sizes configured for this product, or generates standard sensible sizes
  /// (500g, 1 kg, 2 kg, 3 kg, 4 kg, 5 kg) scaled from base price if none are provided.
  List<ProductSizeOption> get effectiveSizes {
    if (sizes.isNotEmpty) return sizes;

    final base = finalPrice;
    final u = unit.toLowerCase();
    final n = name.toLowerCase();

    // Dozen / Egg based products
    if (u.contains('dozen') || n.contains('egg') || n.contains('ande')) {
      return [
        ProductSizeOption(
          name: 'Half Dozen (6 Pcs)',
          price: base > 0 ? (base * 0.5) : 0.0,
          subtitle: '6 pieces',
        ),
        ProductSizeOption(
          name: '1 Dozen (12 Pcs)',
          price: base > 0 ? base : 0.0,
          subtitle: '12 pieces standard',
        ),
        ProductSizeOption(
          name: '2 Dozen (24 Pcs)',
          price: base > 0 ? (base * 2.0) : 0.0,
          subtitle: '24 pieces saver',
        ),
      ];
    }

    // Fast food, beverages by cup/glass, or single servings
    if (u.contains('cup') || u.contains('glass') || u.contains('plate') || categoryId == 7) {
      return [
        ProductSizeOption(
          name: 'Regular',
          price: base > 0 ? base : 0.0,
          subtitle: 'Standard Serving',
        ),
        ProductSizeOption(
          name: 'Medium',
          price: base > 0 ? (base * 1.5) : 0.0,
          subtitle: 'Medium Serving',
        ),
        ProductSizeOption(
          name: 'Large',
          price: base > 0 ? (base * 2.0) : 0.0,
          subtitle: 'Large / Jumbo Serving',
        ),
      ];
    }

    // Default for ALL Vegetables, Fruits, Dry fruits, Grossery, Meat, Fresh Produce, and general grocery:
    // 500g, 1 kg, 2 kg, 5 kg (3 kg and 4 kg removed per user requirement)
    return [
      ProductSizeOption(
        name: '500g',
        price: base > 0 ? (base * 0.5) : 0.0,
        subtitle: 'Half kg (0.5 kg)',
      ),
      ProductSizeOption(
        name: '1 kg',
        price: base > 0 ? base : 0.0,
        subtitle: 'Standard 1 kg',
      ),
      ProductSizeOption(
        name: '2 kg',
        price: base > 0 ? (base * 2.0) : 0.0,
        subtitle: 'Value Pack (2 kg)',
      ),
      ProductSizeOption(
        name: '5 kg',
        price: base > 0 ? (base * 5.0) : 0.0,
        subtitle: 'Family Saver (5 kg)',
      ),
    ];
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<ProductSizeOption> parsedSizes = [];
    if (json['sizes'] is List) {
      parsedSizes = (json['sizes'] as List)
          .map((s) => ProductSizeOption.fromJson(Map<String, dynamic>.from(s)))
          .toList();
    } else if (json['variants'] is List) {
      parsedSizes = (json['variants'] as List)
          .map((s) => ProductSizeOption.fromJson(Map<String, dynamic>.from(s)))
          .toList();
    }

    final priceVal = double.tryParse((json['price'] ?? 0).toString()) ?? 0.0;
    final discountVal = json['discount_price'] != null
        ? double.tryParse(json['discount_price'].toString())
        : null;

    return ProductModel(
      id: json['id'] is int ? json['id'] : int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse((json['category_id'] ?? 0).toString()) ?? 1,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      price: priceVal,
      discountPrice: discountVal,
      unit: json['unit']?.toString() ?? '',
      stockQty: json['stock_qty'] is int ? json['stock_qty'] : int.tryParse((json['stock_qty'] ?? 0).toString()) ?? 0,
      sizes: parsedSizes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'image': image,
      'price': price,
      'discount_price': discountPrice,
      'unit': unit,
      'stock_qty': stockQty,
      'sizes': sizes.map((s) => s.toJson()).toList(),
    };
  }
}
