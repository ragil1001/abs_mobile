import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/presensi_provider.dart';
import 'profile_page.dart';
import 'pengajuan_izin_page.dart';
import 'jadwal_page.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _notificationCount = 3;
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
    });
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
        child: Consumer2<AuthProvider, PresensiProvider>(
          builder: (context, authProvider, presensiProvider, child) {
            final karyawan = authProvider.currentUser;
            final userName = karyawan?.nama.split(' ').first ?? 'User';
            final presensiData = presensiProvider.presensiData;

            // Trigger measurement after data changes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _measureWhiteCard();
            });

            return RefreshIndicator(
              onRefresh: () => presensiProvider.refreshPresensiData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfilePage(),
                                ),
                              );
                            },
                            child: Container(
                              width: avatarSize,
                              height: avatarSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color.fromARGB(255, 221, 225, 231),
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
                                  setState(() {
                                    _notificationCount = 0;
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
                                        color: Colors.black.withOpacity(0.08),
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
                              if (_notificationCount > 0)
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
                                      minWidth: isVerySmallScreen ? 16 : 18,
                                      minHeight: isVerySmallScreen ? 16 : 18,
                                    ),
                                    child: Text(
                                      '$_notificationCount',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isVerySmallScreen ? 9 : 10,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: screenWidth * 0.01),
                                          Text(
                                            '👋',
                                            style: TextStyle(
                                              fontSize: titleFontSize,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: screenHeight * 0.003),
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
                                        color: Colors.orange.withOpacity(0.25),
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

                            if (presensiProvider.isLoading)
                              _buildLoadingCard(screenWidth, screenHeight)
                            else if (presensiProvider.errorMessage != null)
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
                              fontSize: (screenWidth * 0.042).clamp(14.0, 18.0),
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.017),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMenuCard(
                                  icon: Icons.assignment_outlined,
                                  label: 'Izin',
                                  color: Colors.orange,
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  isSmall: isVerySmallScreen || isSmallScreen,
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
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Expanded(
                                child: _buildMenuCard(
                                  icon: Icons.swap_horiz,
                                  label: 'Tukar Shift',
                                  color: Colors.blue,
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  isSmall: isVerySmallScreen || isSmallScreen,
                                  onTap: () {},
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Expanded(
                                child: _buildMenuCard(
                                  icon: Icons.calendar_today,
                                  label: 'Jadwal',
                                  color: Colors.purple,
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  isSmall: isVerySmallScreen || isSmallScreen,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const JadwalPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.02),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingCard(double screenWidth, double screenHeight) {
    final isVerySmallScreen = screenWidth < 340;
    final headerHeight = isVerySmallScreen ? 32.0 : 36.0;
    final topOffset = isVerySmallScreen
        ? screenHeight * 0.04
        : screenHeight * 0.045;

    // Estimasi tinggi minimal untuk loading state
    final estimatedHeight = headerHeight + topOffset + 200;

    return SizedBox(
      height: estimatedHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: estimatedHeight,
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
            padding: EdgeInsets.all(screenWidth * 0.026),
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                'PT Qiprah Multi Service',
                style: TextStyle(
                  fontSize: (screenWidth * 0.039).clamp(13.0, 17.0),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: topOffset,
            left: 4,
            right: 4,
            child: Container(
              padding: EdgeInsets.all(screenWidth * 0.042),
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
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(
    double screenWidth,
    double screenHeight,
    String error,
  ) {
    final isVerySmallScreen = screenWidth < 340;
    final headerHeight = isVerySmallScreen ? 32.0 : 36.0;
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
    final headerHeight = isVerySmallScreen ? 32.0 : 36.0;
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
                                    '${jadwal.waktuMulai ?? '-'} - ${jadwal.waktuSelesai ?? '-'}',
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
                                            // CRITICAL: Jika alpa, tampilkan strip
                                            presensi?.isAlpa == true
                                                ? '-'
                                                : (presensi?.waktuMasuk ?? '-'),
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
                                            // CRITICAL: Jika alpa, tampilkan strip
                                            presensi?.isAlpa == true
                                                ? '-'
                                                : (presensi?.waktuPulang ??
                                                      '-'),
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
    final cardHeight = isSmall ? screenHeight * 0.095 : screenHeight * 0.1;
    final iconSize = (screenWidth * 0.057).clamp(18.0, 24.0);
    final labelSize = (screenWidth * 0.031).clamp(10.0, 14.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              top: -12,
              child: Container(
                width: screenWidth * 0.13,
                height: screenWidth * 0.13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isSmall ? 8 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmall ? 6 : 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.18),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: iconSize, color: color),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: labelSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
