import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_role_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../admin/admin_main_navigation_screen.dart';
import '../delivery/rider_main_navigation_screen.dart';
import '../home/home_screen.dart';

class UnifiedAuthScreen extends StatefulWidget {
  final AppRole initialRole;
  const UnifiedAuthScreen({super.key, this.initialRole = AppRole.customer});

  @override
  State<UnifiedAuthScreen> createState() => _UnifiedAuthScreenState();
}

class _UnifiedAuthScreenState extends State<UnifiedAuthScreen> {
  late AppRole _selectedRole;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleNumberController = TextEditingController(text: 'LEB-4921');
  final _cnicController = TextEditingController();
  final String _selectedVehicleType = 'Motorcycle';

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _prefillRoleDefaults();
  }

  void _prefillRoleDefaults() {
    if (_selectedRole == AppRole.admin) {
      _identifierController.text = 'syedfaizanrasool4@gmail.com';
      _passwordController.text = 'admin123';
    } else if (_selectedRole == AppRole.rider) {
      _identifierController.text = '03019876543';
      _passwordController.text = '123456';
    } else {
      _identifierController.text = '03001234567';
      _passwordController.text = '123456';
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _vehicleNumberController.dispose();
    _cnicController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final roleProv = context.read<AppRoleProvider>();

    try {
      if (_isSignUp) {
        // Register Flow
        final roleString = _selectedRole == AppRole.rider ? 'rider' : 'customer';
        final res = await auth.register(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
          password: _passwordController.text.trim(),
          role: roleString,
          vehicleType: _selectedRole == AppRole.rider ? _selectedVehicleType : null,
          vehicleNumber: _selectedRole == AppRole.rider ? _vehicleNumberController.text.trim() : null,
          cnic: _selectedRole == AppRole.rider ? _cnicController.text.trim() : null,
        );

        if (res['success'] == true) {
          roleProv.setRole(_selectedRole);
          _navigateToRoleScreen(_selectedRole);
        } else {
          _showError(res['message'] ?? 'Registration failed');
        }
      } else {
        // Login Flow
        final roleString = _selectedRole == AppRole.admin
            ? 'admin'
            : (_selectedRole == AppRole.rider ? 'rider' : 'customer');

        final res = await auth.login(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text.trim(),
          role: roleString,
        );

        if (res['success'] == true) {
          final detectedRole = auth.role;
          roleProv.setRole(detectedRole);
          _navigateToRoleScreen(detectedRole);
        } else {
          _showError(res['message'] ?? 'Invalid credentials');
        }
      }
    } catch (e) {
      _showError('Authentication error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToRoleScreen(AppRole role) {
    if (!mounted) return;
    Widget destination;
    switch (role) {
      case AppRole.admin:
        destination = const AdminMainNavigationScreen();
        break;
      case AppRole.rider:
        destination = const RiderMainNavigationScreen();
        break;
      case AppRole.customer:
        destination = const HomeScreen();
        break;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Brand Header
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryDark],
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Everyfy Grocery',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Unified Secure Portal · Customer, Rider & Admin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Role Selector Tabs (Pill Switcher)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _buildRoleTab(AppRole.customer, 'Customer', Icons.person_rounded),
                        _buildRoleTab(AppRole.rider, 'Rider', Icons.electric_moped_rounded),
                        _buildRoleTab(AppRole.admin, 'Admin', Icons.shield_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Auth Card Container
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isSignUp
                                  ? 'Create ${_roleName()} Account'
                                  : '${_roleName()} Sign In',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (_selectedRole != AppRole.admin)
                              TextButton(
                                onPressed: () {
                                  setState(() => _isSignUp = !_isSignUp);
                                },
                                child: Text(
                                  _isSignUp ? 'Sign In Instead' : 'Register',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Form Fields
                        if (_isSignUp) ...[
                          // Full Name
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            hint: 'e.g. Ali Khan',
                            icon: Icons.person_outline_rounded,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                          ),
                          const SizedBox(height: 14),

                          // Phone Number
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            hint: '03001234567',
                            icon: Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone,
                            validator: (v) => (v == null || v.trim().length < 10) ? 'Valid phone required' : null,
                          ),
                          const SizedBox(height: 14),

                          // Email (Optional for customer)
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email Address (Optional)',
                            hint: 'name@example.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),

                          // Rider specific fields
                          if (_selectedRole == AppRole.rider) ...[
                            _buildTextField(
                              controller: _vehicleNumberController,
                              label: 'Vehicle Plate Number',
                              hint: 'e.g. LEB-4921',
                              icon: Icons.two_wheeler_rounded,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Vehicle number required' : null,
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _cnicController,
                              label: 'CNIC Number',
                              hint: '35201-1234567-1',
                              icon: Icons.badge_outlined,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Password for SignUp
                          _buildPasswordField(_passwordController, 'Create Password'),
                        ] else ...[
                          // LOGIN FIELDS
                          _buildTextField(
                            controller: _identifierController,
                            label: _selectedRole == AppRole.admin
                                ? 'Admin Email Address'
                                : 'Phone Number or Email',
                            hint: _selectedRole == AppRole.admin
                                ? 'admin@everyfy.net'
                                : '03001234567',
                            icon: _selectedRole == AppRole.admin
                                ? Icons.admin_panel_settings_outlined
                                : Icons.account_circle_outlined,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),

                          _buildPasswordField(_passwordController, 'Password'),

                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                'Quick Demo Login:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _prefillRoleDefaults,
                                child: Text(
                                  'Pre-fill Default Credentials',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _roleColor(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _roleColor(),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(_isSignUp ? Icons.how_to_reg_rounded : Icons.login_rounded, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isSignUp ? 'Complete Registration' : 'Enter ${_roleName()} Portal',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Footer info with live config dialog
                  Center(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _showServerConfigDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Backend: ${ApiService.baseUrl}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.settings_outlined, size: 14, color: Colors.grey.shade500),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(AppRole role, String title, IconData icon) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = role;
            _isSignUp = false;
            _prefillRoleDefaults();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? _roleColor(role) : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? _roleColor(role) : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: _obscurePassword,
          validator: (v) => (v == null || v.trim().length < 4) ? 'Min 4 characters' : null,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textMuted),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: AppColors.textMuted,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  String _roleName() {
    switch (_selectedRole) {
      case AppRole.admin:
        return 'Store Admin';
      case AppRole.rider:
        return 'Delivery Partner';
      case AppRole.customer:
        return 'Customer';
    }
  }

  Color _roleColor([AppRole? role]) {
    final target = role ?? _selectedRole;
    switch (target) {
      case AppRole.admin:
        return const Color(0xFF0F172A);
      case AppRole.rider:
        return const Color(0xFFE65100);
      case AppRole.customer:
        return AppColors.primary;
    }
  }

  void _showServerConfigDialog() {
    final urlController = TextEditingController(text: ApiService.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, size: 22, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Server API Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set the backend base URL for your Hostinger server or local network testing:',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: 'API Base URL',
                hintText: 'https://everyfy.net/api',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Default: https://everyfy.net/api',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ApiService.setBaseUrl(ApiService.defaultBaseUrl);
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Reset Default'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final newUrl = urlController.text.trim();
              if (newUrl.isNotEmpty) {
                ApiService.setBaseUrl(newUrl);
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Server API URL updated: $newUrl'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save & Apply'),
          ),
        ],
      ),
    );
  }
}
