import 'package:flutter/material.dart';
import 'unified_auth_screen.dart';

/// Unified single login screen wrapper for Everyfy
/// Provides the single universal login where credentials determine role (Customer, Rider, Admin)
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UnifiedAuthScreen();
  }
}
