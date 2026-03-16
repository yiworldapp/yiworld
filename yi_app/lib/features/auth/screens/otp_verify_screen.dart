import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String email;
  final bool isSignUp;

  const OtpVerifyScreen({super.key, required this.email, this.isSignUp = false});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  bool _loading = false;
  String _error = '';

  Future<void> _verifyOtp(String otp) async {
    if (otp.length != 6) return;
    setState(() { _loading = true; _error = ''; });

    // ── TEST ACCOUNT BYPASS ──────────────────────────────────────────────────
    // If this is the hardcoded reviewer account (for Google Play Store review),
    // sign in using password auth instead of OTP. The hardcoded OTP "123456"
    // acts as the trigger — real auth still happens via Supabase session so
    // all route guards pass normally. We skip the profile/onboarding check
    // and go straight to events since this is a pre-seeded test account.
    if (widget.email == 'yiworldapp@gmail.com' && otp == '123456') {
      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: 'yiworldapp@gmail.com',
          password: '1234567890',
        );
        if (mounted) context.go('/events');
      } catch (e) {
        setState(() => _error = 'Test account sign-in failed. Please contact the developer.');
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }
    // ────────────────────────────────────────────────────────────────────────

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: otp,
        type: OtpType.email,
      );

      if (response.session != null && mounted) {
        final userId = response.session!.user.id;
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('onboarding_done')
            .eq('id', userId)
            .maybeSingle();

        if (profile == null || profile['onboarding_done'] != true) {
          context.go('/onboarding');
        } else {
          context.go('/events');
        }
      }
    } catch (e) {
      setState(() => _error = 'Invalid OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  final defaultPinTheme = PinTheme(
    width: 52,
    height: 58,
    textStyle: const TextStyle(
      fontSize: 22,
      color: AppColors.white,
      fontWeight: FontWeight.w600,
    ),
    decoration: BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('Verify OTP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                'Enter the code',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit OTP to ${widget.email}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 48),

              Pinput(
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration?.copyWith(
                    border: Border.all(color: AppColors.green, width: 1.5),
                  ),
                ),
                errorPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration?.copyWith(
                    border: Border.all(color: AppColors.error),
                  ),
                ),
                onCompleted: _verifyOtp,
                autofocus: true,
                cursor: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 9),
                      width: 22, height: 1.5,
                      color: AppColors.green,
                    ),
                  ],
                ),
              ),

              if (_error.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text(_error, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
              ],

              const SizedBox(height: 28),

              if (_loading)
                const Center(child: CircularProgressIndicator(color: AppColors.green)),

              const SizedBox(height: 32),
              Center(
                child: TextButton(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signInWithOtp(email: widget.email);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('OTP resent')),
                      );
                    }
                  },
                  child: const Text("Didn't receive? Resend OTP"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
