// lib/screens/profile/view_model/change_password_view_model.dart
import 'package:flutter/material.dart';
import '../../../service/auth_service.dart';
import '../../../widget/global_widgets/global_loding_overlay.dart';
import '../../../widget/global_widgets/global_utils_snack_bar.dart';
import '../../login_screen/repository/submit_first_login_repo.dart';

import '../../login_screen/model/submit_first_login_model.dart';
import '../model/change_password_model.dart';
import '../repository/change_password_repository.dart';

class ChangePasswordViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SubmitFirstLoginRepository _repository = SubmitFirstLoginRepository();

  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Password visibility
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  bool get showCurrentPassword => _showCurrentPassword;
  bool get showNewPassword => _showNewPassword;
  bool get showConfirmPassword => _showConfirmPassword;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Success message
  String? _successMessage;
  String? get successMessage => _successMessage;

  // Form key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Toggle password visibility
  void toggleCurrentPasswordVisibility() {
    _showCurrentPassword = !_showCurrentPassword;
    notifyListeners();
  }

  void toggleNewPasswordVisibility() {
    _showNewPassword = !_showNewPassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _showConfirmPassword = !_showConfirmPassword;
    notifyListeners();
  }

  // Clear messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // Clear all fields
  void clearFields() {
    oldPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    clearMessages();
  }

  // Validate current password (optional - can be done in form)
  String? validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter current password';
    }
    return null;
  }

  // Validate new password
  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter new password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (oldPasswordController.text == value) {
      return 'New password must be different from current password';
    }
    return null;
  }

  // Validate confirm password
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }
  Future<void> changePassword(BuildContext context) async {
    final String oldPassword = oldPasswordController.text.trim();
    final String newPassword = newPasswordController.text.trim();
    final String confirmPassword = confirmPasswordController.text.trim();

    // ✅ VALIDATION
    if (oldPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter current password'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter new password'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password must be at least 6 characters'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (confirmPassword != newPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final repo = ChangePasswordRepository();

      final response = await repo.changePasswordParsed(
        ChangePasswordReqModel(
          oldPassword: oldPassword,
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        ),
      );

      // Hide loading indicator
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (response.success == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? "Password changed successfully"),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Clear fields
          oldPasswordController.clear();
          newPasswordController.clear();
          confirmPasswordController.clear();

          // Navigate back after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              Navigator.pop(context);
            }
          });
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? "Failed to change password"),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator
      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Network error. Please try again"),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
  // Change password
  // Future<bool> changePassword() async {
  //   // Validate form
  //   if (!formKey.currentState!.validate()) {
  //     return false;
  //   }
  //
  //   _isLoading = true;
  //   _errorMessage = null;
  //   _successMessage = null;
  //   notifyListeners();
  //
  //   try {
  //     final reqModel = SubmitFirstLoginReqModel(
  //       oldPassword: currentPasswordController.text,
  //       newPassword: newPasswordController.text,
  //       confirmPassword: confirmPasswordController.text,
  //     );
  //
  //     // final response = await _repository.submitFirstLoginWithHelper(reqModel);
  //
  //     // if (response.success == true) {
  //     //   _successMessage = response.message ?? 'Password changed successfully!';
  //     //   _isLoading = false;
  //     //   notifyListeners();
  //     //
  //     //   // Clear fields after successful change
  //     //   clearFields();
  //     //
  //     //   return true;
  //     // } else {
  //     //   _errorMessage = response.message ?? 'Failed to change password';
  //     //   _isLoading = false;
  //     //   notifyListeners();
  //     //   return false;
  //     // }
  //   } catch (e) {
  //     _errorMessage = 'Error: $e';
  //     _isLoading = false;
  //     notifyListeners();
  //     return false;
  //   }
  // }

  // Change password with custom API (if different endpoint)
  Future<bool> changePasswordWithApi({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      _errorMessage = 'Passwords do not match';
      notifyListeners();
      return false;
    }

    if (newPassword.length < 6) {
      _errorMessage = 'Password must be at least 6 characters';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Simulate API call - Replace with actual API
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Implement actual API call
      // final response = await _apiClient.post('/change-password', body: {
      //   'current_password': currentPassword,
      //   'new_password': newPassword,
      //   'confirm_password': confirmPassword,
      // });

      _successMessage = 'Password changed successfully!';
      _isLoading = false;
      notifyListeners();

      clearFields();
      return true;

    } catch (e) {
      _errorMessage = 'Failed to change password: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get password strength
  int getPasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    return strength;
  }

  // Get password strength text
  String getPasswordStrengthText(String password) {
    int strength = getPasswordStrength(password);
    if (strength <= 2) return 'Weak';
    if (strength <= 4) return 'Medium';
    return 'Strong';
  }

  // Get password strength color
  Color getPasswordStrengthColor(String password) {
    int strength = getPasswordStrength(password);
    if (strength <= 2) return Colors.red;
    if (strength <= 4) return Colors.orange;
    return Colors.green;
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}