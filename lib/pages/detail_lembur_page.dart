// lib/pages/detail_lembur_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/lembur_provider.dart';
import '../providers/auth_provider.dart';
import '../data/models/pengajuan_lembur_model.dart';
import '../core/constants/app_colors.dart';
import '../components/custom_snackbar.dart';

class DetailLemburPage extends StatefulWidget {
  final int lemburId;

  const DetailLemburPage({super.key, required this.lemburId});

  @override
  State<DetailLemburPage> createState() => _DetailLemburPageState();
}

class _DetailLemburPageState extends State<DetailLemburPage> {
  PengajuanLembur? _lembur;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final lemburProvider = Provider.of<LemburProvider>(context, listen: false);
    final lembur = await lemburProvider.getDetail(widget.lemburId);

    setState(() {
      _lembur = lembur;
      _isLoading = false;
      if (lembur == null) {
        _errorMessage = lemburProvider.errorMessage ?? 'Gagal memuat detail';
      }
    });
  }

  Future<void> _openFile() async {
    if (_lembur?.fileSklUrl == null) {
      CustomSnackbar.showError(context, 'File tidak tersedia');
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      final downloadUrl =
          _lembur!.getDownloadUrl(token) ?? _lembur!.fileSklUrl!;

      print('Opening file: $downloadUrl');

      final uri = Uri.parse(downloadUrl);

      bool launched = false;

      try {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        print('platformDefault failed: $e');
      }

      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          print('externalApplication failed: $e');
        }
      }

      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
        } catch (e) {
          print('inAppWebView failed: $e');
        }
      }

      if (!launched) {
        throw Exception('Tidak dapat membuka file');
      }
    } catch (e) {
      print('Error opening file: $e');
      if (!mounted) return;

      CustomSnackbar.showError(context, 'Gagal membuka file: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
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
        child: Column(
          children: [
            _buildHeader(context, screenWidth, screenHeight, padding),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                  : _lembur == null
                  ? Center(
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
                            onPressed: _loadDetail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDetail,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildStatusBadge(),
                          const SizedBox(height: 20),
                          _buildInfoCard(),
                          const SizedBox(height: 16),
                          if (_lembur!.jamMulai != null &&
                              _lembur!.jamSelesai != null) ...[
                            _buildJamKerjaCard(),
                            const SizedBox(height: 16),
                          ],
                          if (_lembur!.fileSklUrl != null) ...[
                            _buildFileLampiran(),
                            const SizedBox(height: 16),
                          ],
                          // ✅ NEW: Keterangan Karyawan
                          if (_lembur!.keteranganKaryawan != null &&
                              _lembur!.keteranganKaryawan!.isNotEmpty) ...[
                            _buildKeteranganCard(),
                            const SizedBox(height: 16),
                          ],
                          if (_lembur!.catatanAdmin != null) ...[
                            _buildAdminResponse(),
                            const SizedBox(height: 16),
                          ],
                          _buildTimeline(),
                        ],
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
            "Detail Lembur",
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

  Widget _buildStatusBadge() {
    Color statusColor;
    IconData statusIcon;

    switch (_lembur!.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'disetujui':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'ditolak':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
      case 'dibatalkan':
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lembur!.statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                if (_lembur!.diprosesPada != null)
                  Text(
                    DateFormat(
                      'dd MMMM yyyy, HH:mm',
                      'id_ID',
                    ).format(_lembur!.diprosesPada!),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildInfoRow(
                    'Jenis Pengajuan',
                    'Lembur',
                    Icons.access_time,
                    isHighlight: true,
                    customColor: Colors.deepPurple,
                  ),
                ),
                const SizedBox(width: 8),
                // ✅ NEW: Badge Kode Hari
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _lembur!.isHariLibur
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _lembur!.isHariLibur ? Colors.orange : Colors.blue,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _lembur!.isHariLibur
                            ? Icons.weekend
                            : Icons.work_outline,
                        size: 14,
                        color: _lembur!.isHariLibur
                            ? Colors.orange
                            : Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _lembur!.kodeHariText,
                        style: TextStyle(
                          color: _lembur!.isHariLibur
                              ? Colors.orange
                              : Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),
            _buildInfoRow(
              'Tanggal Lembur',
              DateFormat(
                'EEEE, dd MMMM yyyy',
                'id_ID',
              ).format(_lembur!.tanggal),
              Icons.calendar_today,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ UPDATED: Tampilkan jam kerja untuk SEMUA pengajuan (hari kerja & libur)
  Widget _buildJamKerjaCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _lembur!.isHariLibur
                        ? Colors.orange.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.schedule,
                    color: _lembur!.isHariLibur
                        ? Colors.orange
                        : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Jam Kerja Lembur',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _lembur!.isHariLibur
                          ? Colors.orange.withOpacity(0.05)
                          : AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _lembur!.isHariLibur
                            ? Colors.orange.withOpacity(0.3)
                            : AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: _lembur!.isHariLibur
                                  ? Colors.orange
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Jam Mulai',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _lembur!.jamMulai ?? '-',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _lembur!.isHariLibur
                          ? Colors.orange.withOpacity(0.05)
                          : AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _lembur!.isHariLibur
                            ? Colors.orange.withOpacity(0.3)
                            : AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_filled,
                              size: 16,
                              color: _lembur!.isHariLibur
                                  ? Colors.orange
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Jam Selesai',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _lembur!.jamSelesai ?? '-',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _lembur!.isHariLibur
                    ? Colors.orange.withOpacity(0.05)
                    : AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _lembur!.isHariLibur
                      ? Colors.orange.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _lembur!.isHariLibur
                        ? Colors.orange
                        : AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lembur!.isHariLibur
                          ? 'Lembur di hari libur dengan jam kerja yang ditentukan'
                          : 'Lembur di hari kerja dengan jam kerja yang ditentukan',
                      style: TextStyle(
                        fontSize: 12,
                        color: _lembur!.isHariLibur
                            ? Colors.orange.shade800
                            : AppColors.primary.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Card untuk Keterangan Karyawan
  Widget _buildKeteranganCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notes,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Keterangan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              _lembur!.keteranganKaryawan!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    bool isHighlight = false,
    Color? customColor,
  }) {
    final displayColor =
        customColor ?? (isHighlight ? AppColors.primary : Colors.grey.shade600);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: displayColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                  color: isHighlight ? displayColor : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileLampiran() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: InkWell(
        onTap: _isDownloading ? null : _openFile,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.picture_as_pdf,
                  color: AppColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Surat Keterangan Lembur (SKL)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isDownloading
                          ? 'Membuka file...'
                          : 'Tap untuk membuka file',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isDownloading ? AppColors.primary : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isDownloading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                )
              else
                const Icon(Icons.open_in_new, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminResponse() {
    return Card(
      elevation: 0,
      color: _lembur!.status == 'disetujui'
          ? AppColors.success.withOpacity(0.05)
          : AppColors.error.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _lembur!.status == 'disetujui'
                      ? Icons.check_circle
                      : Icons.cancel,
                  size: 20,
                  color: _lembur!.status == 'disetujui'
                      ? AppColors.success
                      : AppColors.error,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Catatan Admin',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _lembur!.catatanAdmin!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            if (_lembur!.diprosesOleh != null) ...[
              const SizedBox(height: 12),
              Text(
                'Diproses oleh: ${_lembur!.diprosesOleh}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timeline, size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Timeline',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTimelineItem(
              'Pengajuan Dibuat',
              DateFormat(
                'dd MMMM yyyy, HH:mm',
                'id_ID',
              ).format(_lembur!.createdAt),
              Icons.send,
              AppColors.primary,
              isFirst: true,
            ),
            if (_lembur!.diprosesPada != null)
              _buildTimelineItem(
                _lembur!.status == 'disetujui'
                    ? 'Disetujui'
                    : _lembur!.status == 'ditolak'
                    ? 'Ditolak'
                    : 'Dibatalkan',
                DateFormat(
                  'dd MMMM yyyy, HH:mm',
                  'id_ID',
                ).format(_lembur!.diprosesPada!),
                _lembur!.status == 'disetujui'
                    ? Icons.check_circle
                    : Icons.cancel,
                _lembur!.status == 'disetujui'
                    ? AppColors.success
                    : AppColors.error,
                isLast: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String time,
    IconData icon,
    Color color, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(width: 2, height: 16, color: Colors.grey.shade300),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            if (!isLast)
              Container(width: 2, height: 16, color: Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
