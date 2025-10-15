import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/mixins/auto_refresh_mixin.dart';

class DetailAbsensiPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const DetailAbsensiPage({super.key, required this.data});

  @override
  State<DetailAbsensiPage> createState() => _DetailAbsensiPageState();
}

class _DetailAbsensiPageState extends State<DetailAbsensiPage>
    with AutoRefreshMixin<DetailAbsensiPage> {
  @override
  Duration get refreshDebounce => const Duration(seconds: 30);

  @override
  Future<void> onRefresh() async {
    // Detail absensi biasanya static, tidak perlu refresh
    // Tetapi kita tetap implement untuk konsistensi
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _openGoogleMaps(
    BuildContext context,
    double lat,
    double lon,
  ) async {
    final geoUri = Uri.parse('geo:$lat,$lon?q=$lat,$lon');

    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      return;
    }

    final webUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
    );

    if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      return;
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tidak dapat membuka Google Maps'),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatTanggal(DateTime tanggal) {
    const hari = [
      "Minggu",
      "Senin",
      "Selasa",
      "Rabu",
      "Kamis",
      "Jumat",
      "Sabtu",
    ];
    const bulan = [
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember",
    ];
    return "${hari[tanggal.weekday % 7]}, ${tanggal.day} ${bulan[tanggal.month - 1]} ${tanggal.year}";
  }

  String _getShiftText() {
    final shift = widget.data["shift"] as Map<String, dynamic>?;
    if (shift == null) return "-";

    final kode = shift['kode'] ?? '';
    final waktuMulai = shift['waktu_mulai'] ?? '';
    final waktuSelesai = shift['waktu_selesai'] ?? '';

    if (waktuMulai.isNotEmpty && waktuSelesai.isNotEmpty) {
      return "$kode ($waktuMulai - $waktuSelesai)";
    }

    return kode;
  }

  List<String> _getBadgeList() {
    final badge = widget.data["badge"] as List<dynamic>?;
    if (badge == null || badge.isEmpty) return [];
    return badge.map((e) => e.toString()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.06;

    final tanggal = widget.data["tanggal"] as DateTime;
    final karyawan = widget.data["karyawan"] as Map<String, dynamic>? ?? {};
    final project = widget.data["project"] as Map<String, dynamic>? ?? {};
    final presensiMasuk =
        widget.data["presensi_masuk"] as Map<String, dynamic>?;
    final presensiPulang =
        widget.data["presensi_pulang"] as Map<String, dynamic>?;
    final badges = _getBadgeList();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 253, 253),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, screenWidth, screenHeight, padding),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => triggerRefresh(force: true),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateCard(tanggal, badges, screenWidth),
                      const SizedBox(height: 16),
                      _buildShiftCard(screenWidth),
                      const SizedBox(height: 16),
                      _buildEmployeeCard(karyawan, screenWidth),
                      const SizedBox(height: 16),
                      _buildProjectCard(project, screenWidth, context),
                      const SizedBox(height: 16),
                      Text(
                        'Detail Absensi',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAttendanceCard(
                        context,
                        title: "Absen Masuk",
                        presensi: presensiMasuk,
                        color: Colors.green,
                        icon: Icons.login,
                        screenWidth: screenWidth,
                      ),
                      const SizedBox(height: 12),
                      _buildAttendanceCard(
                        context,
                        title: "Absen Pulang",
                        presensi: presensiPulang,
                        color: Colors.orange,
                        icon: Icons.logout,
                        screenWidth: screenWidth,
                      ),
                      const SizedBox(height: 20),
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

  Widget _buildHeader(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    double padding,
  ) {
    return Container(
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
            "Detail Absensi",
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
    );
  }

  Widget _buildDateCard(
    DateTime tanggal,
    List<String> badges,
    double screenWidth,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.primary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.9))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: screenWidth * 0.07,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTanggal(tanggal),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getShiftText(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (badges.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: badges.map((badge) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildShiftCard(double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.access_time,
              color: Colors.purple.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shift Kerja',
                style: TextStyle(
                  fontSize: screenWidth * 0.032,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getShiftText(),
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> karyawan, double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Informasi Karyawan',
                style: TextStyle(
                  fontSize: screenWidth * 0.042,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow("Nama", karyawan["nama"] ?? "-", screenWidth),
          _buildInfoRow("NIK", karyawan["nik"] ?? "-", screenWidth),
          _buildInfoRow(
            "Jabatan",
            karyawan["jabatan"] != null ? karyawan["jabatan"]["nama"] : "-",
            screenWidth,
          ),
          _buildInfoRow(
            "Divisi",
            karyawan["divisi"] != null ? karyawan["divisi"]["nama"] : "-",
            screenWidth,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(
    Map<String, dynamic> project,
    double screenWidth,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.business,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Project',
                style: TextStyle(
                  fontSize: screenWidth * 0.042,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow("Nama Project", project["nama"] ?? "-", screenWidth),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Lokasi Project",
                        style: TextStyle(
                          fontSize: screenWidth * 0.034,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        project["lokasi"] != null
                            ? project["lokasi"]["nama"] ?? "-"
                            : "-",
                        style: TextStyle(
                          fontSize: screenWidth * 0.038,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                if (project["lokasi"] != null &&
                    project["lokasi"]["latitude"] != null &&
                    project["lokasi"]["longitude"] != null)
                  GestureDetector(
                    onTap: () {
                      final lat = (project["lokasi"]["latitude"] as num)
                          .toDouble();
                      final lon = (project["lokasi"]["longitude"] as num)
                          .toDouble();
                      _openGoogleMaps(context, lat, lon);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_pin,
                            color: Colors.blue.shade600,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Buka',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    double screenWidth, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: screenWidth * 0.28,
            child: Text(
              label,
              style: TextStyle(
                fontSize: screenWidth * 0.034,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: screenWidth * 0.038,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(
    BuildContext context, {
    required String title,
    required Map<String, dynamic>? presensi,
    required Color color,
    required IconData icon,
    required double screenWidth,
  }) {
    String jam = "-";
    String keterangan = "-";
    String? fotoUrl;
    double? latitude;
    double? longitude;

    if (presensi != null) {
      if (presensi["waktu"] != null) {
        final waktu = presensi["waktu"] as String;
        try {
          if (waktu.contains('T')) {
            final dateTime = DateTime.parse(waktu);
            jam =
                "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
          } else {
            final parts = waktu.split(":");
            if (parts.length >= 2) {
              jam = "${parts[0]}:${parts[1]}";
            } else {
              jam = waktu;
            }
          }
        } catch (e) {
          jam = waktu;
        }
      }

      keterangan = presensi["keterangan"] ?? "-";
      fotoUrl = presensi["foto_url"];
      latitude = presensi["latitude"] != null
          ? double.tryParse(presensi["latitude"].toString())
          : null;
      longitude = presensi["longitude"] != null
          ? double.tryParse(presensi["longitude"].toString())
          : null;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Waktu',
                      style: TextStyle(
                        fontSize: screenWidth * 0.034,
                        color: Colors.black54,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      jam,
                      style: TextStyle(
                        fontSize: screenWidth * 0.042,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  'Keterangan',
                  style: TextStyle(
                    fontSize: screenWidth * 0.034,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    keterangan,
                    style: TextStyle(
                      fontSize: screenWidth * 0.036,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (fotoUrl != null && fotoUrl.isNotEmpty)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullFotoPage(fotoUrl: fotoUrl!),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.photo,
                                  color: Colors.blue.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Lihat Foto',
                                  style: TextStyle(
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.w600,
                                    fontSize: screenWidth * 0.034,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (fotoUrl != null &&
                        fotoUrl.isNotEmpty &&
                        latitude != null &&
                        longitude != null)
                      const SizedBox(width: 12),
                    if (latitude != null && longitude != null)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _openGoogleMaps(context, latitude!, longitude!);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_pin,
                                  color: Colors.green.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Lihat Lokasi',
                                  style: TextStyle(
                                    color: Colors.green.shade600,
                                    fontWeight: FontWeight.w600,
                                    fontSize: screenWidth * 0.034,
                                  ),
                                ),
                              ],
                            ),
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
    );
  }
}

class FullFotoPage extends StatelessWidget {
  final String fotoUrl;
  const FullFotoPage({super.key, required this.fotoUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                fotoUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Gagal memuat foto',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Foto Presensi',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
