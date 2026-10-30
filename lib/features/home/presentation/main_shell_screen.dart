import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/services/entitlement_service.dart';
import 'home_screen.dart';
import '../../video_library/presentation/library_main_screen.dart';
import '../../mock_test/presentation/mock_test_landing_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    EntitlementService.syncUserEntitlements();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onSemesterChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onSemesterChanged: _onSemesterChanged),
      const LibraryMainScreen(),
      const MockTestLandingScreen(),
      ProfileScreen(onSemesterChanged: _onSemesterChanged),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.surface,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF334155) : AppColors.border,
              width: 1,
            ),
          ),
          boxShadow: AppColors.softCardShadow,
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: isDark ? const Color(0xFF1E293B) : AppColors.surface,
          elevation: 0,
          indicatorColor: isDark ? const Color(0xFF334155) : AppColors.primaryLight,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: [
            NavigationDestination(
              icon: Opacity(
                opacity: 0.65,
                child: Image.asset('assets/icons/ic_nav_home.png', width: 24, height: 24),
              ),
              selectedIcon: Image.asset('assets/icons/ic_nav_home.png', width: 26, height: 26),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Opacity(
                opacity: 0.65,
                child: Image.asset('assets/icons/ic_nav_library.png', width: 24, height: 24),
              ),
              selectedIcon: Image.asset('assets/icons/ic_nav_library.png', width: 26, height: 26),
              label: 'Library',
            ),
            NavigationDestination(
              icon: Opacity(
                opacity: 0.65,
                child: Image.asset('assets/icons/ic_nav_mock_test.png', width: 24, height: 24),
              ),
              selectedIcon: Image.asset('assets/icons/ic_nav_mock_test.png', width: 26, height: 26),
              label: 'Mock Test',
            ),
            NavigationDestination(
              icon: Opacity(
                opacity: 0.65,
                child: Image.asset('assets/icons/ic_nav_profile.png', width: 24, height: 24),
              ),
              selectedIcon: Image.asset('assets/icons/ic_nav_profile.png', width: 26, height: 26),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
