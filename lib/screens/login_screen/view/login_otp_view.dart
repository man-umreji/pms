// Update your FirstLoginVerification screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_model/login_screen_view_model.dart';
class FirstLoginVerification extends StatefulWidget {
  final String? userId;
  final String? username;
  final String? email;

  const FirstLoginVerification({
    super.key,
    this.userId,
    this.username,
    this.email,
  });
  @override
  State<FirstLoginVerification> createState() => _FirstLoginVerificationState();
}

class _FirstLoginVerificationState extends State<FirstLoginVerification> {
  @override
  void initState() {
    super.initState();
    // Start timer when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<LoginProvider>(context, listen: false);
      provider.startOtpTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'First Login Verification',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeaderSection(),
              const SizedBox(height: 32),

              // OTP Section
              _buildOtpSection(),
              const SizedBox(height: 24),
              _buildOldPassword(),
              const SizedBox(height: 24),
              // New Password Section
              _buildNewPasswordSection(),
              const SizedBox(height: 24),

              // Confirm Password Section
              _buildConfirmPasswordSection(),
              const SizedBox(height: 32),

              // Verify & Continue Button
              _buildVerifyButton(),
              const SizedBox(height: 24),

              // Note Section
              _buildNoteSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 60,
            color: Colors.blue.shade700,
          ),
          const SizedBox(height: 12),
          const Text(
            'OTP Verification & Password Change',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please complete the verification process to continue',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpSection() {
    final provider = Provider.of<LoginProvider>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.email_outlined, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text(
                'OTP (Sent to Registered Email)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // OTP Input
          TextFormField(
            controller: provider.otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: 'Enter 6-digit OTP',
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Resend OTP with Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Time remaining: ${provider.formattedTime}',
                style: TextStyle(
                  fontSize: 12,
                  color: provider.remainingSeconds > 0 ? Colors.orange.shade700 : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton(
                onPressed: provider.isResendEnabled && !provider.isLoading
                    ? () => _handleResendOTP(context)
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: provider.isResendEnabled && !provider.isLoading
                      ? Colors.blue.shade700
                      : Colors.grey,
                ),
                child: const Text('Resend OTP'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewPasswordSection() {
    final provider = Provider.of<LoginProvider>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text(
                'New Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // New Password Input
          TextFormField(
            controller: provider.newPasswordController,
            obscureText: provider.obscureNewPassword,
            enabled: !provider.isLoading,
            decoration: InputDecoration(
              hintText: 'Enter new password',
              prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
              suffixIcon: IconButton(
                icon: Icon(
                  provider.obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade600,
                ),
                onPressed: provider.toggleNewPasswordVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildOldPassword() {
    final provider = Provider.of<LoginProvider>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text(
                'Current Password"',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // New Password Input
          TextFormField(
            controller: provider.oldPasswordController,
            obscureText: provider.obscureNewPassword,
            enabled: !provider.isLoading,
            decoration: InputDecoration(
              hintText: 'Enter Current Password"',
              prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
              suffixIcon: IconButton(
                icon: Icon(
                  provider.obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade600,
                ),
                onPressed: provider.toggleNewPasswordVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildConfirmPasswordSection() {
    final provider = Provider.of<LoginProvider>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text(
                'Confirm Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Confirm Password Input
          TextFormField(
            controller: provider.confirmPasswordController,
            obscureText: provider.obscureConfirmPassword,
            enabled: !provider.isLoading,
            decoration: InputDecoration(
              hintText: 'Confirm new password',
              prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
              suffixIcon: IconButton(
                icon: Icon(
                  provider.obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade600,
                ),
                onPressed: provider.toggleConfirmPasswordVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton() {
    return Consumer<LoginProvider>(
      builder: (context, provider, child) {
        return SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: provider.isLoading
                ? null
                : () => _handleVerifyAndContinue(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: provider.isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text(
              'Verify & Continue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoteSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Note:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Verification session and OTP are valid for 10 minutes. Please complete the process within this time.\n'
                '• Password must be at least 8 characters and include uppercase, lowercase, number, and special character.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _handleResendOTP(BuildContext context) async {
    final provider = Provider.of<LoginProvider>(context, listen: false);
    await provider.resendOtp(context);
  }

  void _handleVerifyAndContinue(BuildContext context) async {
    final provider = Provider.of<LoginProvider>(context, listen: false);
    await provider.submitFirstLogin(context);
  }
}