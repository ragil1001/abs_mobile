import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailAbsensiPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailAbsensiPage({super.key, required this.data});

  Future<void> _openGoogleMaps(
    BuildContext context,
    double lat,
    double lon,
  ) async {
    // Try opening Google Maps app first with geo URI
    final geoUri = Uri.parse('geo:$lat,$lon?q=$lat,$lon');

    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      return;
    }

    // Fallback to web URL
    final webUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
    );

    if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      return;
    }

    // If both fail, show error message
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
    final shift = data["shift"] as Map<String, dynamic>?;
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
    final badge = data["badge"] as List<dynamic>?;
    if (badge == null || badge.isEmpty) return [];
    return badge.map((e) => e.toString()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tanggal = data["tanggal"] as DateTime;
    final karyawan = data["karyawan"] as Map<String, dynamic>? ?? {};
    final project = data["project"] as Map<String, dynamic>? ?? {};
    final presensiMasuk = data["presensi_masuk"] as Map<String, dynamic>?;
    final presensiPulang = data["presensi_pulang"] as Map<String, dynamic>?;
    final badges = _getBadgeList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Data Absensi"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tanggal dan badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 24),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTanggal(tanggal),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getShiftText(),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
              if (badges.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: badges.map((badge) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Informasi Karyawan
          _infoRow("Nama Karyawan", karyawan["nama"] ?? "-"),
          _infoRow("Nomor Induk Karyawan (NIK)", karyawan["nik"] ?? "-"),
          _infoRow(
            "Jabatan",
            karyawan["jabatan"] != null ? karyawan["jabatan"]["nama"] : "-",
          ),
          _infoRow(
            "Divisi",
            karyawan["divisi"] != null ? karyawan["divisi"]["nama"] : "-",
          ),
          _infoRow("Project", project["nama"] ?? "-"),

          // Lokasi Project dengan link ke Google Maps
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Lokasi Project",
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project["lokasi"] != null
                            ? project["lokasi"]["nama"] ?? "-"
                            : "-",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (project["lokasi"] != null &&
                        project["lokasi"]["latitude"] != null &&
                        project["lokasi"]["longitude"] != null)
                      IconButton(
                        icon: const Icon(
                          Icons.location_pin,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          final lat = (project["lokasi"]["latitude"] as num)
                              .toDouble();
                          final lon = (project["lokasi"]["longitude"] as num)
                              .toDouble();
                          _openGoogleMaps(context, lat, lon);
                        },
                        tooltip: "Buka di Google Maps",
                      ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 32, thickness: 1),

          const Text(
            "Absensi",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Card Masuk
          _absensiCard(
            context,
            title: "Masuk",
            presensi: presensiMasuk,
            color: Colors.green,
          ),

          const SizedBox(height: 12),

          // Card Pulang
          _absensiCard(
            context,
            title: "Pulang",
            presensi: presensiPulang,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _absensiCard(
    BuildContext context, {
    required String title,
    required Map<String, dynamic>? presensi,
    required Color color,
  }) {
    String jam = "-";
    String keterangan = "-";
    String? fotoUrl;
    double? latitude;
    double? longitude;

    if (presensi != null) {
      // Format jam (HH:mm tanpa detik)
      if (presensi["waktu"] != null) {
        final waktu = presensi["waktu"] as String;

        try {
          // Jika format ISO 8601 (2025-10-02T06:40:02.0000 atau 2025-10-02T06:40)
          if (waktu.contains('T')) {
            final dateTime = DateTime.parse(waktu);
            jam =
                "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
          } else {
            // Jika sudah format HH:mm:ss atau HH:mm
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

      // Debug print
      if (fotoUrl != null) {
        print('=== FOTO URL DEBUG ===');
        print('Title: $title');
        print('URL: $fotoUrl');
        print('URL Type: ${fotoUrl.runtimeType}');
        print('Is Empty: ${fotoUrl.isEmpty}');
      }

      latitude = presensi["latitude"] != null
          ? double.tryParse(presensi["latitude"].toString())
          : null;
      longitude = presensi["longitude"] != null
          ? double.tryParse(presensi["longitude"].toString())
          : null;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // konten kiri (judul, jam, keterangan)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
              Text(
                jam,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              const Text("Keterangan", style: TextStyle(color: Colors.black54)),
              Text(keterangan),
            ],
          ),

          // foto & lokasi di pojok kanan atas
          Positioned(
            right: 0,
            top: 0,
            child: Row(
              children: [
                if (fotoUrl != null && fotoUrl.isNotEmpty)
                  Builder(
                    builder: (context) {
                      final url = fotoUrl; // Create local final variable
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullFotoPage(fotoUrl: url!),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[300],
                          child: ClipOval(
                            child: Image.network(
                              url!,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.person, size: 20);
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const SizedBox(
                                      width: 36,
                                      height: 36,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(width: 8),
                if (latitude != null && longitude != null)
                  IconButton(
                    icon: const Icon(Icons.location_pin, color: Colors.red),
                    onPressed: () {
                      _openGoogleMaps(context, latitude!, longitude!);
                    },
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
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
