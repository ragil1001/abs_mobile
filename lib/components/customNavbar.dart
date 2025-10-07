import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/presensi_provider.dart';
import '../data/services/api_service.dart';
import '../data/services/fake_gps_detector_service.dart';
import '../core/config/app_config.dart';

class CustomBottomNavBar extends StatefulWidget {
  final double circleRadius;
  final int currentIndex;
  final Function(int)? onTabSelected;

  const CustomBottomNavBar({
    super.key,
    this.circleRadius = 40,
    this.currentIndex = 0,
    this.onTabSelected,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _fakeGpsDetector = FakeGpsDetectorService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePresensiTap() async {
    // STEP 1: Cek developer mode terlebih dahulu (PRIORITY TERTINGGI)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Memeriksa keamanan perangkat...'),
              ],
            ),
          ),
        ),
      ),
    );

    final isDeveloperMode = await _fakeGpsDetector.quickDeveloperModeCheck();

    if (mounted) Navigator.pop(context);

    if (isDeveloperMode) {
      _showSecurityBlockDialog(
        title: 'Opsi Developer Terdeteksi',
        message:
            'Untuk keamanan presensi, aplikasi tidak dapat digunakan saat Opsi Developer aktif.\n\n'
            'Cara menonaktifkan:\n'
            '1. Buka Pengaturan\n'
            '2. Pilih Sistem\n'
            '3. Pilih Opsi Pengembang\n'
            '4. Matikan "Opsi Pengembang"',
        icon: Icons.security,
        iconColor: Colors.red,
      );
      return;
    }

    // STEP 2: Lanjutkan cek akses presensi normal
    _checkPresensiAccess();
  }

  Future<void> _checkPresensiAccess() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Memeriksa akses presensi...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw ApiException('Token tidak ditemukan');
      }

      final apiService = ApiService();
      final response = await apiService.get(
        '${AppConfig.mobileApiPrefix}/presensi/cek',
      );

      if (mounted) Navigator.pop(context);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];

        final bisaMasuk = data['bisa_presensi_masuk'] ?? false;
        final bisaPulang = data['bisa_presensi_pulang'] ?? false;
        final sudahMasuk = data['sudah_presensi_masuk'] ?? false;
        final sudahPulang = data['sudah_presensi_pulang'] ?? false;

        // Cek status alpa
        final presensiProvider = Provider.of<PresensiProvider>(
          context,
          listen: false,
        );
        final presensiData = presensiProvider.presensiData;
        final isAlpaToday = presensiData?.presensiHariIni?.isAlpa ?? false;

        if (isAlpaToday) {
          _showAccessDeniedDialog(
            title: 'Status Alpa',
            message:
                'Anda tercatat tidak melakukan presensi hari ini dan statusnya adalah Alpa. Silakan hubungi admin jika ada kesalahan.',
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.red,
          );
          return;
        }

        if (sudahMasuk && sudahPulang) {
          _showAccessDeniedDialog(
            title: 'Presensi Selesai',
            message: 'Anda sudah melakukan presensi masuk dan pulang hari ini.',
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
          );
          return;
        }

        if (!sudahMasuk && !bisaMasuk) {
          _showAccessDeniedDialog(
            title: 'Belum Waktunya Presensi',
            message:
                'Waktu presensi masuk belum dibuka. Silakan coba lagi saat waktu shift Anda.',
            icon: Icons.schedule,
            iconColor: Colors.orange,
          );
          return;
        }

        if (mounted) {
          Navigator.pushNamed(context, '/absensi');
        }
      } else {
        throw ApiException(response['message'] ?? 'Gagal mengecek presensi');
      }
    } on ApiException catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      String message = e.message;
      IconData icon = Icons.info_outline;
      Color iconColor = Colors.orange;

      if (e.message.contains('Tidak ada jadwal')) {
        message = 'Tidak ada jadwal kerja untuk hari ini.';
        icon = Icons.event_busy;
      } else if (e.message.contains('hari libur')) {
        message = 'Hari ini adalah hari libur Anda.';
        icon = Icons.beach_access;
        iconColor = Colors.blue;
      } else if (e.message.contains('belum terdaftar')) {
        message = 'Anda belum terdaftar di project manapun. Hubungi admin.';
        icon = Icons.person_off;
        iconColor = Colors.red;
      }

      _showAccessDeniedDialog(
        title: 'Tidak Dapat Presensi',
        message: message,
        icon: icon,
        iconColor: iconColor,
      );
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      _showAccessDeniedDialog(
        title: 'Terjadi Kesalahan',
        message: 'Gagal memeriksa akses presensi. Silakan coba lagi.',
        icon: Icons.error_outline,
        iconColor: Colors.red,
      );
    }
  }

  void _showSecurityBlockDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(icon, size: 64, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showAccessDeniedDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(icon, size: 64, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double centerButtonSize = widget.circleRadius * 1.4;

    return SizedBox(
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 90),
            painter: NavbarPainter(circleRadius: widget.circleRadius + 10),
          ),
          Positioned(
            top: -centerButtonSize / 1.8,
            left: MediaQuery.of(context).size.width / 2 - centerButtonSize / 2,
            child: GestureDetector(
              onTap: _handlePresensiTap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9800).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final double barHeight = centerButtonSize * 0.07;
                        final double top =
                            centerButtonSize -
                            (centerButtonSize + barHeight) * _controller.value;

                        return Container(
                          width: centerButtonSize,
                          height: centerButtonSize,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFFC107),
                                Color(0xFFFF9800),
                                Color(0xFFF44336),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: ClipOval(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 4,
                                    sigmaY: 4,
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: top,
                                  child: Opacity(
                                    opacity: 0.95,
                                    child: Container(
                                      height: barHeight,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Colors.white.withOpacity(0.0),
                                            Colors.white.withOpacity(0.85),
                                            Colors.white.withOpacity(0.0),
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Icon(
                                    Icons.fingerprint,
                                    color: Colors.white,
                                    size: widget.circleRadius * 0.9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "PRESENSI",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedHome01,
                    color: widget.currentIndex == 0
                        ? const Color(0xFFFF9800)
                        : Colors.black87,
                    size: 25,
                  ),
                  label: "BERANDA",
                  isActive: widget.currentIndex == 0,
                  onTap: () => widget.onTabSelected?.call(0),
                ),
                const SizedBox(width: 60),
                _NavItem(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedGoogleDoc,
                    color: widget.currentIndex == 1
                        ? const Color(0xFFFF9800)
                        : Colors.black87,
                    size: 25,
                  ),
                  label: "RIWAYAT",
                  isActive: widget.currentIndex == 1,
                  onTap: () => widget.onTabSelected?.call(1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 110,
        height: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 28, child: Center(child: icon)),
            const SizedBox(height: 4),
            SizedBox(
              height: 22,
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    fontSize: isActive ? 15 : 13,
                    fontWeight: FontWeight.w700,
                    color: isActive ? const Color(0xFFFF9800) : Colors.black87,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
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

class NavbarPainter extends CustomPainter {
  final double circleRadius;

  NavbarPainter({required this.circleRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final cornerRadius = 40.0;
    final notchDepth = 38.0;

    final path = Path();

    path.moveTo(0, size.height);
    path.lineTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    path.lineTo(centerX - circleRadius - 20, 0);
    path.quadraticBezierTo(
      centerX - circleRadius,
      0,
      centerX - circleRadius + 10,
      notchDepth * 0.3,
    );
    path.cubicTo(
      centerX - circleRadius * 0.5,
      notchDepth * 0.8,
      centerX - circleRadius * 0.3,
      notchDepth,
      centerX,
      notchDepth,
    );
    path.cubicTo(
      centerX + circleRadius * 0.3,
      notchDepth,
      centerX + circleRadius * 0.5,
      notchDepth * 0.8,
      centerX + circleRadius - 10,
      notchDepth * 0.3,
    );
    path.quadraticBezierTo(
      centerX + circleRadius,
      0,
      centerX + circleRadius + 20,
      0,
    );
    path.lineTo(size.width - cornerRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);
    path.lineTo(size.width, size.height);
    path.close();

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.save();
    canvas.translate(0, -4);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Colors.grey.shade50],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);

    final innerShadowPath = Path();
    innerShadowPath.moveTo(centerX - circleRadius + 10, notchDepth * 0.3);
    innerShadowPath.cubicTo(
      centerX - circleRadius * 0.5,
      notchDepth * 0.8,
      centerX - circleRadius * 0.3,
      notchDepth,
      centerX,
      notchDepth,
    );
    innerShadowPath.cubicTo(
      centerX + circleRadius * 0.3,
      notchDepth,
      centerX + circleRadius * 0.5,
      notchDepth * 0.8,
      centerX + circleRadius - 10,
      notchDepth * 0.3,
    );

    final innerShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawPath(innerShadowPath, innerShadowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
