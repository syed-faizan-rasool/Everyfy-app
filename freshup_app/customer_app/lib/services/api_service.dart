import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/address_model.dart';
import '../models/admin_model.dart';
import '../models/cart_item_model.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../models/delivery_order_model.dart';
import '../models/order_model.dart';
import '../models/notification_model.dart';
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

  /// Request Password Reset OTP
  static Future<Map<String, dynamic>> forgotPassword(String identifier) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/forgot_password.php'),
        headers: _headers(),
        body: jsonEncode({'identifier': identifier}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Reset Password with Verified OTP in real-time DB
  static Future<Map<String, dynamic>> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/reset_password.php'),
        headers: _headers(),
        body: jsonEncode({
          'identifier': identifier,
          'otp': otp,
          'new_password': newPassword,
        }),
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

      final bodyTrim = res.body.trim();
      if (bodyTrim.startsWith('<') || (!bodyTrim.startsWith('{') && !bodyTrim.startsWith('['))) {
        return {
          'success': false,
          'message': 'Server returned unexpected response (Status ${res.statusCode})',
          'is_server_error': true,
        };
      }

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

  /// Get current user profile from DB
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/auth/profile.php'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Update user profile in DB (name, email, profile_image)
  static Future<Map<String, dynamic>> updateProfile({String? name, String? email, String? avatar}) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/profile.php'),
        headers: _headers(),
        body: jsonEncode({
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (avatar != null) 'profile_image': avatar,
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
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

  /// Alias for backward compatibility
  static Future<List<OrderModel>> getOrderHistory() => getOrders();

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

      final bodyTrim = res.body.trim();
      if (bodyTrim.startsWith('<') || (!bodyTrim.startsWith('{') && !bodyTrim.startsWith('['))) {
        return {
          'success': false,
          'message': 'Registration endpoint returned status ${res.statusCode}',
          'is_server_error': true,
        };
      }

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

  /// Place custom grocery order request
  static Future<Map<String, dynamic>> placeCustomOrder({
    required String notes,
    required String addressText,
    String? customerName,
    String? customerPhone,
  }) async {
    try {
      final body = {
        'notes': notes,
        'address_text': addressText,
        if (customerName != null) 'customer_name': customerName,
        if (customerPhone != null) 'customer_phone': customerPhone,
      };

      final res = await http.post(
        Uri.parse('$_baseUrl/orders/custom.php'),
        headers: _headers(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get Admin Orders as AdminOrderModel
  static Future<List<AdminOrderModel>> getAdminOrdersList() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/admin/orders.php'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List)
            .map((o) => AdminOrderModel.fromJson(Map<String, dynamic>.from(o)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Get Admin Riders Fleet as RiderFleetMemberModel
  static Future<List<RiderFleetMemberModel>> getAdminRidersList() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/admin/riders.php'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['data'] is List) {
        return (data['data'] as List)
            .map((r) => RiderFleetMemberModel.fromJson(Map<String, dynamic>.from(r)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Update Admin Order Status or Assign Rider
  static Future<bool> updateAdminOrderStatus({
    required dynamic orderId,
    String? status,
    int? riderId,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        'order_id': orderId,
      };
      if (status != null) body['status'] = status;
      if (riderId != null) body['delivery_boy_id'] = riderId;
      if (notes != null) body['notes'] = notes;

      final res = await http.post(
        Uri.parse('$_baseUrl/admin/orders.php'),
        headers: _headers(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      return data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Add or Update Rider by Admin
  static Future<bool> adminSaveRider(Map<String, dynamic> riderData) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/admin/riders.php'),
        headers: _headers(),
        body: jsonEncode(riderData),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      return data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Delete Rider by Admin
  static Future<bool> adminDeleteRider(int riderId) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/admin/riders.php?id=$riderId'),
        headers: _headers(),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      return data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Add or Update Product by Admin (Live Database Sync)
  static Future<Map<String, dynamic>> adminSaveProduct(Map<String, dynamic> productData) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/admin/products.php'),
        headers: _headers(),
        body: jsonEncode(productData),
      ).timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body);
      return data is Map<String, dynamic> ? data : {'success': false, 'message': 'Invalid response'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Delete Product by Admin
  static Future<bool> adminDeleteProduct(int productId) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/admin/products.php?id=$productId'),
        headers: _headers(),
        body: jsonEncode({'id': productId}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      return data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Upload an image to Everyfy Backend (Hostinger)
  static Future<Map<String, dynamic>> uploadImage(File file, {String folder = 'general'}) async {
    try {
      final uri = Uri.parse('$_baseUrl/upload.php');
      final request = http.MultipartRequest('POST', uri);
      request.fields['folder'] = folder;
      if (_authToken != null && _authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      request.files.add(await http.MultipartFile.fromPath('image', file.path));

      final streamedRes = await request.send().timeout(const Duration(seconds: 25));
      final res = await http.Response.fromStream(streamedRes);
      final data = jsonDecode(res.body);
      return data is Map<String, dynamic> ? data : {'success': false, 'message': 'Upload failed'};
    } catch (e) {
      try {
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        final res = await http.post(
          Uri.parse('$_baseUrl/upload.php'),
          headers: _headers(),
          body: jsonEncode({
            'folder': folder,
            'image_base64': base64String,
          }),
        ).timeout(const Duration(seconds: 25));
        final data = jsonDecode(res.body);
        return data is Map<String, dynamic> ? data : {'success': false, 'message': 'Upload failed'};
      } catch (e2) {
        return {'success': false, 'message': e2.toString()};
      }
    }
  }

  /// -------------------------------------------------------------
  /// Notifications API (Customer, Admin, Rider)
  /// -------------------------------------------------------------

  /// Fetch notifications for a given role (customer, admin, rider)
  static Future<Map<String, dynamic>> getNotifications({
    String role = 'customer',
    int? userId,
  }) async {
    try {
      final queryParams = <String, String>{'role': role};
      if (userId != null) queryParams['user_id'] = userId.toString();

      final uri = Uri.parse('$_baseUrl/notifications/index.php').replace(queryParameters: queryParams);
      final res = await http.get(uri, headers: _headers()).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['data'] != null) {
        final rawList = data['data']['notifications'] as List? ?? [];
        final list = rawList
            .map((n) => NotificationModel.fromJson(Map<String, dynamic>.from(n)))
            .toList();
        final unreadCount = data['data']['unread_count'] as int? ?? 0;
        return {
          'success': true,
          'unread_count': unreadCount,
          'notifications': list,
        };
      }
    } catch (_) {}
    return {'success': false, 'unread_count': 0, 'notifications': <NotificationModel>[]};
  }

  /// Mark single or all notifications as read
  static Future<bool> markNotificationAsRead({
    int? notificationId,
    bool markAll = false,
    String role = 'customer',
    int? userId,
  }) async {
    try {
      final body = <String, dynamic>{
        if (notificationId != null) 'id': notificationId,
        if (markAll) 'mark_all': 1,
        'role': role,
        if (userId != null) 'user_id': userId,
      };

      final res = await http.post(
        Uri.parse('$_baseUrl/notifications/index.php'),
        headers: _headers(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      return data['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
