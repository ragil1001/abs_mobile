// lib/presentation/pages/home/profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../core/constants/app_colors.dart';
import '../components/shimmer_loading.dart';
import './auth/ganti_password_page.dart';

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

    // Ensure minimum loading time for smooth UX
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
    final padding = screenWidth * 0.06;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 253, 253),
      body: SafeArea(
        child: _isLoading
            ? _buildShimmerLayout(screenWidth, screenHeight, padding)
            : Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final karyawan = authProvider.currentUser;

                  if (karyawan == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Column(
                    children: [
                      // ===== MINIMAL HEADER =====
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
                              "Profile",
                              style: TextStyle(
                                fontSize: screenWidth * 0.048,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(width: screenWidth * 0.1),
                          ],
                        ),
                      ),

                      // ===== SCROLLABLE CONTENT =====
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.03),

                              // ===== PROFILE CARD =====
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: padding,
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(screenWidth * 0.05),
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
                                      // Avatar
                                      Container(
                                        width: screenWidth * 0.24,
                                        height: screenWidth * 0.24,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(
                                            0.1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.person_outline,
                                          size: screenWidth * 0.12,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.02),

                                      // Name
                                      Text(
                                        karyawan.nama,
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.058,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                          letterSpacing: 0.3,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: screenHeight * 0.005),

                                      // Position & Division
                                      Text(
                                        "${karyawan.jabatan.nama} • ${karyawan.divisi.nama}",
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.036,
                                          color: Colors.black45,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: screenHeight * 0.02),

                                      // Divider
                                      Container(
                                        height: 1,
                                        color: const Color(0xFFF0F0F0),
                                      ),
                                      SizedBox(height: screenHeight * 0.025),

                                      // Info Items
                                      _buildInfoItem(
                                        "NIK",
                                        karyawan.nik,
                                        screenWidth,
                                      ),
                                      _buildInfoItem(
                                        "Divisi",
                                        karyawan.divisi.nama,
                                        screenWidth,
                                      ),
                                      _buildInfoItem(
                                        "Jabatan",
                                        karyawan.jabatan.nama,
                                        screenWidth,
                                      ),
                                      _buildInfoItem(
                                        "Project",
                                        karyawan.project?.nama ??
                                            "Belum ada project",
                                        screenWidth,
                                      ),
                                      _buildInfoItem(
                                        "No Telepon",
                                        karyawan.noTelepon,
                                        screenWidth,
                                      ),
                                      _buildInfoItem(
                                        "Jenis Kelamin",
                                        karyawan.jenisKelaminText,
                                        screenWidth,
                                      ),
                                      _buildInfoItem(
                                        "Tanggal Lahir",
                                        karyawan.formattedTanggalLahir,
                                        screenWidth,
                                      ),
                                      _buildInfoItem(
                                        "Tanggal Bergabung",
                                        karyawan.formattedTanggalBergabung,
                                        screenWidth,
                                      ),
                                      _buildInfoItem(
                                        "Username",
                                        karyawan.username,
                                        screenWidth,
                                        isLast: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.025),

                              // ===== ACTION BUTTONS =====
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
                                    SizedBox(height: screenHeight * 0.015),
                                    _buildActionButton(
                                      "Logout",
                                      Icons.logout,
                                      screenWidth,
                                      screenHeight,
                                      () => _showLogoutDialog(context),
                                      isLogout: true,
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.04),
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
  ) {
    return Column(
      children: [
        // Header
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
                  width: screenWidth * 0.1,
                  height: screenWidth * 0.1,
                  borderRadius: 12,
                ),
              ),
              const Spacer(),
              ShimmerLoading(
                child: ShimmerBox(
                  width: screenWidth * 0.3,
                  height: 20,
                  borderRadius: 4,
                ),
              ),
              const Spacer(),
              SizedBox(width: screenWidth * 0.1),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.03),
                // Profile card shimmer
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: ShimmerLoading(
                    child: Container(
                      padding: EdgeInsets.all(screenWidth * 0.05),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          // Avatar
                          ShimmerBox(
                            width: screenWidth * 0.24,
                            height: screenWidth * 0.24,
                            borderRadius: screenWidth * 0.12,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          // Name
                          ShimmerBox(
                            width: screenWidth * 0.5,
                            height: 20,
                            borderRadius: 4,
                          ),
                          const SizedBox(height: 8),
                          // Position
                          ShimmerBox(
                            width: screenWidth * 0.4,
                            height: 16,
                            borderRadius: 4,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Container(height: 1, color: const Color(0xFFF0F0F0)),
                          SizedBox(height: screenHeight * 0.025),
                          // Info items
                          ...List.generate(
                            9,
                            (index) => Padding(
                              padding: EdgeInsets.only(
                                bottom: screenWidth * 0.04,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ShimmerBox(
                                    width: screenWidth * 0.3,
                                    height: 14,
                                    borderRadius: 4,
                                  ),
                                  ShimmerBox(
                                    width: screenWidth * 0.35,
                                    height: 14,
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
                SizedBox(height: screenHeight * 0.025),
                // Action buttons shimmer
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: ShimmerLoading(
                    child: Column(
                      children: [
                        ShimmerBox(
                          width: double.infinity,
                          height: 60,
                          borderRadius: 16,
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        ShimmerBox(
                          width: double.infinity,
                          height: 60,
                          borderRadius: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
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
    double screenWidth, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : screenWidth * 0.04),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: screenWidth * 0.35,
            child: Text(
              label,
              style: TextStyle(
                fontSize: screenWidth * 0.036,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: screenWidth * 0.036,
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
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.02,
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
              width: screenWidth * 0.11,
              height: screenWidth * 0.11,
              decoration: BoxDecoration(
                color: isLogout
                    ? AppColors.error.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: screenWidth * 0.055,
                color: isLogout ? AppColors.error : AppColors.primary,
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: screenWidth * 0.04,
              color: Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool isLoading = false;

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: EdgeInsets.all(screenWidth * 0.06),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: screenWidth * 0.15,
                  height: screenWidth * 0.15,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout,
                    color: AppColors.error,
                    size: screenWidth * 0.08,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  "Logout",
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  "Apakah Anda yakin ingin keluar?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.036,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),

                if (isLoading)
                  Column(
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.error,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Text(
                        'Sedang logout...',
                        style: TextStyle(
                          fontSize: screenWidth * 0.032,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
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
                                fontSize: screenWidth * 0.038,
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
                          onTap: () async {
                            setState(() {
                              isLoading = true;
                            });

                            final authProvider = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );

                            try {
                              await authProvider.logout();

                              if (context.mounted) {
                                final notifProvider =
                                    Provider.of<NotificationProvider>(
                                      context,
                                      listen: false,
                                    );
                                notifProvider.clear();
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                              }

                              if (context.mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/login',
                                  (route) => false,
                                );
                              }
                            } catch (e) {
                              setState(() {
                                isLoading = false;
                              });

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Logout berhasil (offline mode)',
                                    ),
                                    backgroundColor: AppColors.success,
                                  ),
                                );

                                Navigator.pop(context);
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/login',
                                  (route) => false,
                                );
                              }
                            }
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
                                fontSize: screenWidth * 0.038,
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
          );
        },
      ),
    );
  }
}
