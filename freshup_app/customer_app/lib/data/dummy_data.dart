import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/address_model.dart';

/// TEMPORARY dummy data so the UI can be built and tested without the
/// PHP backend being ready yet. Replace with real ApiService calls later.
class DummyData {
  static final List<CategoryModel> categories = [
    CategoryModel(
      id: 1,
      name: 'Fruits',
      image: 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=400',
    ),
    CategoryModel(
      id: 2,
      name: 'Vegetables',
      image: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400',
    ),
    CategoryModel(
      id: 3,
      name: 'Dairy & Eggs',
      image: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400',
    ),
    CategoryModel(
      id: 4,
      name: 'Bakery',
      image: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400',
    ),
    CategoryModel(
      id: 5,
      name: 'Beverages',
      image: 'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=400',
    ),
    CategoryModel(
      id: 6,
      name: 'Snacks',
      image: 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=400',
    ),
  ];

  static final List<ProductModel> products = [
    ProductModel(
      id: 1,
      categoryId: 1,
      name: 'Fresh Red Apples',
      description: 'Crisp, sweet, and handpicked Royal Gala apples directly sourced from premium orchards. Rich in dietary fiber and vitamins.',
      image: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=500',
      price: 350,
      discountPrice: 299,
      unit: '1 kg',
      stockQty: 40,
    ),
    ProductModel(
      id: 2,
      categoryId: 1,
      name: 'Cavendish Bananas',
      description: 'Naturally ripened, potassium-packed fresh yellow bananas. Perfect for morning smoothies, snacking, and quick energy.',
      image: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=500',
      price: 160,
      discountPrice: 140,
      unit: '1 dozen',
      stockQty: 60,
    ),
    ProductModel(
      id: 3,
      categoryId: 2,
      name: 'Organic Vine Tomatoes',
      description: 'Juicy, farm-fresh vine-ripened red tomatoes. Ideal for gourmet salads, traditional gravies, and fresh sauces.',
      image: 'https://images.unsplash.com/photo-1546470427-e5380b43d2d0?w=500',
      price: 120,
      unit: '1 kg',
      stockQty: 25,
    ),
    ProductModel(
      id: 4,
      categoryId: 2,
      name: 'Premium Russet Potatoes',
      description: 'Freshly harvested, washed, high-grade baking and frying potatoes with smooth skin and consistent texture.',
      image: 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=500',
      price: 90,
      unit: '1 kg',
      stockQty: 100,
    ),
    ProductModel(
      id: 5,
      categoryId: 3,
      name: 'Farm Fresh Full Cream Milk',
      description: 'Pure, pasteurized whole milk with rich natural goodness, vitamins, and calcium. Bottled under sterile conditions.',
      image: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=500',
      price: 240,
      discountPrice: 210,
      unit: '1 litre',
      stockQty: 30,
    ),
    ProductModel(
      id: 6,
      categoryId: 3,
      name: 'Aged Cheddar Cheese',
      description: 'Rich and creamy sharp cheddar cheese block. Made from grass-fed cows milk and cured to perfection.',
      image: 'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=500',
      price: 480,
      discountPrice: 420,
      unit: '200 g',
      stockQty: 15,
    ),
    ProductModel(
      id: 7,
      categoryId: 4,
      name: 'Artisan Whole Wheat Bread',
      description: 'Soft, freshly baked 100% whole grain loaf with a golden crust. High in fiber with zero artificial preservatives.',
      image: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500',
      price: 180,
      unit: '1 loaf (450g)',
      stockQty: 20,
    ),
    ProductModel(
      id: 8,
      categoryId: 5,
      name: 'Freshly Squeezed Orange Juice',
      description: '100% pure cold-pressed orange juice without added sugars or artificial flavors. Loaded with natural Vitamin C.',
      image: 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=500',
      price: 320,
      discountPrice: 280,
      unit: '1 litre',
      stockQty: 18,
    ),
    ProductModel(
      id: 9,
      categoryId: 6,
      name: 'Crunchy Salted Potato Crisps',
      description: 'Thinly sliced golden potato chips lightly seasoned with natural sea salt for the ultimate crispy crunch.',
      image: 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=500',
      price: 120,
      unit: '150 g',
      stockQty: 50,
    ),
    ProductModel(
      id: 10,
      categoryId: 1,
      name: 'Fresh Farm Strawberries',
      description: 'Sweet, juicy, freshly picked red strawberries packed with antioxidants.',
      image: 'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=500',
      price: 290,
      discountPrice: 250,
      unit: '250 g',
      stockQty: 30,
    ),
    ProductModel(
      id: 11,
      categoryId: 1,
      name: 'Pakistani Sindhri Mangoes',
      description: 'Aromatic, honey-sweet Sindhri mangoes known for their succulent flavor.',
      image: 'https://images.unsplash.com/photo-1553279768-865429fa0078?w=500',
      price: 450,
      discountPrice: 390,
      unit: '1 kg',
      stockQty: 40,
    ),
    ProductModel(
      id: 12,
      categoryId: 2,
      name: 'Farm Fresh Red Onions',
      description: 'Firm, pungent, and crisp red cooking onions directly sourced from local farms.',
      image: 'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?w=500',
      price: 140,
      unit: '1 kg',
      stockQty: 75,
    ),
    ProductModel(
      id: 13,
      categoryId: 2,
      name: 'Crisp Green Cucumbers',
      description: 'Hydrating, crunchy salad cucumbers freshly harvested and hand-selected.',
      image: 'https://images.unsplash.com/photo-1449300079323-02e209d9d3a6?w=500',
      price: 80,
      unit: '1 kg',
      stockQty: 45,
    ),
    ProductModel(
      id: 14,
      categoryId: 3,
      name: 'Farm Fresh Desi Eggs',
      description: 'Free-range, protein-packed brown farm eggs. Carefully inspected and safely crated.',
      image: 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=500',
      price: 360,
      discountPrice: 330,
      unit: '1 dozen (12 pcs)',
      stockQty: 60,
    ),
    ProductModel(
      id: 15,
      categoryId: 4,
      name: 'Fresh Butter Croissants',
      description: 'Flaky, buttery French-style breakfast croissants baked fresh every morning.',
      image: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=500',
      price: 240,
      discountPrice: 200,
      unit: 'Pack of 2',
      stockQty: 25,
    ),
    ProductModel(
      id: 16,
      categoryId: 5,
      name: 'Pure Natural Apple Juice',
      description: 'Refreshing cloudy apple juice pressed from sweet orchard apples. No added sugar.',
      image: 'https://images.unsplash.com/photo-1568644396922-5c3bfae12521?w=500',
      price: 280,
      unit: '1 litre',
      stockQty: 20,
    ),
    ProductModel(
      id: 17,
      categoryId: 6,
      name: 'Roasted Salted Almonds',
      description: 'Crunchy Californian almonds gently roasted with Himalayan pink salt.',
      image: 'https://images.unsplash.com/photo-1508061252445-564b6f79c98a?w=500',
      price: 550,
      discountPrice: 490,
      unit: '200 g',
      stockQty: 35,
    ),
  ];

  static final List<AddressModel> addresses = [
    AddressModel(
      id: 1,
      label: 'Home',
      addressLine: 'House 12, Street 5',
      area: 'DHA Phase 6',
      city: 'Lahore',
      isDefault: true,
    ),
    AddressModel(
      id: 2,
      label: 'Office',
      addressLine: 'Office 304, Business Tower',
      area: 'Gulberg III',
      city: 'Lahore',
    ),
    AddressModel(
      id: 3,
      label: 'Parents',
      addressLine: 'Villa 44, Block C',
      area: 'Model Town',
      city: 'Lahore',
    ),
  ];

  static List<ProductModel> productsByCategory(int categoryId) {
    return products.where((p) => p.categoryId == categoryId).toList();
  }

  static List<ProductModel> searchProducts(String query) {
    if (query.trim().isEmpty) return products;
    final q = query.toLowerCase().trim();
    return products.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.unit.toLowerCase().contains(q);
    }).toList();
  }
}
