import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/address_model.dart';
import '../services/api_service.dart';
import 'app_role_provider.dart';

class AuthProvider extends ChangeNotifier {
  static const String _kIsLoggedIn = 'auth_is_logged_in';
  static const String _kUserId = 'auth_user_id';
  static const String _kName = 'auth_name';
  static const String _kPhone = 'auth_phone';
  static const String _kEmail = 'auth_email';
  static const String _kRole = 'auth_role';
  static const String _kToken = 'auth_token';
  static const String _kLoginTimestamp = 'auth_login_timestamp';
  static const String _kAvatar = 'auth_avatar';
  static const int _sessionValidityDays = 7; // Auto-login valid for 7 days

  bool _isLoggedIn = false;
  int _userId = 0;
  String _name = '';
  String _phone = '';
  String _email = '';
  String _avatar = '';
  AppRole _role = AppRole.customer;
  AddressModel? _selectedAddress;
  String? _errorMessage;

  bool get isLoggedIn => _isLoggedIn;
  int get userId => _userId;
  String get name => _name.isNotEmpty ? _name : (_role == AppRole.admin ? 'Store Admin' : (_role == AppRole.rider ? 'Delivery Rider' : 'Customer'));
  String get phone => _phone;
  String get email => _email;
  String get avatar => _avatar;
  AppRole get role => _role;
  String? get errorMessage => _errorMessage;
  AddressModel? get selectedAddress => _selectedAddress;

