import 'package:flutter/foundation.dart';
import '../models/address_model.dart';
import '../data/dummy_data.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _name = '';
  String _phone = '';
  AddressModel? _selectedAddress;

  bool get isLoggedIn => _isLoggedIn;
  String get name => _name;
  String get phone => _phone;
  AddressModel? get selectedAddress => _selectedAddress ?? (DummyData.addresses.isNotEmpty ? DummyData.addresses.first : null);

  // TODO: Replace with real API call to /auth/send-otp
  Future<void> sendOtp(String phone) async {
    _phone = phone;
    await Future.delayed(const Duration(seconds: 1));
  }

  // TODO: Replace with real API call to /auth/verify-otp
  Future<bool> verifyOtp(String otp) async {
    await Future.delayed(const Duration(seconds: 1));
    if (otp.length == 4 || otp.length == 6) {
      _isLoggedIn = true;
      _name = 'Guest User';
      notifyListeners();
      return true;
    }
    return false;
  }

  void setAddress(AddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}
