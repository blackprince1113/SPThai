import 'package:flutter/material.dart';
import 'package:superthai/core/services/auth_service.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';
import 'package:superthai/core/utils/error_handler.dart';

class AddAdminScreen extends StatefulWidget {
  const AddAdminScreen({super.key});

  @override
  State<AddAdminScreen> createState() => _AddAdminScreenState();
}

class _AddAdminScreenState extends State<AddAdminScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleProceed() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a user email")),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Admin Promotion"),
        content: Text(
          "Are you sure you want to set $email as an Admin? This will give them full access to all admin features.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _promoteToAdmin(email);
    }
  }

  Future<void> _promoteToAdmin(String email) async {
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.makeAdmin(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$email is now an Admin! 🛡️"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getMessage(e)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const adminColor = Colors.deepPurple;

    return Scaffold(
      appBar: const ThaiAppBar(
        title: "Add New Admin",
        showProfile: false,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ThaiInfoBox(
              icon: Icons.shield_rounded,
              text: "Promoting a user to Admin grants them full control over lesson plans and discover items.",
              color: adminColor,
            ),
            const SizedBox(height: 32),
            ThaiSectionLabel(
              label: "USER EMAIL",
              color: theme.colorScheme.primary,
              fontSize: 12,
              padding: const EdgeInsets.only(bottom: 12),
            ),
            ThaiTextField(
              controller: _emailController,
              label: "Enter user's email address",
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 40),
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: adminColor),
                  )
                : ThaiButton(
                    text: "PROMOTE TO ADMIN",
                    color: adminColor,
                    onPressed: _handleProceed,
                  ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: theme.disabledColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
