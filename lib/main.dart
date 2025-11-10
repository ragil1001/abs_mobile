import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import '../data/services/fake_gps_detector_service.dart';

import 'providers/auth_provider.dart';
import 'providers/izin_provider.dart';
import 'providers/presensi_provider.dart';
import 'providers/jadwal_provider.dart';
import 'providers/tukar_shift_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/lembur_provider.dart';
import 'providers/informasi_provider.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_routes.dart';
import 'data/services/dio_service.dart';
import 'data/services/cache_manager_service.dart';
import 'data/services/firebase_messaging_service.dart';

import 'data/models/tukar_shift_model.dart';

import './pages/auth/login_page.dart' as auth;
import './pages/home_page.dart';
import './pages/profile_page.dart';
import './pages/auth/ganti_password_page.dart';
import './pages/absensi_page.dart';
import './pages/data_absensi_page.dart';
import './pages/jadwal_page.dart';
import './pages/detail_izin_page.dart';
import './pages/detail_lembur_page.dart';
import './pages/notification_page.dart';
import './pages/history_absensi_page.dart';
import './pages/informasi_page.dart';
import './pages/detail_informasi_page.dart';
import './pages/tukar_shift/tukar_shift_detail_page.dart';
import './components/customNavbar.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ✅ Global logout handler untuk smooth transition
class LogoutHandler {
  static bool _isLoggingOut = false;

  static Future<void> performLogout(BuildContext context) async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    try {
      final authProvider = context.read<AuthProvider>();
      final notifProvider = context.read<NotificationProvider>();

      // Clear UI state first (instant)
      notifProvider.clear();

      // Navigate immediately (smooth)
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }

      // Logout in background (non-blocking)
      authProvider.logout().catchError((e) {
        debugPrint('⚠️ Background logout error: $e');
      });
    } finally {
      _isLoggingOut = false;
    }
  }
}

