import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    setState(() { _loading = true; _error = ''; });

    // ── TEST ACCOUNT BYPASS ──────────────────────────────────────────────────
    // Hardcoded reviewer account for Google Play Store review process.
    // Entering this email skips sending a real OTP — the actual Supabase
    // sign-in happens in otp_verify_screen via signInWithPassword when the
    // hardcoded OTP "123456" is entered. Do not remove without updating
    // Play Store test credentials in the developer console.
    if (email == 'yiworldapp@gmail.com') {
      if (mounted) {
        setState(() => _loading = false);
        context.pushNamed('otp', extra: {'email': email});
      }
      return;
    }
    // ────────────────────────────────────────────────────────────────────────

    // ── ORGANISATION WHITELIST CHECK ─────────────────────────────────────────
    // Only emails listed in the organisation_emails table are permitted.
    // This check runs after the test account bypass above.
    try {
      final allowed = await Supabase.instance.client
          .from('organisation_emails')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      if (allowed == null) {
        setState(() {
          _error = 'This app is only for Young Indians organisation members. Please contact your chapter coordinator.';
          _loading = false;
        });
        return;
      }
    } catch (e) {
      setState(() { _error = 'Unable to verify membership. Please try again.'; _loading = false; });
      return;
    }
    // ────────────────────────────────────────────────────────────────────────

    try {
      await Supabase.instance.client.auth.signInWithOtp(email: email);
      if (mounted) {
        context.pushNamed('otp', extra: {'email': email});
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Logo / Brand
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/images/yi_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.bolt_rounded, color: AppColors.green, size: 32),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Young Indians',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your email address to continue',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 48),

              // Email input
              Text('Email Address', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              ListenableBuilder(
                listenable: _emailFocus,
                builder: (context, _) => Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _emailFocus.hasFocus ? AppColors.green : AppColors.border,
                      width: _emailFocus.hasFocus ? 1.5 : 1,
                    ),
                  ),
                  child: TextField(
                    focusNode: _emailFocus,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'you@example.com',
                      hintStyle: TextStyle(color: AppColors.textHint),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                  ),
                ),
              ),

              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    _error,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    disabledBackgroundColor: AppColors.green.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      )
                    : const Text(
                        'Send OTP',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
