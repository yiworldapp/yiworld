import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class ChangePhoneScreen extends StatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  State<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends State<ChangePhoneScreen> {
  final _supabase = Supabase.instance.client;

  // Step 1 — new number
  String _countryCode = '+91';
  final _phoneCtrl = TextEditingController();

  // Step 2 — OTP
  final _otpCtrl = TextEditingController();

  bool _loading = false;
  bool _otpSent = false;
  String? _newFullPhone; // the full E.164 phone sent to Supabase

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  String get _fullPhone => '$_countryCode${_phoneCtrl.text.trim()}';

  Future<void> _sendOtp() async {
    final number = _phoneCtrl.text.trim();
    if (number.isEmpty) {
      _snack('Please enter a phone number', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await _supabase.auth.updateUser(UserAttributes(phone: '$_countryCode$number'));
      _newFullPhone = '$_countryCode$number';
      setState(() { _otpSent = true; _loading = false; });
    } on AuthException catch (e) {
      _snack(e.message, error: true);
      setState(() => _loading = false);
    } catch (e) {
      _snack('Error: $e', error: true);
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 6) {
      _snack('Enter the 6-digit OTP', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await _supabase.auth.verifyOTP(
        phone: _newFullPhone!,
        token: otp,
        type: OtpType.phoneChange,
      );

      // Keep profiles.phone in sync
      await _supabase
          .from('profiles')
          .update({'phone': _newFullPhone})
          .eq('id', _supabase.auth.currentUser!.id);

      if (mounted) {
        _snack('Phone number updated successfully');
        context.pop(true); // return true = success
      }
    } on AuthException catch (e) {
      _snack(e.message, error: true);
      setState(() => _loading = false);
    } catch (e) {
      _snack('Error: $e', error: true);
      setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text('Change Phone Number'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _otpSent ? _buildOtpStep() : _buildNumberStep(),
      ),
    );
  }

  Widget _buildNumberStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter your new phone number',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'We\'ll send a one-time verification code to confirm.',
          style: TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 32),
        const Text('New Phone Number', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _countryCodePicker(),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                autofocus: true,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'Phone number',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.green),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black),
                  )
                : const Text('Send OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter verification code',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'A 6-digit code was sent to $_newFullPhone',
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 32),
        const Text('OTP Code', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofocus: true,
          style: const TextStyle(color: AppColors.white, fontSize: 24, letterSpacing: 8),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            counterText: '',
            hintText: '------',
            hintStyle: const TextStyle(color: AppColors.textMuted, letterSpacing: 8),
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.green),
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black),
                  )
                : const Text('Verify & Update', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _loading ? null : () => setState(() { _otpSent = false; _otpCtrl.clear(); }),
            child: const Text('Change number', style: TextStyle(color: AppColors.textMuted)),
          ),
        ),
      ],
    );
  }

  Widget _countryCodePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _countryCode,
          dropdownColor: AppColors.card,
          style: const TextStyle(color: AppColors.white, fontSize: 14),
          items: AppConstants.countryCodes.map((c) => DropdownMenuItem<String>(
            value: c['code'],
            child: Text('${c['flag']} ${c['code']}'),
          )).toList(),
          onChanged: (v) { if (v != null) setState(() => _countryCode = v); },
        ),
      ),
    );
  }
}