// ✅ Custom PageTransitionsBuilder dengan fade singkat untuk smooth experience
class OptimizedFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const OptimizedFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurveTween(curve: Curves.easeOut).animate(animation),
      child: child,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  await DioService().initialize();
  await CacheManagerService.autoCleanup();

  try {
    await Firebase.initializeApp();
    await FirebaseMessagingService.initialize(navigatorKey: navigatorKey);
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }

  try {
    await FakeGpsDetectorService().prewarmCache();
    debugPrint('✅ FakeGpsDetector cache prewarmed at app start');
  } catch (e) {
    debugPrint('⚠️ Failed to prewarm FakeGpsDetector cache: $e');
  }

  runApp(
    DevicePreview(enabled: !kReleaseMode, builder: (context) => const MyApp()),
  );
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
        ChangeNotifierProvider(create: (_) => JadwalProvider()),
        ChangeNotifierProvider(create: (_) => TukarShiftProvider()),
        ChangeNotifierProvider(create: (_) => LemburProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => InformasiProvider()),
      ],
      child: MaterialApp(
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        navigatorKey: navigatorKey,
        title: 'PT Qiprah Multi Service',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.white,
          fontFamily: 'Roboto',
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: OptimizedFadePageTransitionsBuilder(),
              TargetPlatform.iOS: OptimizedFadePageTransitionsBuilder(),
              TargetPlatform.fuchsia: OptimizedFadePageTransitionsBuilder(),
              TargetPlatform.linux: OptimizedFadePageTransitionsBuilder(),
              TargetPlatform.macOS: OptimizedFadePageTransitionsBuilder(),
              TargetPlatform.windows: OptimizedFadePageTransitionsBuilder(),
            },
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        routes: {
          AppRoutes.login: (context) => const auth.LoginPage(),
          AppRoutes.home: (context) => const MainApp(),
          AppRoutes.profile: (context) => const ProfilePage(),
          AppRoutes.changePassword: (context) => const GantiPasswordPage(),
          AppRoutes.absensi: (context) => const AbsensiPage(),
          AppRoutes.jadwal: (context) => const JadwalPage(),
          AppRoutes.notifications: (context) => const NotificationPage(),
          AppRoutes.historyAbsensi: (context) => const HistoryAbsensiPage(),
          AppRoutes.informasi: (context) => const InformasiPage(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.detailIzin) {
            final izinId = settings.arguments as int?;
            if (izinId != null) {
              return _createOptimizedRoute(
                DetailIzinPage(izinId: izinId),
                settings,
              );
            }
          }

          if (settings.name == AppRoutes.detailLembur) {
            final lemburId = settings.arguments as int?;
            if (lemburId != null) {
              return _createOptimizedRoute(
                DetailLemburPage(lemburId: lemburId),
                settings,
              );
            }
          }

          if (settings.name == AppRoutes.detailTukarShift) {
            final tukarShiftId = settings.arguments as int?;
            if (tukarShiftId != null) {
              return _createOptimizedRoute(
                _TukarShiftDetailLoader(tukarShiftId: tukarShiftId),
                settings,
              );
            }
          }

          if (settings.name == AppRoutes.detailInformasi) {
            final informasiKaryawanId = settings.arguments as int?;
            if (informasiKaryawanId != null) {
              return _createOptimizedRoute(
                DetailInformasiPage(informasiKaryawanId: informasiKaryawanId),
                settings,
              );
            }
          }

          return null;
        },
        home: const SplashScreen(),
      ),
    );
  }

  Route _createOptimizedRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 150),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeOut).animate(animation),
          child: child,
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    debugPrint('🔄 Initializing auth...');
    await authProvider.initAuth();

    if (!mounted) return;

    await _animationController.reverse(from: 1.0);

    if (!mounted) return;

    debugPrint(
      '🎯 Auth state: ${authProvider.isAuthenticated ? "Authenticated" : "Unauthenticated"}',
    );

    if (authProvider.isAuthenticated) {
      debugPrint('✅ User authenticated - navigating to home');
      Navigator.pushReplacementNamed(context, AppRoutes.home);

      Future.delayed(const Duration(milliseconds: 200), () {
        FirebaseMessagingService.markAppReady();
      });
    } else {
      debugPrint('❌ User not authenticated - navigating to login');
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppColors.primary.withOpacity(0.05)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.only(top: screenWidth * 0.03),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.business_rounded,
                            size: 60,
                            color: AppColors.primary,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'PT Qiprah Multi Service',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: const Text(
                      'Sistem Presensi Karyawan',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ SMOOTH NAVIGATION: IndexedStack + Fade Transition
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp>
    with RouteAware, WidgetsBindingObserver, TickerProviderStateMixin {
  int _currentIndex = 0;
  int _previousIndex = 0;

  bool _isLoadingBeranda = false;
  bool _isLoadingRiwayat = false;

  // ✅ Animation controller untuk smooth fade
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ✅ Setup fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200), // Smooth & fast
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseMessagingService.markAppReady();
      _refreshCurrentPage();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 App resumed - checking auth state');
      _checkAuthState();
    }
  }

  Future<void> _checkAuthState() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final isValid = await authProvider.isTokenValid();

    if (!isValid && authProvider.isAuthenticated) {
      debugPrint('⚠️ Token invalid - logging out');
      await authProvider.logout();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else if (isValid) {
      debugPrint('✅ Token still valid - refreshing data');
      _refreshCurrentPage();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _refreshCurrentPage() async {
    if (!mounted) return;

    if (_currentIndex == 0) {
      setState(() => _isLoadingBeranda = true);

      try {
        await Future.wait([
          context.read<PresensiProvider>().loadPresensiData(),
          context.read<NotificationProvider>().loadUnreadCount(),
          context.read<InformasiProvider>().loadUnreadCount(),
        ]);
      } finally {
        if (mounted) {
          setState(() => _isLoadingBeranda = false);
        }
      }
    } else if (_currentIndex == 1) {
      setState(() => _isLoadingRiwayat = true);

      try {
        final presensiProvider = context.read<PresensiProvider>();
        await presensiProvider.loadPresensiData();

        final presensiData = presensiProvider.presensiData;
        if (presensiData?.projectInfo != null) {
          final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
          await presensiProvider.loadStatistikPeriode(currentMonth);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoadingRiwayat = false);
        }
      }
    }
  }

  // ✅ INSTANT SHIMMER + REFRESH DATA
  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    // ✅ Langsung set loading state + ganti tab + trigger refresh
    if (index == 0) {
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = index;
        _isLoadingBeranda = true; // Langsung shimmer
      });

      // ✅ Langsung refresh data (tidak tunggu animasi)
      _refreshBerandaData();
    } else if (index == 1) {
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = index;
        _isLoadingRiwayat = true; // Langsung shimmer
      });

      // ✅ Langsung refresh data (tidak tunggu animasi)
      _refreshRiwayatData();
    }

    // ✅ Animasi berjalan PARALLEL dengan data loading
    _fadeController.reverse().then((_) {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  // ✅ Separated refresh methods untuk immediate execution
  Future<void> _refreshBerandaData() async {
    if (!mounted) return;

    try {
      // ✅ FORCE REFRESH: Gunakan refreshPresensiData untuk data terbaru
      await Future.wait([
        context.read<PresensiProvider>().refreshPresensiData(),
        context.read<NotificationProvider>().loadUnreadCount(),
        context.read<InformasiProvider>().loadUnreadCount(),
      ]);
    } finally {
      if (mounted) {
        setState(() => _isLoadingBeranda = false);
      }
    }
  }

  Future<void> _refreshRiwayatData() async {
    if (!mounted) return;

    try {
      final presensiProvider = context.read<PresensiProvider>();

      // ✅ FORCE REFRESH: Refresh presensi data dulu
      await presensiProvider.refreshPresensiData();

      final presensiData = presensiProvider.presensiData;
      if (presensiData?.projectInfo != null) {
        // ✅ CRITICAL: Calculate CURRENT PERIOD based on project start
        final projectStart = DateTime.parse(
          presensiData!.projectInfo!.tanggalMulai,
        );
        final today = DateTime.now();

        // Calculate how many complete months have passed since project start
        int monthsDiff =
            (today.year - projectStart.year) * 12 +
            (today.month - projectStart.month);

        // If today's day is before project start day, we're still in previous period
        if (today.day < projectStart.day) {
          monthsDiff--;
        }

        // Current period starts on project start day of the current calculated month
        final periodStart = DateTime(
          projectStart.year,
          projectStart.month + monthsDiff,
          projectStart.day,
        );

        // Format as yyyy-MM (for API compatibility)
        final currentPeriod = DateFormat('yyyy-MM').format(periodStart);

        debugPrint(
          '🔄 Refresh Riwayat - Current Period: $currentPeriod (from ${projectStart.day} ${DateFormat('MMM').format(periodStart)} to ${projectStart.day - 1} ${DateFormat('MMM').format(periodStart.add(Duration(days: 30)))} )',
        );

        // ✅ Refresh statistik dengan periode yang benar
        await presensiProvider.loadStatistikPeriode(currentPeriod);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingRiwayat = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            HomePage(isForceLoading: _isLoadingBeranda),
            DataAbsensiPage(isForceLoading: _isLoadingRiwayat),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: CustomBottomNavBar(
          circleRadius: 50,
          currentIndex: _currentIndex,
          onTabSelected: _onTabTapped,
        ),
      ),
    );
  }
}

class _TukarShiftDetailLoader extends StatefulWidget {
  final int tukarShiftId;

  const _TukarShiftDetailLoader({required this.tukarShiftId});

  @override
  State<_TukarShiftDetailLoader> createState() =>
      _TukarShiftDetailLoaderState();
}

class _TukarShiftDetailLoaderState extends State<_TukarShiftDetailLoader> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndNavigate();
    });
  }

  Future<void> _loadAndNavigate() async {
    final provider = Provider.of<TukarShiftProvider>(context, listen: false);

    if (provider.requests.isEmpty) {
      await provider.loadTukarShiftRequests();
    }

    if (!mounted) return;

    TukarShiftRequest? request;
    try {
      request = provider.requests.firstWhere(
        (r) => r.id == widget.tukarShiftId,
      );
    } catch (e) {
      request = null;
    }

    if (request != null) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              TukarShiftDetailPage(request: request!),
          transitionDuration: const Duration(milliseconds: 150),
          reverseTransitionDuration: const Duration(milliseconds: 150),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeOut).animate(animation),
              child: child,
            );
          },
        ),
      );
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Data tukar shift tidak ditemukan';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 253, 253),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: screenHeight * 0.02,
              ),
              color: Colors.white,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: screenWidth * 0.1,
                      height: screenWidth * 0.1,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: screenWidth * 0.045,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "Detail Tukar Shift",
                    style: TextStyle(
                      fontSize: screenWidth * 0.048,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(width: screenWidth * 0.1),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                  : Center(
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth * 0.06),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppColors.error.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage ?? 'Data tidak ditemukan',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Kembali'),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