  /// Restore existing session from local storage if within 7 days
  Future<bool> checkSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_kIsLoggedIn) ?? false;
      if (!isLoggedIn) {
        _isLoggedIn = false;
        return false;
      }

      final timestamp = prefs.getInt(_kLoginTimestamp) ?? 0;
      if (timestamp == 0) {
        await logout();
        return false;
      }

      final loginDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final daysDiff = DateTime.now().difference(loginDate).inDays;

      // Check if session has exceeded 7 days (1 week)
      if (daysDiff >= _sessionValidityDays) {
        // Expired after 1 week! Require user to log in again.
        await logout();
        return false;
      }

      // Valid session! Restore user state
      _isLoggedIn = true;
      _userId = prefs.getInt(_kUserId) ?? 1;
      _name = prefs.getString(_kName) ?? '';
      _phone = prefs.getString(_kPhone) ?? '';
      _email = prefs.getString(_kEmail) ?? '';
      _avatar = prefs.getString(_kAvatar) ?? '';

      final roleStr = prefs.getString(_kRole) ?? 'customer';
      if (roleStr == 'admin') {
        _role = AppRole.admin;
      } else if (roleStr == 'rider') {
        _role = AppRole.rider;
      } else {
        _role = AppRole.customer;
      }

      final token = prefs.getString(_kToken);
      if (token != null && token.isNotEmpty) {
        ApiService.setAuthToken(token);
      }

      // Restore user's saved address from backend
      try {
        final addrs = await ApiService.getAddresses();
        if (addrs.isNotEmpty) {
          _selectedAddress = addrs.firstWhere((a) => a.isDefault, orElse: () => addrs.first);
        }
      } catch (_) {}

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Save active user session locally
  Future<void> _saveSessionToPrefs([String? token]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsLoggedIn, true);
      await prefs.setInt(_kUserId, _userId);
      await prefs.setString(_kName, _name);
      await prefs.setString(_kPhone, _phone);
      await prefs.setString(_kEmail, _email);
      await prefs.setString(_kAvatar, _avatar);
      await prefs.setString(_kRole, _role.name);
      if (token != null && token.isNotEmpty) {
        await prefs.setString(_kToken, token);
      }
      await prefs.setInt(_kLoginTimestamp, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// Strict Live Multi-Role Login against Everyfy Backend (Customer, Rider or Admin)
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    String role = 'auto',
  }) async {
    _errorMessage = null;
    try {
      final res = await ApiService.login(
        identifier: identifier,
        password: password,
        role: role,
      );

      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final user = data['user'] ?? {};
        final serverRole = data['role'] ?? user['role'] ?? role;

        _isLoggedIn = true;
        _userId = user['id'] ?? 0;
        _name = user['name'] ?? '';
        _phone = user['phone'] ?? identifier;
        _email = user['email'] ?? '';

        if (serverRole == 'admin') {
          _role = AppRole.admin;
        } else if (serverRole == 'rider') {
          _role = AppRole.rider;
        } else {
          _role = AppRole.customer;
        }

        final token = data['token'] ?? ApiService.authToken;
        await _saveSessionToPrefs(token);

        // Fetch user's saved addresses live from server
        try {
          final addrs = await ApiService.getAddresses();
          if (addrs.isNotEmpty) {
            _selectedAddress = addrs.firstWhere((a) => a.isDefault, orElse: () => addrs.first);
          }
        } catch (_) {}

        notifyListeners();
        return {'success': true, 'role': _role, 'message': res['message']};
      } else {
        _errorMessage = res['message'] ?? 'Login failed. Please check your credentials.';
        notifyListeners();
        return {'success': false, 'message': _errorMessage};
      }
    } catch (e) {
      _errorMessage = 'Could not connect to server: ${e.toString()}';
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }

  /// Strict Live Registration for Customer or Rider
  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    String? email,
    required String password,
    String role = 'customer',
    String? vehicleType,
    String? vehicleNumber,
    String? cnic,
  }) async {
    _errorMessage = null;
    try {
      final res = await ApiService.register(
        name: name,
        phone: phone,
        email: email,
        password: password,
        role: role,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        cnic: cnic,
      );

      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final user = data['user'] ?? {};

        _isLoggedIn = true;
        _userId = user['id'] ?? 0;
        _name = user['name'] ?? name;
        _phone = user['phone'] ?? phone;
        _email = user['email'] ?? (email ?? '');

        _role = role == 'rider' ? AppRole.rider : AppRole.customer;
        final token = data['token'] ?? ApiService.authToken;
        await _saveSessionToPrefs(token);

        notifyListeners();
        return {'success': true, 'role': _role, 'message': res['message']};
      } else {
        _errorMessage = res['message'] ?? 'Registration failed. Please verify your details.';
        notifyListeners();
        return {'success': false, 'message': _errorMessage};
      }
    } catch (e) {
      _errorMessage = 'Connection error: ${e.toString()}';
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }

  /// Send OTP code via backend API
  Future<void> sendOtp(String phone) async {
    _phone = phone;
    try {
      await ApiService.sendOtp(phone);
    } catch (_) {}
  }

  /// Verify OTP code strictly via live backend API
  Future<bool> verifyOtp(String otp) async {
    try {
      final res = await ApiService.verifyOtp(_phone, otp);
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final user = data['user'] ?? {};
        _isLoggedIn = true;
        _userId = user['id'] ?? 0;
        _name = user['name'] ?? 'Customer';
        _phone = user['phone'] ?? _phone;
        _email = user['email'] ?? '';
        _role = AppRole.customer;

        final token = data['token'] ?? ApiService.authToken;
        await _saveSessionToPrefs(token);

        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  void setAddress(AddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userId = 0;
    _name = '';
    _phone = '';
    _email = '';
    _role = AppRole.customer;
    _selectedAddress = null;
    ApiService.setAuthToken(null);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kIsLoggedIn);
      await prefs.remove(_kUserId);
      await prefs.remove(_kName);
      await prefs.remove(_kPhone);
      await prefs.remove(_kEmail);
      await prefs.remove(_kRole);
      await prefs.remove(_kToken);
      await prefs.remove(_kLoginTimestamp);
    } catch (_) {}

    notifyListeners();
  }

  Future<void> updateAvatar(String pathOrUrl) async {
    _avatar = pathOrUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAvatar, pathOrUrl);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? phone, String? email, String? avatar}) async {
    if (name != null && name.isNotEmpty) _name = name;
    if (phone != null && phone.isNotEmpty) _phone = phone;
    if (email != null && email.isNotEmpty) _email = email;
    if (avatar != null && avatar.isNotEmpty) _avatar = avatar;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (name != null && name.isNotEmpty) await prefs.setString(_kName, name);
      if (phone != null && phone.isNotEmpty) await prefs.setString(_kPhone, phone);
      if (email != null && email.isNotEmpty) await prefs.setString(_kEmail, email);
      if (avatar != null && avatar.isNotEmpty) await prefs.setString(_kAvatar, avatar);
    } catch (_) {}
    notifyListeners();
  }
}
