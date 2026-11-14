import 'package:flutter/material.dart';
import 'package:superthai/features/lessons/presentation/screens/lesson_editor_screen.dart';
import 'package:superthai/features/lessons/presentation/screens/manage_lessons_screen.dart';
import 'package:superthai/ui/screens/admin/add_admin_screen.dart';
import 'package:superthai/ui/screens/admin/import_online_image_screen.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';

class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ThaiAppBar(
        title: "Manage",
        showProfile: false,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ThaiSettingsGroup(
                children: [
                  ThaiSettingsTile(
                    icon: Icons.add_circle_outline_rounded,
                    title: "Create New Lesson",
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateScreen()),
                      );
                    },
                  ),
                  ThaiSettingsTile(
                    icon: Icons.reorder_rounded,
                    title: "Manage Lesson Order",
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageLessonsScreen(),
                        ),
                      );
                    },
                  ),
                  ThaiSettingsTile(
                    icon: Icons.admin_panel_settings_rounded,
                    title: "Add New Admin",
                    color: Colors.deepPurple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddAdminScreen(),
                        ),
                      );
                    },
                  ),
                  ThaiSettingsTile(
                    icon: Icons.image_search_rounded,
                    title: "Import Online Image",
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ImportOnlineImageScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
