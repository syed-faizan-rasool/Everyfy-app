class CategoryModel {
  final int id;
  final String name;
  final String image;

  CategoryModel({required this.id, required this.name, required this.image});

  static const List<int> preferredOrder = [
    9,  // Gojra special
    6,  // Entertainment
    3,  // Breakfast - dairy
    16, // Vegetables
    10, // Grossery
    11, // Health & beauty
    1,  // Baby care
    4,  // Dry fruits
    15, // Sweets
    2,  // Beverages
    12, // House hold
    13, // Personal care
    14, // Stationary
    5,  // Electronics
    8,  // Fruits
    7,  // Fast Food
  ];

  static int compareByPreferredOrder(CategoryModel a, CategoryModel b) {
    final idxA = preferredOrder.indexOf(a.id);
    final idxB = preferredOrder.indexOf(b.id);
    final orderA = idxA >= 0 ? idxA : 999;
    final orderB = idxB >= 0 ? idxB : 999;
    return orderA.compareTo(orderB);
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      image: json['image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
    };
  }
}
