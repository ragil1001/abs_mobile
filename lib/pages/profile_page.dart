// lib/presentation/pages/home/profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../core/constants/app_colors.dart';
import '../components/shimmer_loading.dart';
import './auth/ganti_password_page.dart';
import '../main.dart'; // Import untuk LogoutHandler

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  bool get _shouldRefresh {
    if (_lastRefreshTime == null) return true;
    return DateTime.now().difference(_lastRefreshTime!).inSeconds > 30;
  }

  Future<void> _loadData() async {
    if (!_shouldRefresh) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    _lastRefreshTime = DateTime.now();

    final startTime = DateTime.now();

    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initAuth();
    }

    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < const Duration(milliseconds: 300)) {
      await Future.delayed(const Duration(milliseconds: 300) - elapsed);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final bool isVerySmallScreen = screenWidth < 340;

    final padding = screenWidth * 0.06;
    final headerFontSize = (screenWidth * 0.048).clamp(16.0, 20.0);
    final nameFontSize = (screenWidth * 0.058).clamp(18.0, 24.0);
    final subtitleFontSize = (screenWidth * 0.036).clamp(12.0, 15.0);
    final labelFontSize = (screenWidth * 0.036).clamp(12.0, 15.0);
    final valueFontSize = (screenWidth * 0.036).clamp(12.0, 15.0);
    final buttonTextFontSize = (screenWidth * 0.04).clamp(13.0, 17.0);
    final avatarSize = (screenWidth * 0.24).clamp(70.0, 100.0);
    final iconSize = (screenWidth * 0.12).clamp(35.0, 50.0);
    final buttonIconSize = (screenWidth * 0.11).clamp(36.0, 46.0);
    final arrowIconSize = (screenWidth * 0.045).clamp(14.0, 18.0);
    final backButtonSize = (screenWidth * 0.1).clamp(36.0, 42.0);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 253, 253),
      body: SafeArea(
        child: _isLoading
            ? _buildShimmerLayout(
                screenWidth,
                screenHeight,
                padding,
                avatarSize,
                nameFontSize,
                subtitleFontSize,
                labelFontSize,
                buttonIconSize,
                backButtonSize,
                isVerySmallScreen,
              )
            : Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final karyawan = authProvider.currentUser;

                  if (karyawan == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: padding,
                          vertical: screenHeight * 0.02,
                        ),
                        color: Colors.white,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: backButtonSize,
                                height: backButtonSize,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.arrow_back_ios_new,
                                  size: arrowIconSize,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "Profile",
                              style: TextStyle(
                                fontSize: headerFontSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(width: backButtonSize),
                          ],
                        ),
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(
                                height: isVerySmallScreen
                                    ? screenHeight * 0.02
                                    : screenHeight * 0.03,
                              ),

                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: padding,
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(
                                    isVerySmallScreen
                                        ? screenWidth * 0.04
                                        : screenWidth * 0.05,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: avatarSize,
                                        height: avatarSize,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(
                                            0.1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.person_outline,
                                          size: iconSize,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      SizedBox(
                                        height: isVerySmallScreen
                                            ? screenHeight * 0.015
                                            : screenHeight * 0.02,
                                      ),
                                      Text(
                                        karyawan.nama,
                                        style: TextStyle(
                                          fontSize: nameFontSize,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                          letterSpacing: 0.3,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: screenHeight * 0.005),
                                      Text(
                                        "${karyawan.jabatan.nama.isNotEmpty ? karyawan.jabatan.nama : '-'} • "
                                        "${karyawan.divisi.nama.isNotEmpty ? karyawan.divisi.nama : '-'}",
                                        style: TextStyle(
                                          fontSize: subtitleFontSize,
                                          color: Colors.black45,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(
                                        height: isVerySmallScreen
                                            ? screenHeight * 0.015
                                            : screenHeight * 0.02,
                                      ),
                                      Container(
                                        height: 1,
                                        color: const Color(0xFFF0F0F0),
                                      ),
                                      SizedBox(
                                        height: isVerySmallScreen
                                            ? screenHeight * 0.02
                                            : screenHeight * 0.025,
                                      ),
                                      _buildInfoItem(
                                        "NIK",
                                        karyawan.nik,
                                        screenWidth,
                                        labelFontSize,
                                        valueFontSize,
                                        isVerySmallScreen,
                                      ),
                                      _buildInfoItem(
                                        "Divisi",
                                        karyawan.divisi.nama.isNotEmpty
                                            ? karyawan.divisi.nama
                                            : '-',
                                        screenWidth,
                                        labelFontSize,
                                        valueFontSize,
                                        isVerySmallScreen,
                                      ),
                                      _buildInfoItem(
                                        "Jabatan",
                                        karyawan.jabatan.nama,
                                        screenWidth,
                                        labelFontSize,
                                        valueFontSize,
                                        isVerySmallScreen,
                                      ),
                                      _buildInfoItem(
                                        "Project",
                                        karyawan.project?.nama ??
                                            "Belum ada project",
                                        screenWidth,
                                        labelFontSize,
                                        valueFontSize,
                                        isVerySmallScreen,
                                      ),
                                      _buildInfoItem(
                                        "No Telepon",
                                        karyawan.noTelepon,
                                        screenWidth,
                                        labelFontSize,
                                        valueFontSize,
                                        isVerySmallScreen,
                                      ),
                                      _buildInfoItem(
                                        "Jenis Kelamin",
                                        karyawan.jenisKelaminText,
                                        screenWidth,
                                        labelFontSize,
                                        valueFontSize,
                                        isVerySmallScreen,
                                      ),
                                      _buildInfoItem(
                                        "Tanggal Lahir",
                                        karyawan.formattedTanggalLahir,
                                        screenWidth,
                                        labelFontSize,
                                        valueFontSize,
                                        isVerySmallScreen,
                                      ),
                                      _buildInfoItem(
                                        "Tanggal Bergabung",
                                        karyawan.formattedTanggalBergabung,
                                        screenWidth,
                                        labelFontSize,
                                        valueFontSize,
                                        isVerySmallScreen,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(
                                height: isVerySmallScreen
                                    ? screenHeight * 0.02
                                    : screenHeight * 0.025,
                              ),

                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: padding,
                                ),
                                child: Column(
                                  children: [
                                    _buildActionButton(
                                      "Ganti Password",
                                      Icons.lock_outline,
                                      screenWidth,
                                      screenHeight,
                                      buttonIconSize,
                                      buttonTextFontSize,
                                      arrowIconSize,
                                      isVerySmallScreen,
                                      () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const GantiPasswordPage(),
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(
                                      height: isVerySmallScreen
                                          ? screenHeight * 0.012
                                          : screenHeight * 0.015,
                                    ),
                                    _buildActionButton(
                                      "Logout",
                                      Icons.logout,
                                      screenWidth,
                                      screenHeight,
                                      buttonIconSize,
                                      buttonTextFontSize,
                                      arrowIconSize,
                                      isVerySmallScreen,
                                      () => _showLogoutDialog(
                                        context,
                                        screenWidth,
                                        screenHeight,
                                        headerFontSize,
                                        subtitleFontSize,
                                        buttonTextFontSize,
                                      ),
                                      isLogout: true,
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(
                                height: isVerySmallScreen
                                    ? screenHeight * 0.03
                                    : screenHeight * 0.04,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildShimmerLayout(
    double screenWidth,
    double screenHeight,
    double padding,
    double avatarSize,
    double nameFontSize,
    double subtitleFontSize,
    double labelFontSize,
    double buttonIconSize,
    double backButtonSize,
    bool isVerySmallScreen,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: padding,
            vertical: screenHeight * 0.02,
          ),
          color: Colors.white,
          child: Row(
            children: [
              ShimmerLoading(
                child: ShimmerBox(
                  width: backButtonSize,
                  height: backButtonSize,
                  borderRadius: 12,
                ),
              ),
              const Spacer(),
              ShimmerLoading(
                child: ShimmerBox(
                  width: screenWidth * 0.25,
                  height: (screenWidth * 0.048).clamp(16.0, 20.0),
                  borderRadius: 4,
                ),
              ),
              const Spacer(),
              SizedBox(width: backButtonSize),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: isVerySmallScreen
                      ? screenHeight * 0.02
                      : screenHeight * 0.03,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: ShimmerLoading(
                    child: Container(
                      padding: EdgeInsets.all(
                        isVerySmallScreen
                            ? screenWidth * 0.04
                            : screenWidth * 0.05,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          ShimmerBox(
                            width: avatarSize,
                            height: avatarSize,
                            borderRadius: avatarSize / 2,
                          ),
                          SizedBox(
                            height: isVerySmallScreen
                                ? screenHeight * 0.015
                                : screenHeight * 0.02,
                          ),
                          ShimmerBox(
                            width: screenWidth * 0.5,
                            height: nameFontSize,
                            borderRadius: 4,
                          ),
                          const SizedBox(height: 8),
                          ShimmerBox(
                            width: screenWidth * 0.4,
                            height: subtitleFontSize,
                            borderRadius: 4,
                          ),
                          SizedBox(
                            height: isVerySmallScreen
                                ? screenHeight * 0.015
                                : screenHeight * 0.02,
                          ),
                          Container(height: 1, color: const Color(0xFFF0F0F0)),
                          SizedBox(
                            height: isVerySmallScreen
                                ? screenHeight * 0.02
                                : screenHeight * 0.025,
                          ),
                          ...List.generate(
                            8,
                            (index) => Padding(
                              padding: EdgeInsets.only(
                                bottom: isVerySmallScreen
                                    ? screenWidth * 0.03
                                    : screenWidth * 0.04,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ShimmerBox(
                                    width: screenWidth * 0.3,
                                    height: labelFontSize,
                                    borderRadius: 4,
                                  ),
                                  ShimmerBox(
                                    width: screenWidth * 0.35,
                                    height: labelFontSize,
                                    borderRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: isVerySmallScreen
                      ? screenHeight * 0.02
                      : screenHeight * 0.025,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: ShimmerLoading(
                    child: Column(
                      children: [
                        ShimmerBox(
                          width: double.infinity,
                          height: isVerySmallScreen ? 55 : 60,
                          borderRadius: 16,
                        ),
                        SizedBox(
                          height: isVerySmallScreen
                              ? screenHeight * 0.012
                              : screenHeight * 0.015,
                        ),
                        ShimmerBox(
                          width: double.infinity,
                          height: isVerySmallScreen ? 55 : 60,
                          borderRadius: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: isVerySmallScreen
                      ? screenHeight * 0.03
                      : screenHeight * 0.04,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    double screenWidth,
    double labelFontSize,
    double valueFontSize,
    bool isVerySmallScreen, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast
            ? 0
            : (isVerySmallScreen ? screenWidth * 0.03 : screenWidth * 0.04),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: screenWidth * 0.35,
            child: Text(
              label,
              style: TextStyle(
                fontSize: labelFontSize,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    double screenWidth,
    double screenHeight,
    double iconSize,
    double textSize,
    double arrowSize,
    bool isVerySmallScreen,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    final buttonHeight = isVerySmallScreen ? 55.0 : 60.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: buttonHeight,
        padding: EdgeInsets.symmetric(
          horizontal: isVerySmallScreen
              ? screenWidth * 0.04
              : screenWidth * 0.05,
          vertical: screenHeight * 0.015,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: isLogout
                    ? AppColors.error.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: iconSize * 0.5,
                color: isLogout ? AppColors.error : AppColors.primary,
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: textSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: arrowSize,
              color: Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ OPTIMIZED: Logout dialog dengan smooth transition
  void _showLogoutDialog(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    double headerFontSize,
    double subtitleFontSize,
    double buttonTextFontSize,
  ) {
    final iconSize = (screenWidth * 0.15).clamp(50.0, 64.0);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.all(screenWidth * 0.06),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout,
                color: AppColors.error,
                size: iconSize * 0.5,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              "Logout",
              style: TextStyle(
                fontSize: headerFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              "Apakah Anda yakin ingin keluar?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: subtitleFontSize,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: screenHeight * 0.025),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(dialogContext),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.015,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Batal",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: buttonTextFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // ✅ Close dialog immediately
                      Navigator.pop(dialogContext);

                      // ✅ Smooth logout via global handler
                      LogoutHandler.performLogout(context);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.015,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Logout",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: buttonTextFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
