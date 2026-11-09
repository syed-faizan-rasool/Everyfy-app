import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/app_role_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_order_provider.dart';
import '../../services/meta_analytics_service.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../admin/admin_main_navigation_screen.dart';
import '../delivery/rider_main_navigation_screen.dart';
import '../home/home_screen.dart';

class UnifiedAuthScreen extends StatefulWidget {
  final AppRole? initialRole;
  const UnifiedAuthScreen({super.key, this.initialRole});

  @override
  State<UnifiedAuthScreen> createState() => _UnifiedAuthScreenState();
}

class _UnifiedAuthScreenState extends State<UnifiedAuthScreen> {
  bool _isSignUp = false;
  String _signUpRole = 'customer'; // 'customer' or 'rider'
  String _selectedVehicleType = 'Motorcycle';
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _selectedAvatarUrl;

  final List<String> _avatarPresets = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
    'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
    'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200',
  ];

  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleNumberController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final roleProv = context.read<AppRoleProvider>();

    try {
      if (_isSignUp) {
        // Customer or Delivery Rider Registration
        final res = await auth.register(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: _signUpRole,
          vehicleType: _signUpRole == 'rider' ? _selectedVehicleType : null,
          vehicleNumber: _signUpRole == 'rider' ? _vehicleNumberController.text.trim() : null,
        );

        if (!mounted) return;
        if (res['success'] == true) {
          // Meta Tracking Event: CompleteRegistration
          MetaAnalyticsService.logCompleteRegistration(
            registrationMethod: _signUpRole,
            userId: _phoneController.text.trim(),
          );
          final targetRole = _signUpRole == 'rider' ? AppRole.rider : AppRole.customer;
          roleProv.setRole(targetRole);
          if (targetRole == AppRole.rider) {
            context.read<DeliveryOrderProvider>().setRiderSession(
              name: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
              vehicle: _vehicleNumberController.text.trim(),
            );
          }
          _navigateToRoleScreen(targetRole);
        } else {
          _showError(res['message'] ?? 'Registration failed. Please try again.');
        }
      } else {
        // Universal Single Login (Credentials decide the role: Admin, Rider, or Customer)
        final identifier = _identifierController.text.trim();
        final password = _passwordController.text.trim();

        final res = await auth.login(
          identifier: identifier,
          password: password,
          role: 'auto',
        );

        if (!mounted) return;
        if (res['success'] == true) {
          final detectedRole = auth.role;
          roleProv.setRole(detectedRole);

          // Synchronize role-specific providers with live credentials
          if (detectedRole == AppRole.admin) {
            await context.read<AdminProvider>().login(identifier, password);
          } else if (detectedRole == AppRole.rider) {
            await context.read<DeliveryOrderProvider>().login(identifier, password);
          }

          _navigateToRoleScreen(detectedRole);
        } else {
          _showError(res['message'] ?? 'Invalid phone/email or password');
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

  void _showError(String rawMessage) {
    if (!mounted) return;

    // Sanitize any raw backend default password or developer strings
    String cleanTitle = 'Authentication Notice';
    String cleanMessage = rawMessage;

    final lower = rawMessage.toLowerCase();
    if (lower.contains('default pass') ||
        lower.contains('1234') ||
        lower.contains('admin123') ||
        lower.contains('invalid phone') ||
        lower.contains('invalid password') ||
        lower.contains('please provide both')) {
      cleanTitle = 'Invalid Credentials';
      cleanMessage = 'Invalid email/phone or password. Please verify your credentials and try again.';
    } else if (rawMessage.contains('404') ||
        lower.contains('server returned unexpected') ||
        lower.contains('connection error') ||
        lower.contains('registration endpoint')) {
      cleanTitle = 'Backend Sync Required';
      cleanMessage = 'Please ensure the latest backend files are uploaded to Hostinger.';
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cleanTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cleanMessage,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.95),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        int step = 1; // 1: Enter Email/Phone, 2: Enter OTP, 3: Set New Password
        final identifierCtrl = TextEditingController(text: _identifierController.text.trim());
        final otpCtrl = TextEditingController();
        final newPassCtrl = TextEditingController();
        final confirmPassCtrl = TextEditingController();
        bool isSubmitting = false;
        String? errorMessage;
        String? serverOtpNotice;
        bool obscureNewPass = true;
        bool obscureConfirmPass = true;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 18,
                bottom: bottomInset + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              step == 1
                                  ? 'Reset Password'
                                  : (step == 2 ? 'Verify OTP Code' : 'New Password'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (step == 1) ...[
                      const Text(
                        'Enter your registered email address or phone number. We will verify your account in real-time and generate your OTP code.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: identifierCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Registered Email or Phone',
                          hintText: 'e.g. name@example.com or 03001234567',
                          prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.primary, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final id = identifierCtrl.text.trim();
                                  if (id.isEmpty) {
                                    setModalState(() => errorMessage = 'Please enter your email or phone number');
                                    return;
                                  }
                                  setModalState(() {
                                    isSubmitting = true;
                                    errorMessage = null;
                                  });
                                  final res = await ApiService.forgotPassword(id);
                                  setModalState(() => isSubmitting = false);

                                  if (res['success'] == true) {
                                    final otpCode = res['data']?['otp']?.toString() ?? '1234';
                                    setModalState(() {
                                      serverOtpNotice = 'OTP generated: $otpCode (Demo code 1234 is also accepted)';
                                      otpCtrl.text = otpCode; // Auto-prefill for effortless testing
                                      step = 2;
                                    });
                                  } else {
                                    setModalState(() => errorMessage = res['message'] ?? 'Failed to send OTP. Please check credentials.');
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                              : const Text('Send Verification Code', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                      ),
                    ] else if (step == 2) ...[
                      Text(
                        'A 4-digit code was generated for ${identifierCtrl.text.trim()}. Please enter it below:',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      ),
                      if (serverOtpNotice != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.key_rounded, color: Color(0xFF059669), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  serverOtpNotice!,
                                  style: const TextStyle(color: Color(0xFF065F46), fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: otpCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 14),
                        decoration: InputDecoration(
                          hintText: '••••',
                          hintStyle: const TextStyle(letterSpacing: 14),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final code = otpCtrl.text.trim();
                                  if (code.isEmpty) {
                                    setModalState(() => errorMessage = 'Please enter the 4-digit OTP code');
                                    return;
                                  }
                                  setModalState(() {
                                    isSubmitting = true;
                                    errorMessage = null;
                                  });
                                  final res = await ApiService.verifyOtp(identifierCtrl.text.trim(), code);
                                  setModalState(() => isSubmitting = false);

                                  if (res['success'] == true) {
                                    setModalState(() => step = 3);
                                  } else {
                                    setModalState(() => errorMessage = res['message'] ?? 'Invalid OTP code. Please try 1234.');
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                              : const Text('Verify Code & Continue', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Create your new password. Once submitted, it will be securely encrypted in the live database.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: newPassCtrl,
                        obscureText: obscureNewPass,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                            onPressed: () => setModalState(() => obscureNewPass = !obscureNewPass),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPassCtrl,
                        obscureText: obscureConfirmPass,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          prefixIcon: const Icon(Icons.lock_clock_outlined, color: AppColors.primary, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                            onPressed: () => setModalState(() => obscureConfirmPass = !obscureConfirmPass),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final newPass = newPassCtrl.text.trim();
                                  final confPass = confirmPassCtrl.text.trim();

                                  if (newPass.length < 4) {
                                    setModalState(() => errorMessage = 'Password must be at least 4 characters');
                                    return;
                                  }
                                  if (newPass != confPass) {
                                    setModalState(() => errorMessage = 'Passwords do not match');
                                    return;
                                  }

                                  setModalState(() {
                                    isSubmitting = true;
                                    errorMessage = null;
                                  });

                                  final res = await ApiService.resetPassword(
                                    identifier: identifierCtrl.text.trim(),
                                    otp: otpCtrl.text.trim(),
                                    newPassword: newPass,
                                  );

                                  setModalState(() => isSubmitting = false);

                                  if (res['success'] == true) {
                                    if (sheetContext.mounted) {
                                      Navigator.pop(sheetContext);
                                    }
                                    _identifierController.text = identifierCtrl.text.trim();
                                    _passwordController.text = newPass;

                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Password reset successfully! Tap Sign In to enter.',
                                                  style: TextStyle(fontWeight: FontWeight.w700),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: const Color(0xFF0D5C3A),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      );
                                    }
                                  } else {
                                    setModalState(() => errorMessage = res['message'] ?? 'Failed to reset password. Please try again.');
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                              : const Text('Save New Password & Sign In', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAvatarPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Profile Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose a profile avatar for your Everyfy account:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _avatarPresets.map((url) {
                final isSel = _selectedAvatarUrl == url;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedAvatarUrl = url);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSel ? AppColors.primary : Colors.grey.shade300,
                        width: isSel ? 3 : 1,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() => _selectedAvatarUrl = null);
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Use Default Logo', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Brand Header
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF136E44), AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: const Icon(Icons.shopping_basket_rounded,
                                color: Colors.white, size: 44),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Brand Name
                  const Text(
                    'Everyfy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Express Delivery Pill Tag
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded,
                              size: 16, color: AppColors.primaryDark),
                          SizedBox(width: 4),
                          Text(
                            'Fresh Groceries Delivered in 15 Mins',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Universal Auth Card Container
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
                      border: Border.all(color: Colors.grey.shade100, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Text(
                          _isSignUp ? 'Create Account' : 'Welcome Back',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isSignUp
                              ? 'Enter your details to create an Everyfy account'
                              : 'Sign in with your phone or email to continue',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Form Inputs
                        if (_isSignUp) ...[
                          // Profile Image / Avatar Picker
                          Center(
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: _showAvatarPickerSheet,
                                  child: Container(
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFF1F5F1),
                                      border: Border.all(
                                        color: AppColors.primary,
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.15),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: _selectedAvatarUrl != null
                                          ? Image.network(
                                              _selectedAvatarUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(
                                                Icons.person_rounded,
                                                size: 46,
                                                color: AppColors.primary,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.person_rounded,
                                              size: 46,
                                              color: AppColors.primary,
                                            ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _showAvatarPickerSheet,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: GestureDetector(
                              onTap: _showAvatarPickerSheet,
                              child: const Text(
                                'Add Profile Photo',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Account Type Selector
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _signUpRole = 'customer'),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _signUpRole == 'customer' ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: _signUpRole == 'customer'
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.05),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.person_rounded,
                                            size: 16,
                                            color: _signUpRole == 'customer' ? AppColors.primary : AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Customer',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: _signUpRole == 'customer' ? AppColors.primaryDark : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _signUpRole = 'rider'),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _signUpRole == 'rider' ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: _signUpRole == 'rider'
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.05),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.two_wheeler_rounded,
                                            size: 16,
                                            color: _signUpRole == 'rider' ? AppColors.primary : AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Delivery Rider',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: _signUpRole == 'rider' ? AppColors.primaryDark : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Full Name
                          _buildTextField(
                            controller: _nameController,
                            label: _signUpRole == 'rider' ? 'Rider Full Name' : 'Full Name',
                            hint: 'e.g. Ali Khan',
                            icon: Icons.person_outline_rounded,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Name is required'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // Phone Number
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Mobile Number',
                            hint: '03XXXXXXXXX',
                            icon: Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                                (v == null || v.trim().length < 10)
                                    ? 'Valid mobile number required'
                                    : null,
                          ),
                          const SizedBox(height: 14),

                          // Email Address (Required)
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            hint: 'name@example.com',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email address is required';
                              }
                              final emailRegex =
                                  RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(v.trim())) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password for SignUp
                          _buildPasswordField(
                            controller: _passwordController,
                            label: 'Create Password',
                            hint: 'At least 6 characters',
                          ),

                          if (_signUpRole == 'rider') ...[
                            const SizedBox(height: 14),
                            // Vehicle Type Selector
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vehicle Type',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FBF9),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedVehicleType,
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                                      items: const [
                                        DropdownMenuItem(value: 'Motorcycle', child: Text('Motorcycle / Bike')),
                                        DropdownMenuItem(value: 'Scooter', child: Text('Scooter')),
                                        DropdownMenuItem(value: 'Car', child: Text('Car / Auto')),
                                        DropdownMenuItem(value: 'Bicycle', child: Text('Bicycle')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedVehicleType = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Vehicle Number
                            _buildTextField(
                              controller: _vehicleNumberController,
                              label: 'Vehicle Plate Number',
                              hint: 'e.g. KHI-1234',
                              icon: Icons.numbers_rounded,
                              validator: (v) {
                                if (_signUpRole == 'rider' && (v == null || v.trim().isEmpty)) {
                                  return 'Vehicle number is required for riders';
                                }
                                return null;
                              },
                            ),
                          ],
                        ] else ...[
                          // SINGLE UNIFIED LOGIN FIELDS
                          _buildTextField(
                            controller: _identifierController,
                            label: 'Phone Number or Email',
                            hint: 'Phone number or email address',
                            icon: Icons.account_circle_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Please enter your phone or email'
                                    : null,
                          ),
                          const SizedBox(height: 16),

                          _buildPasswordField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Enter your password',
                          ),

                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: _showForgotPasswordDialog,
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 22),

                        // Submit Button
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryDark],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _isSignUp ? 'Create Account' : 'Sign In',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Switch between Login and Registration
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                _formKey.currentState?.reset();
                              });
                            },
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                                children: [
                                  TextSpan(
                                    text: _isSignUp
                                        ? 'Already have an account? '
                                        : 'Don\'t have an account? ',
                                  ),
                                  TextSpan(
                                    text: _isSignUp ? 'Sign In' : 'Sign Up',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Professional Grocery App Value Props
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _TrustFeature(
                          icon: Icons.flash_on_rounded,
                          label: '15-Min Delivery',
                        ),
                        _TrustDivider(),
                        _TrustFeature(
                          icon: Icons.eco_rounded,
                          label: '100% Fresh',
                        ),
                        _TrustDivider(),
                        _TrustFeature(
                          icon: Icons.verified_user_rounded,
                          label: 'Secure Orders',
                        ),
                      ],
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
            filled: true,
            fillColor: const Color(0xFFF9FBF9),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
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
          obscureText: _obscurePassword,
          validator: (v) => (v == null || v.trim().length < 4)
              ? 'Password must be at least 4 characters'
              : null,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                size: 20, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: Colors.grey.shade600,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FBF9),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrustFeature extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustFeature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primaryDark),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TrustDivider extends StatelessWidget {
  const _TrustDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      color: Colors.grey.shade300,
    );
  }
}
