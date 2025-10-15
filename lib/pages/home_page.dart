import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/presensi_provider.dart';
import '../providers/notification_provider.dart'; // ✅ Add this
import '../components/shimmer_loading.dart';
import 'profile_page.dart';
import 'pengajuan_izin_page.dart';
import 'jadwal_page.dart';
import 'tukar_shift/tukar_shift_page.dart';
import 'dart:async';
import '../core/constants/app_routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _dateTimer;
  String _currentDate = '';
  final GlobalKey _whiteCardKey = GlobalKey();
  double _whiteCardHeight = 0;

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
      context.read<PresensiProvider>().loadPresensiData();
      _measureWhiteCard();
      // ✅ Load notification count
      _loadNotificationCount();
    });
  }

  Future<void> _loadNotificationCount() async {
    try {
      await context.read<NotificationProvider>().loadUnreadCount();
    } catch (e) {
      print('Error loading notification count: $e');
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

  @override
  void dispose() {
    _dateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final bool isVerySmallScreen = screenWidth < 340;
    final bool isSmallScreen = screenWidth >= 340 && screenWidth < 360;
    final bool isMediumScreen = screenWidth >= 360 && screenWidth < 400;

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
          builder: (context, authProvider, presensiProvider, notificationProvider, child) {
            final karyawan = authProvider.currentUser;
            final userName = karyawan?.nama.split(' ').first ?? 'User';
            final presensiData = presensiProvider.presensiData;
            final unreadCount =
                notificationProvider.unreadCount; // ✅ Get real count

            // Trigger measurement after data changes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _measureWhiteCard();
            });

            return RefreshIndicator(
              onRefresh: () async {
                await presensiProvider.refreshPresensiData();
                await _loadNotificationCount(); // ✅ Refresh notification count
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: presensiProvider.isLoading
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ProfilePage(),
                                      ),
                                    );
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
                                          color: Colors.black.withOpacity(0.08),
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
                                        // Navigate ke notification page
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.notifications,
                                        ).then((_) {
                                          // ✅ Refresh notification count setelah kembali
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
                                              color: Colors.black.withOpacity(
                                                0.08,
                                              ),
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
                                    // ✅ Real-time badge from NotificationProvider
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                                    fontWeight: FontWeight.w300,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                Flexible(
                                                  child: Text(
                                                    userName,
                                                    style: TextStyle(
                                                      fontSize: titleFontSize,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                              color: Colors.orange.withOpacity(
                                                0.25,
                                              ),
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
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    _buildMenuCard(
                                      icon: Icons.assignment_outlined,
                                      label: 'Izin',
                                      color: Colors.orange,
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                      isSmall:
                                          isVerySmallScreen || isSmallScreen,
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
                                    SizedBox(width: screenWidth * 0.04),
                                    _buildMenuCard(
                                      icon: Icons.swap_horiz,
                                      label: 'Tukar Shift',
                                      color: Colors.blue,
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                      isSmall:
                                          isVerySmallScreen || isSmallScreen,
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
                                    SizedBox(width: screenWidth * 0.04),
                                    _buildMenuCard(
                                      icon: Icons.calendar_today,
                                      label: 'Jadwal',
                                      color: Colors.purple,
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                      isSmall:
                                          isVerySmallScreen || isSmallScreen,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const JadwalPage(),
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

  // ... rest of the widget methods remain the same ...
  // (I'll include the key ones below)

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
    required IconData icon,
    required String label,
    required Color color,
    required double screenWidth,
    required double screenHeight,
    required bool isSmall,
    VoidCallback? onTap,
  }) {
    final cardHeight = isSmall ? screenHeight * 0.10 : screenHeight * 0.11;
    final cardWidth = isSmall ? screenWidth * 0.22 : screenWidth * 0.24;
    final labelSize = (screenWidth * 0.032).clamp(11.0, 14.0);
    final iconBarHeight = cardHeight * 0.65;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight,
        width: cardWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: iconBarHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: color,
                  size: (screenWidth * 0.09).clamp(22.0, 28.0),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
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
    final cardHeight = (isVerySmallScreen || isSmallScreen)
        ? screenHeight * 0.10
        : screenHeight * 0.11;
    final cardWidth = (isVerySmallScreen || isSmallScreen)
        ? screenWidth * 0.22
        : screenWidth * 0.24;

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ShimmerBox(
                      width: cardWidth,
                      height: cardHeight,
                      borderRadius: 15,
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    ShimmerBox(
                      width: cardWidth,
                      height: cardHeight,
                      borderRadius: 15,
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    ShimmerBox(
                      width: cardWidth,
                      height: cardHeight,
                      borderRadius: 15,
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
    // Jika format sudah HH:mm, return as is
    if (timeString.length <= 5) {
      return timeString;
    }

    // Jika format HH:mm:ss, ambil 5 karakter pertama (HH:mm)
    if (timeString.length >= 8 && timeString.contains(':')) {
      return timeString.substring(0, 5);
    }

    return timeString;
  } catch (e) {
    return timeString;
  }
}
