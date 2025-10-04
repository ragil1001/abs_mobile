import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'providers/auth_provider.dart';
import 'providers/izin_provider.dart';
import 'providers/presensi_provider.dart'; // UBAH DARI home_provider
import 'core/constants/app_colors.dart';
import 'core/constants/app_routes.dart';

import './pages/auth/login_page.dart';
import './pages/home_page.dart';
import './pages/profile_page.dart';
import './pages/auth/ganti_password_page.dart';
import './pages/absensi_page.dart';
import './pages/data_absensi_page.dart';
import './components/customNavbar.dart';

import 'providers/jadwal_provider.dart'; // TAMBAH INI
import 'pages/jadwal_page.dart'; // TAMBAH INI

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => IzinProvider()),
        ChangeNotifierProvider(create: (_) => PresensiProvider()),
        ChangeNotifierProvider(create: (_) => JadwalProvider()), // TAMBAH INI
      ],
      child: MaterialApp(
        // ... existing code ...
        routes: {
          AppRoutes.login: (context) => const LoginPage(),
          AppRoutes.home: (context) => const MainApp(),
          AppRoutes.profile: (context) => const ProfilePage(),
          AppRoutes.changePassword: (context) => const GantiPasswordPage(),
          AppRoutes.absensi: (context) => const AbsensiPage(),
          AppRoutes.jadwal: (context) => const JadwalPage(), // TAMBAH INI
        },
        home: const SplashScreen(),
      ),
    );
  }
}

// Splash Screen untuk cek auth state
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Initialize auth state
    await authProvider.initAuth();

    if (!mounted) return;

    // Navigate based on auth state
    if (authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.business_rounded,
                size: 50,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            // Company Name
            const Text(
              'PT Qiprah Multi Service',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sistem Presensi Karyawan',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

// MainApp dengan Bottom Navigation Bar
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [HomePage(), DataAbsensiPage()];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        circleRadius: 50,
        currentIndex: _currentIndex,
        onTabSelected: _onTabTapped,
      ),
    );
  }
}
