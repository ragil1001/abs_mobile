import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/presensi_provider.dart';
import '../providers/notification_provider.dart';
import '../components/custom_snackbar.dart';
import '../components/shimmer_loading.dart';
import 'profile_page.dart';
import 'pengajuan_izin_page.dart';
import 'pengajuan_lembur_page.dart';
import 'jadwal_page.dart';
import 'tukar_shift/tukar_shift_page.dart';
import 'dart:async';
import '../core/constants/app_routes.dart';

class HomePage extends StatefulWidget {
  final bool isForceLoading; // ✅ NEW parameter

  const HomePage({super.key, this.isForceLoading = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  Timer? _dateTimer;
  String _currentDate = '';
  final GlobalKey _whiteCardKey = GlobalKey();
  double _whiteCardHeight = 0;
  bool _hasShownWelcome = false; // ✅ NEW: Track welcome message

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.now());

    _dateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentDate = DateFormat(
            'd MMMM yyyy',
            'id_ID',
          ).format(DateTime.now());
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      _measureWhiteCard();
      _showWelcomeMessage(); // ✅ NEW: Show welcome after login
    });
  }

  // ✅ NEW: Show welcome message hanya sekali
  void _showWelcomeMessage() {
    if (!_hasShownWelcome && mounted) {
      _hasShownWelcome = true;

      // Delay sedikit agar page sudah fully loaded
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          final authProvider = context.read<AuthProvider>();
          final userName =
              authProvider.currentUser?.nama.split(' ').first ?? 'User';

          CustomSnackbar.showSuccess(
            context,
            'Selamat datang kembali, $userName! 👋',
          );
        }
      });
    }
  }

  Future<void> _loadInitialData() async {
    await context.read<PresensiProvider>().loadPresensiData();
    await _loadNotificationCount();
  }

  Future<void> _loadNotificationCount() async {
    try {
      await context.read<NotificationProvider>().loadUnreadCount();
    } catch (e) {
      debugPrint('Error loading notification count: $e');
    }
  }

  void _measureWhiteCard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox =
          _whiteCardKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && mounted) {
        setState(() {
          _whiteCardHeight = renderBox.size.height;
        });
      }
    });
  }

  // ✅ Refresh dengan shimmer effect
  Future<void> _refreshAllData() async {
    try {
      await Future.wait([
        context.read<AuthProvider>().initAuth(),
        context.read<PresensiProvider>().refreshPresensiData(),
        _loadNotificationCount(),
      ]);
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    }
  }

  @override
  void dispose() {
    _dateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final bool isVerySmallScreen = screenWidth < 340;
    final bool isSmallScreen = screenWidth >= 340 && screenWidth < 360;

    final padding = screenWidth * 0.05;
    final avatarSize = (screenWidth * 0.13).clamp(42.0, 56.0);
    final notifSize = (screenWidth * 0.12).clamp(40.0, 52.0);
    final companyIconSize = (screenWidth * 0.13).clamp(42.0, 56.0);

    final titleFontSize = (screenWidth * 0.052).clamp(16.0, 22.0);
    final subtitleFontSize = (screenWidth * 0.036).clamp(12.0, 16.0);
    final bodyFontSize = (screenWidth * 0.034).clamp(11.0, 15.0);
    final smallFontSize = (screenWidth * 0.035).clamp(10.0, 13.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer3<AuthProvider, PresensiProvider, NotificationProvider>(
          builder:
              (
                context,
                authProvider,
                presensiProvider,
                notificationProvider,
                child,
              ) {
                final karyawan = authProvider.currentUser;
                final namaParts = karyawan?.nama.split(' ') ?? [];
                final userName = namaParts.length >= 2
                    ? '${namaParts[0]} ${namaParts[1]}'
                    : (namaParts.isNotEmpty ? namaParts[0] : 'User');

                final presensiData = presensiProvider.presensiData;
                final unreadCount = notificationProvider.unreadCount;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _measureWhiteCard();
                });

                // ✅ Show shimmer jika loading ATAU force shimmer
                final shouldShowShimmer =
                    widget.isForceLoading || presensiProvider.isLoading;

                return RefreshIndicator(
                  onRefresh: _refreshAllData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: shouldShowShimmer
                        ? _buildShimmerLayout(
                            screenWidth,
                            screenHeight,
                            padding,
                            avatarSize,
                            notifSize,
                            companyIconSize,
                            titleFontSize,
                            subtitleFontSize,
                            isVerySmallScreen,
                            isSmallScreen,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  padding,
                                  screenHeight * 0.02,
                                  padding,
                                  0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        // ✅ Navigate ke profile
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ProfilePage(),
                                          ),
                                        );

                                        // ✅ Langsung refresh saat kembali
                                        if (mounted) {
                                          await _refreshAllData();
                                        }
                                      },
                                      child: Container(
                                        width: avatarSize,
                                        height: avatarSize,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color.fromARGB(
                                            255,
                                            221,
                                            225,
                                            231,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.08,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          size: avatarSize * 0.6,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Stack(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              AppRoutes.notifications,
                                            ).then((_) {
                                              _loadNotificationCount();
                                            });
                                          },
                                          child: Container(
                                            width: notifSize,
                                            height: notifSize,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.08),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.notifications_none,
                                              size: notifSize * 0.55,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (unreadCount > 0)
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              constraints: BoxConstraints(
                                                minWidth: isVerySmallScreen
                                                    ? 16
                                                    : 18,
                                                minHeight: isVerySmallScreen
                                                    ? 16
                                                    : 18,
                                              ),
                                              child: Text(
                                                unreadCount > 99
                                                    ? '99+'
                                                    : '$unreadCount',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: isVerySmallScreen
                                                      ? 9
                                                      : 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),

                              Container(
                                color: const Color.fromARGB(255, 250, 251, 253),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    padding,
                                    screenHeight * 0.02,
                                    padding,
                                    0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Halo, ',
                                                      style: TextStyle(
                                                        fontSize: titleFontSize,
                                                        fontWeight:
                                                            FontWeight.w300,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    Flexible(
                                                      child: Text(
                                                        userName,
                                                        style: TextStyle(
                                                          fontSize:
                                                              titleFontSize,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.black87,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: screenWidth * 0.01,
                                                    ),
                                                    Text(
                                                      '👋',
                                                      style: TextStyle(
                                                        fontSize: titleFontSize,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  height: screenHeight * 0.003,
                                                ),
                                                Text(
                                                  _currentDate,
                                                  style: TextStyle(
                                                    fontSize: subtitleFontSize,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: companyIconSize,
                                            height: companyIconSize,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                              border: Border.all(
                                                color: Colors.orange,
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.orange
                                                      .withOpacity(0.25),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.business,
                                              size: companyIconSize * 0.56,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: screenHeight * 0.022),

                                      if (presensiProvider.errorMessage != null)
                                        _buildErrorCard(
                                          screenWidth,
                                          screenHeight,
                                          presensiProvider.errorMessage!,
                                        )
                                      else
                                        _buildDataCard(
                                          screenWidth,
                                          screenHeight,
                                          bodyFontSize,
                                          smallFontSize,
                                          presensiData,
                                        ),
                                      SizedBox(height: screenHeight * 0.028),
                                    ],
                                  ),
                                ),
                              ),

                              Padding(
                                padding: EdgeInsets.all(padding),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Menu Lainnya',
                                      style: TextStyle(
                                        fontSize: (screenWidth * 0.042).clamp(
                                          14.0,
                                          18.0,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.017),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildMenuCard(
                                          assetPath: 'assets/izin.webp',
                                          label: 'Izin',
                                          screenWidth: screenWidth,
                                          screenHeight: screenHeight,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const PengajuanIzinPage(),
                                              ),
                                            );
                                          },
                                        ),
                                        _buildMenuCard(
                                          assetPath: 'assets/lembur.webp',
                                          label: 'Lembur',
                                          screenWidth: screenWidth,
                                          screenHeight: screenHeight,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const PengajuanLemburPage(),
                                              ),
                                            );
                                          },
                                        ),
                                        _buildMenuCard(
                                          assetPath: 'assets/shift.webp',
                                          label: 'Tukar Shift',
                                          screenWidth: screenWidth,
                                          screenHeight: screenHeight,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const TukarShiftPage(),
                                              ),
                                            );
                                          },
                                        ),
                                        _buildMenuCard(
                                          assetPath: 'assets/jadwal.webp',
                                          label: 'Jadwal',
                                          screenWidth: screenWidth,
                                          screenHeight: screenHeight,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const JadwalPage(),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: screenHeight * 0.02),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                  ),
                );
              },
        ),
      ),
    );
  }

  Widget _buildErrorCard(
    double screenWidth,
    double screenHeight,
    String error,
  ) {
    final isVerySmallScreen = screenWidth < 340;
    final topOffset = isVerySmallScreen
        ? screenHeight * 0.04
        : screenHeight * 0.045;

    return SizedBox(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: screenWidth * 0.026,
              left: screenWidth * 0.026,
              right: screenWidth * 0.026,
              bottom: topOffset + 16,
            ),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'PT Qiprah Multi Service',
                  style: TextStyle(
                    fontSize: (screenWidth * 0.039).clamp(13.0, 17.0),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: topOffset),
                Container(
                  key: _whiteCardKey,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        error,
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(
    double screenWidth,
    double screenHeight,
    double bodyFontSize,
    double smallFontSize,
    presensiData,
  ) {
    final statistik = presensiData?.statistik;
    final jadwal = presensiData?.jadwalHariIni;
    final presensi = presensiData?.presensiHariIni;
    final isVerySmallScreen = screenWidth < 340;
    final topOffset = isVerySmallScreen
        ? screenHeight * 0.005
        : screenHeight * 0.01;

    return SizedBox(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: screenWidth * 0.026,
              left: screenWidth * 0.01,
              right: screenWidth * 0.01,
              bottom: topOffset - 3,
            ),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'PT Qiprah Multi Service',
                  style: TextStyle(
                    fontSize: (screenWidth * 0.039).clamp(13.0, 17.0),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: topOffset),
                Container(
                  key: _whiteCardKey,
                  padding: EdgeInsets.all(
                    isVerySmallScreen
                        ? screenWidth * 0.035
                        : screenWidth * 0.042,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Hadir',
                            '${statistik?.hadir ?? 0} Hari',
                            bodyFontSize,
                            smallFontSize,
                          ),
                          _buildStatItem(
                            'Izin',
                            '${statistik?.izin ?? 0} Hari',
                            bodyFontSize,
                            smallFontSize,
                          ),
                          _buildStatItem(
                            'Alpa',
                            '${statistik?.alpa ?? 0} Hari',
                            bodyFontSize,
                            smallFontSize,
                          ),
                        ],
                      ),
                      SizedBox(height: isVerySmallScreen ? 14 : 18),

                      if (jadwal != null && jadwal.isLibur)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.01,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade50,
                                Colors.green.shade100,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.weekend,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Hari Libur',
                                style: TextStyle(
                                  fontSize: bodyFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (jadwal != null)
                        Container(
                          padding: EdgeInsets.all(isVerySmallScreen ? 10 : 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade50,
                                Colors.blue.shade100,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Jadwal Shift Hari Ini',
                                style: TextStyle(
                                  fontSize: smallFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade700,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      jadwal.shiftCode,
                                      style: TextStyle(
                                        fontSize: bodyFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${_formatTimeWithoutSeconds(jadwal.waktuMulai)} - ${_formatTimeWithoutSeconds(jadwal.waktuSelesai)}',
                                    style: TextStyle(
                                      fontSize: bodyFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: EdgeInsets.all(isVerySmallScreen ? 10 : 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            'Tidak ada jadwal hari ini',
                            style: TextStyle(
                              fontSize: smallFontSize,
                              color: Colors.black54,
                            ),
                          ),
                        ),

                      SizedBox(height: isVerySmallScreen ? 12 : 16),

                      if (jadwal != null && !jadwal.isLibur)
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(
                                  isVerySmallScreen ? 8 : 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.login,
                                      color: Colors.green[600],
                                      size: (screenWidth * 0.073).clamp(
                                        20.0,
                                        28.0,
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.02),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            presensi?.isAlpa == true
                                                ? '-'
                                                : (presensi?.statusMasuk ==
                                                          'izin'
                                                      ? 'Izin'
                                                      : _formatTimeWithoutSeconds(
                                                          presensi?.waktuMasuk,
                                                        )),
                                            style: TextStyle(
                                              fontSize: (screenWidth * 0.042)
                                                  .clamp(14.0, 18.0),
                                              fontWeight: FontWeight.bold,
                                              color: presensi?.isAlpa == true
                                                  ? Colors.red
                                                  : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            presensi?.isAlpa == true
                                                ? 'Alpa'
                                                : 'Masuk',
                                            style: TextStyle(
                                              fontSize: smallFontSize,
                                              color: presensi?.isAlpa == true
                                                  ? Colors.red
                                                  : Colors.black54,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(
                                  isVerySmallScreen ? 8 : 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.logout,
                                      color: Colors.red[600],
                                      size: (screenWidth * 0.073).clamp(
                                        20.0,
                                        28.0,
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.02),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            presensi?.isAlpa == true
                                                ? '-'
                                                : (presensi?.statusMasuk ==
                                                          'izin'
                                                      ? 'Izin'
                                                      : _formatTimeWithoutSeconds(
                                                          presensi?.waktuPulang,
                                                        )),
                                            style: TextStyle(
                                              fontSize: (screenWidth * 0.042)
                                                  .clamp(14.0, 18.0),
                                              fontWeight: FontWeight.bold,
                                              color: presensi?.isAlpa == true
                                                  ? Colors.red
                                                  : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            presensi?.isAlpa == true
                                                ? 'Alpa'
                                                : 'Pulang',
                                            style: TextStyle(
                                              fontSize: smallFontSize,
                                              color: presensi?.isAlpa == true
                                                  ? Colors.red
                                                  : Colors.black54,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    double labelSize,
    double valueSize,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: labelSize,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required String assetPath,
    required String label,
    required double screenWidth,
    required double screenHeight,
    VoidCallback? onTap,
  }) {
    // Hitung lebar card agar muat 4 dalam 1 baris
    // Formula: (screenWidth - (padding kiri + kanan) - (3 spacing)) / 4
    final horizontalPadding = screenWidth * 0.05 * 2; // padding kiri & kanan
    final totalSpacing = screenWidth * 0.04 * 3; // 3 spacing untuk 4 card
    final cardWidth = (screenWidth - horizontalPadding - totalSpacing) / 4;

    // Sesuaikan tinggi card (hanya untuk kotak, tidak termasuk label)
    final cardHeight = cardWidth * 0.85; // Kotak persegi

    final labelSize = (screenWidth * 0.028).clamp(9.0, 12.0);
    final iconSize = cardWidth * 0.7; // Icon 55% dari lebar card

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Kotak card dengan icon
            Container(
              height: cardHeight,
              width: cardWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  assetPath,
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.image_not_supported,
                      color: Colors.grey.shade400,
                      size: iconSize * 0.6,
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 6),
            // Label di bawah kotak
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLayout(
    double screenWidth,
    double screenHeight,
    double padding,
    double avatarSize,
    double notifSize,
    double companyIconSize,
    double titleFontSize,
    double subtitleFontSize,
    bool isVerySmallScreen,
    bool isSmallScreen,
  ) {
    // Gunakan formula yang sama dengan _buildMenuCard untuk konsistensi
    final horizontalPadding = screenWidth * 0.05 * 2;
    final totalSpacing = screenWidth * 0.04 * 3;
    final cardWidth = (screenWidth - horizontalPadding - totalSpacing) / 4;
    final cardHeight = cardWidth * 0.85;

    return ShimmerLoading(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              padding,
              screenHeight * 0.02,
              padding,
              0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(
                  width: avatarSize,
                  height: avatarSize,
                  borderRadius: avatarSize / 2,
                ),
                ShimmerBox(
                  width: notifSize,
                  height: notifSize,
                  borderRadius: notifSize / 2,
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Container(
            color: const Color.fromARGB(255, 250, 251, 253),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                padding,
                screenHeight * 0.02,
                padding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(
                              width: screenWidth * 0.4,
                              height: titleFontSize,
                              borderRadius: 4,
                            ),
                            SizedBox(height: screenHeight * 0.003),
                            ShimmerBox(
                              width: screenWidth * 0.3,
                              height: subtitleFontSize,
                              borderRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      ShimmerBox(
                        width: companyIconSize,
                        height: companyIconSize,
                        borderRadius: companyIconSize / 2,
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.022),
                  ShimmerBox(
                    width: double.infinity,
                    height: _whiteCardHeight > 0
                        ? _whiteCardHeight + 36.0 + screenHeight * 0.01
                        : screenHeight * 0.35,
                    borderRadius: 16,
                  ),
                  SizedBox(height: screenHeight * 0.028),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: screenWidth * 0.3,
                  height: (screenWidth * 0.042).clamp(14.0, 18.0),
                  borderRadius: 4,
                ),
                SizedBox(height: screenHeight * 0.017),
                // 4 menu cards dalam 1 baris dengan spacing yang sama
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        ShimmerBox(
                          width: cardWidth,
                          height: cardHeight,
                          borderRadius: 20,
                        ),
                        SizedBox(height: 6),
                        ShimmerBox(
                          width: cardWidth * 0.8,
                          height: (screenWidth * 0.028).clamp(9.0, 12.0),
                          borderRadius: 4,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        ShimmerBox(
                          width: cardWidth,
                          height: cardHeight,
                          borderRadius: 20,
                        ),
                        SizedBox(height: 6),
                        ShimmerBox(
                          width: cardWidth * 0.8,
                          height: (screenWidth * 0.028).clamp(9.0, 12.0),
                          borderRadius: 4,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        ShimmerBox(
                          width: cardWidth,
                          height: cardHeight,
                          borderRadius: 20,
                        ),
                        SizedBox(height: 6),
                        ShimmerBox(
                          width: cardWidth * 0.8,
                          height: (screenWidth * 0.028).clamp(9.0, 12.0),
                          borderRadius: 4,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        ShimmerBox(
                          width: cardWidth,
                          height: cardHeight,
                          borderRadius: 20,
                        ),
                        SizedBox(height: 6),
                        ShimmerBox(
                          width: cardWidth * 0.8,
                          height: (screenWidth * 0.028).clamp(9.0, 12.0),
                          borderRadius: 4,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

String _formatTimeWithoutSeconds(String? timeString) {
  if (timeString == null || timeString.isEmpty || timeString == '-') {
    return '-';
  }

  try {
    if (timeString.length <= 5) {
      return timeString;
    }

    if (timeString.length >= 8 && timeString.contains(':')) {
      return timeString.substring(0, 5);
    }

    return timeString;
  } catch (e) {
    return timeString;
  }
}
