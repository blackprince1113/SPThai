import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/features/lessons/presentation/screens/lesson_selection_screen.dart';
import 'package:superthai/features/lessons/presentation/screens/lesson_editor_screen.dart';
import 'package:superthai/ui/screens/favorites_screen.dart';
import 'package:superthai/ui/screens/discover_screen.dart';
import 'package:superthai/ui/widgets/app_drawer.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/core/services/auth_service.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  static MainContainerState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainContainerState>();

  @override
  State<MainContainer> createState() => MainContainerState();
}

class MainContainerState extends State<MainContainer> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  String? _selectedCategory;
  LessonPlan? _editingPlan;

  final List<bool> _loadedPages = [true, false, false, false];

  int get selectedIndex => _selectedIndex;
  String? get selectedCategory => _selectedCategory;

  void selectCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      _selectedIndex = 0;
      _loadedPages[0] = true;
    });
  }

  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  void setSelectedIndex(int index) {
    final isAdmin = authService.isAdmin;
    if (index == 3 && !isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Only Admins can access the Create section. 🛡️"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      if (_selectedIndex == 3 && index != 3) {
        _editingPlan = null;
      }
      _selectedIndex = index;
      _loadedPages[index] = true;
    });
  }

  void switchToCreate([LessonPlan? plan]) {
    setState(() {
      _editingPlan = plan;
      _selectedIndex = 3;
      _loadedPages[3] = true;
    });
  }

  void switchToLesson() {
    setState(() {
      _editingPlan = null;
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        final isAdmin = authService.isAdmin;

        int effectiveIndex = _selectedIndex;
        int maxIndex = isAdmin ? 3 : 2;
        if (effectiveIndex > maxIndex) {
          effectiveIndex = 0;
        }

        return Scaffold(
          key: scaffoldKey,
          drawer: const AppDrawer(),
          body: IndexedStack(
            index: effectiveIndex,
            children: [
              LessonSelectionScreen(selectedCategory: _selectedCategory),
              _buildLazyPage(1, () => const FavoritesScreen()),
              _buildLazyPage(2, () => const DiscoverScreen()),
              _buildLazyPage(3, () => CreateScreen(existingPlan: _editingPlan)),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: effectiveIndex,
              onDestinationSelected: setSelectedIndex,
              backgroundColor: Theme.of(context).cardColor,
              indicatorColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(
                    Icons.menu_book_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  label: 'Lesson',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.translate_rounded),
                  selectedIcon: Icon(
                    Icons.translate_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  label: 'Vocabulary',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.explore_outlined),
                  selectedIcon: Icon(
                    Icons.explore_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  label: 'Discover',
                ),
                if (isAdmin)
                  NavigationDestination(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    selectedIcon: Icon(
                      Icons.add_circle_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    label: 'Create',
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLazyPage(int index, Widget Function() builder) {
    if (_loadedPages[index]) {
      return builder();
    } else {
      return const SizedBox.shrink();
    }
  }
}
