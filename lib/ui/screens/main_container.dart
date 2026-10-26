import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/features/lessons/presentation/screens/lesson_selection_screen.dart';
import 'package:superthai/features/lessons/presentation/screens/lesson_editor_screen.dart';
import 'package:superthai/ui/screens/favorites_screen.dart';
import 'package:superthai/ui/screens/discover_screen.dart';
import 'package:superthai/ui/screens/settings_screen.dart';
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
    setState(() {
      _selectedIndex = index;
      _loadedPages[index] = true;
    });
  }

  void switchToCreate([LessonPlan? plan]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateScreen(existingPlan: plan),
      ),
    );
  }

  void switchToLesson() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        return Scaffold(
          key: scaffoldKey,
          drawer: const AppDrawer(),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              LessonSelectionScreen(selectedCategory: _selectedCategory),
              _buildLazyPage(1, () => const FavoritesScreen()),
              _buildLazyPage(2, () => const DiscoverScreen()),
              _buildLazyPage(3, () => const SettingsScreen()),
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
              selectedIndex: _selectedIndex,
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
                NavigationDestination(
                  icon: const Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(
                    Icons.person_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  label: 'Profile',
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
