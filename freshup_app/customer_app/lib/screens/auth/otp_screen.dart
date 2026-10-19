import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/animated_widgets.dart';
import '../home/home_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _loading = false;
  String? _error;
  int _resendTimer = 45;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendTimer = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter the verification code');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final success = await context.read<AuthProvider>().verifyOtp(code);
    setState(() => _loading = false);
    if (!mounted) return;
    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      setState(() => _error = 'Invalid verification code. Please verify and try again.');
    }
  }

  void _resendCode() {
    if (_resendTimer == 0) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('New OTP sent successfully!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = context.watch<AuthProvider>().phone;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Verify Phone Number',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
                  children: [
                    const TextSpan(text: 'We sent a 4-digit code to '),
                    TextSpan(
                      text: '+92 $phone',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // OTP Input Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _error != null ? AppColors.error : AppColors.cardBorder,
                    width: _error != null ? 1.5 : 1,
                  ),
                ),
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '••••',
                    hintStyle: TextStyle(
                      letterSpacing: 16,
                      fontSize: 28,
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],



              const SizedBox(height: 32),

              BouncingButton(
                onTap: _loading ? null : _verify,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _verify,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Verify & Proceed'),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: _resendTimer > 0
                    ? Text(
                        'Resend code in ${_resendTimer}s',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      )
                    : TextButton.icon(
                        onPressed: _resendCode,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text(
                          'Resend Code',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
