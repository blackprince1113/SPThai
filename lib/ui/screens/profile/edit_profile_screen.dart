import 'package:flutter/material.dart';
import 'package:superthai/core/services/auth_service.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';
import 'package:superthai/core/utils/error_handler.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser;
    _nameController = TextEditingController(
      text: user?.displayName ?? user?.email ?? "",
    );
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showError("Name cannot be empty");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.instance.updateProfileName(_nameController.text.trim());

      if (_oldPasswordController.text.isNotEmpty ||
          _newPasswordController.text.isNotEmpty ||
          _confirmPasswordController.text.isNotEmpty) {
        if (_oldPasswordController.text.isEmpty) {
          throw "Please enter your old password to change password";
        }
        if (_newPasswordController.text.length < 6) {
          throw "New password must be at least 6 characters";
        }
        if (_newPasswordController.text != _confirmPasswordController.text) {
          throw "New passwords do not match";
        }

        await AuthService.instance.changePassword(
          _oldPasswordController.text,
          _newPasswordController.text,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully! ✨")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError(ErrorHandler.getMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ThaiAppBar(
        title: "Edit Profile",
        showProfile: false,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                "Save",
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ThaiSectionLabel(
              label: "PERSONAL INFO",
              color: AppTheme.primaryColor,
              fontSize: 12,
              padding: const EdgeInsets.only(bottom: 12),
            ),
            ThaiTextField(
              controller: _nameController,
              label: "Display Name",
              icon: Icons.person_outline_rounded,
            ),

            const SizedBox(height: 32),

            ThaiSectionLabel(
              label: "CHANGE PASSWORD",
              color: AppTheme.primaryColor,
              fontSize: 12,
              padding: const EdgeInsets.only(bottom: 8),
            ),
            Text(
              "Leave blank if you don't want to change password",
              style: TextStyle(fontSize: 12, color: theme.disabledColor),
            ),
            const SizedBox(height: 16),
            ThaiTextField(
              controller: _oldPasswordController,
              label: "Old Password",
              icon: Icons.lock_open_rounded,
              isPassword: true,
            ),
            ThaiTextField(
              controller: _newPasswordController,
              label: "New Password",
              icon: Icons.lock_outline_rounded,
              isPassword: true,
            ),
            ThaiTextField(
              controller: _confirmPasswordController,
              label: "Confirm New Password",
              icon: Icons.lock_reset_rounded,
              isPassword: true,
            ),
          ],
        ),
      ),
    );
  }
}
