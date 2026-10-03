import 'package:flutter/foundation.dart';

enum AppRole { customer, rider, admin }

class AppRoleProvider extends ChangeNotifier {
  AppRole _role = AppRole.customer;

  AppRole get role => _role;
  bool get isCustomer => _role == AppRole.customer;
  bool get isRider => _role == AppRole.rider;
  bool get isAdmin => _role == AppRole.admin;

  void setRole(AppRole newRole) {
    if (_role != newRole) {
      _role = newRole;
      notifyListeners();
    }
  }

  void resetRole() {
    _role = AppRole.customer;
    notifyListeners();
  }
}
