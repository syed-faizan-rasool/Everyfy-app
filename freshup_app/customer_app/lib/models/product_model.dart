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
  });

  double get finalPrice => discountPrice ?? price;
  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  bool get inStock => stockQty > 0;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      price: double.parse(json['price'].toString()),
      discountPrice: json['discount_price'] != null
          ? double.parse(json['discount_price'].toString())
          : null,
      unit: json['unit'] ?? '',
      stockQty: json['stock_qty'] ?? 0,
    );
  }
}
