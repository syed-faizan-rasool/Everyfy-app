import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/address_model.dart';
import '../models/cart_item_model.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../models/delivery_order_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';

/// Centralized API Service for Everyfy Mobile App
/// Communicates with Hostinger backend at https://everyfy.net/api
class ApiService {
  static const String defaultBaseUrl = 'https://everyfy.net/api';
  static String _baseUrl = defaultBaseUrl;
  static String? _authToken;

  static void setBaseUrl(String url) {
    _baseUrl = url.replaceAll(RegExp(r'/+$'), '');
  }

  static String get baseUrl => _baseUrl;

  static void setAuthToken(String? token) {
    _authToken = token;
  }

  static String? get authToken => _authToken;

  static Map<String, String> _headers() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // -------------------------------------------------------------
  // Authentication APIs
  // -------------------------------------------------------------

  /// Request OTP for customer phone
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/send_otp.php'),
        headers: _headers(),
        body: jsonEncode({'phone': phone}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Verify OTP code and obtain JWT bearer token
  static Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/verify_otp.php'),
        headers: _headers(),
        body: jsonEncode({'phone': phone, 'otp': otp}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['data'] != null) {
        if (data['data']['token'] != null) {
          _authToken = data['data']['token'];
        }
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Login with phone and password (Customer, Rider, or Admin)
  static Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    String role = 'customer',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/login.php'),
        headers: _headers(),
        body: jsonEncode({
          'identifier': identifier,
          'password': password,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['data'] != null) {
        if (data['data']['token'] != null) {
          _authToken = data['data']['token'];
        }
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // -------------------------------------------------------------
  // Product Catalog & Category APIs
  // -------------------------------------------------------------

  /// Fetch active categories
  static Future<List<CategoryModel>> getCategories() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/categories/index.php'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List)
            .map((c) => CategoryModel.fromJson(Map<String, dynamic>.from(c)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Fetch products with optional filters
  static Future<List<ProductModel>> getProducts({
    int? categoryId,
    String? search,
    bool? featured,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (categoryId != null) queryParams['category_id'] = categoryId.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (featured != null) queryParams['featured'] = featured ? '1' : '0';

      final uri = Uri.parse('$_baseUrl/products/index.php').replace(queryParameters: queryParams);
      final res = await http.get(uri, headers: _headers()).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List)
            .map((p) => ProductModel.fromJson(Map<String, dynamic>.from(p)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Apply promo coupon code
  static Future<Map<String, dynamic>> applyCoupon(String code, double subtotal) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/coupons/apply.php'),
        headers: _headers(),
        body: jsonEncode({'code': code, 'subtotal': subtotal}),
      ).timeout(const Duration(seconds: 10));

      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // -------------------------------------------------------------
  // Customer Address APIs
  // -------------------------------------------------------------

  /// Fetch customer's saved addresses
  static Future<List<AddressModel>> getAddresses() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/addresses/index.php'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List)
            .map((a) => AddressModel.fromJson(Map<String, dynamic>.from(a)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Save new customer address
  static Future<AddressModel?> saveAddress(AddressModel address) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/addresses/index.php'),
        headers: _headers(),
        body: jsonEncode(address.toJson()),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['data'] != null) {
        return AddressModel.fromJson(Map<String, dynamic>.from(data['data']));
      }
    } catch (_) {}
    return null;
  }

  // -------------------------------------------------------------
  // Order APIs
  // -------------------------------------------------------------

  /// Place grocery checkout order
  static Future<Map<String, dynamic>> checkoutOrder({
    required List<CartItemModel> items,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required double total,
    required String paymentMethod,
    required String orderType,
    required String addressText,
    String? notes,
    String? couponCode,
    String? customerName,
    String? customerPhone,
  }) async {
    try {
      final body = {
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'discount': discount,
        'total': total,
        'payment_method': paymentMethod,
        'order_type': orderType,
        'address_text': addressText,
        'notes': notes,
        'coupon_code': couponCode,
        'customer_name': customerName,
        'customer_phone': customerPhone,
      };

      final res = await http.post(
        Uri.parse('$_baseUrl/orders/checkout.php'),
        headers: _headers(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Fetch customer order history
  static Future<List<OrderModel>> getOrders() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/orders/index.php'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List)
            .map((o) => OrderModel.fromJson(Map<String, dynamic>.from(o)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Get single order details with status tracking
  static Future<Map<String, dynamic>> getOrderDetail(String orderNumberOrId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/orders/detail.php?order_number=$orderNumberOrId'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 10));

      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // -------------------------------------------------------------
  // Delivery Boy / Rider APIs
  // -------------------------------------------------------------

  /// Rider Login
  static Future<Map<String, dynamic>> riderLogin(String phone, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/delivery/login.php'),
        headers: _headers(),
        body: jsonEncode({'phone': phone, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['data'] != null) {
        if (data['data']['token'] != null) {
          _authToken = data['data']['token'];
        }
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Fetch available unassigned orders for riders
  static Future<List<DeliveryOrderModel>> getRiderAvailableOrders() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/delivery/orders/available.php'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List)
            .map((o) => DeliveryOrderModel.fromJson(Map<String, dynamic>.from(o)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Accept order for delivery
  static Future<bool> riderAcceptOrder(String orderId) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/delivery/orders/accept.php'),
        headers: _headers(),
        body: jsonEncode({'order_id': orderId}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      return data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Update order status (picked_up -> on_the_way -> delivered)
  static Future<bool> riderUpdateStatus(String orderId, String status, {String? notes}) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/delivery/orders/status.php'),
        headers: _headers(),
        body: jsonEncode({
          'order_id': orderId,
          'status': status,
          'notes': notes ?? '',
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      return data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Fetch promotional banners
  static Future<List<BannerModel>> getBanners() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/banners/index.php'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List)
            .map((b) => BannerModel.fromJson(Map<String, dynamic>.from(b)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Register customer or rider account
  static Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    String? email,
    required String password,
    String role = 'customer',
    String? vehicleType,
    String? vehicleNumber,
    String? cnic,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/register.php'),
        headers: _headers(),
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'email': email,
          'password': password,
          'role': role,
          'vehicle_type': vehicleType,
          'vehicle_number': vehicleNumber,
          'cnic': cnic,
        }),
      ).timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['data'] != null) {
        if (data['data']['token'] != null) {
          _authToken = data['data']['token'];
        }
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Admin Login
  static Future<Map<String, dynamic>> adminLogin(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/admin/login.php'),
        headers: _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['data'] != null) {
        if (data['data']['token'] != null) {
          _authToken = data['data']['token'];
        }
      }
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get Admin Live Stats
  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/admin/stats.php'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get Admin Orders
  static Future<List<OrderModel>> getAdminOrders() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/admin/orders.php'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List)
            .map((o) => OrderModel.fromJson(Map<String, dynamic>.from(o)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Toggle rider online status
  static Future<bool> riderToggleOnline(bool isOnline) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/delivery/toggle_online.php'),
        headers: _headers(),
        body: jsonEncode({'is_online': isOnline ? 1 : 0}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      return data['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
