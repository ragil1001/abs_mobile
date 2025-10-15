import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../data/services/api_service.dart';
import '../core/config/app_config.dart';
import '../components/shimmer_loading.dart';
import 'detail_absensi_page.dart';

class HistoryAbsensiPage extends StatefulWidget {
  const HistoryAbsensiPage({super.key});

  @override
  State<HistoryAbsensiPage> createState() => _HistoryAbsensiPageState();
}

class _HistoryAbsensiPageState extends State<HistoryAbsensiPage> {
  String _filter = "Semua";
  DateTimeRange? _customRange;
  List<Map<String, dynamic>> _absensi = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistoryAbsensi();
    });
  }

  bool get _shouldRefresh {
    if (_lastRefreshTime == null) return true;
    return DateTime.now().difference(_lastRefreshTime!).inSeconds > 30;
  }

  Future<void> _loadHistoryAbsensi() async {
    if (!_shouldRefresh && _absensi.isNotEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _lastRefreshTime = DateTime.now();

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      // Tentukan range tanggal berdasarkan filter
      DateTime startDate;
      DateTime endDate = DateTime.now();

      switch (_filter) {
        case "Bulan Ini":
          startDate = DateTime(endDate.year, endDate.month, 1);
          break;
        case "Bulan Lalu":
          final lastMonth = DateTime(endDate.year, endDate.month - 1, 1);
          startDate = lastMonth;
          endDate = DateTime(endDate.year, endDate.month, 0);
          break;
        case "Custom":
          if (_customRange != null) {
            startDate = _customRange!.start;
            endDate = _customRange!.end;
          } else {
            startDate = endDate.subtract(const Duration(days: 30));
          }
          break;
        default: // "Semua"
          startDate = endDate.subtract(const Duration(days: 90));
      }

      final response = await ApiService().get(
        '${AppConfig.mobileApiPrefix}/presensi/history?start_date=${_formatDate(startDate)}&end_date=${_formatDate(endDate)}',
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];

        setState(() {
          _absensi = data.where((item) => item['presensi_masuk'] != null).map((
            item,
          ) {
            final presensiMasuk =
                item['presensi_masuk'] as Map<String, dynamic>;
            final presensiPulang =
                item['presensi_pulang'] as Map<String, dynamic>?;

            final status = presensiMasuk['status'] as String;

            return {
              "id": item['id'],
              "tanggal": DateTime.parse(item['tanggal']),
              "hari": item['hari'],
              "status": status,
              "status_display": _getStatusDisplay(status),
              "masuk": _parseWaktu(presensiMasuk['waktu']),
              "pulang": presensiPulang != null
                  ? _parseWaktu(presensiPulang['waktu'])
                  : '-',
              "badge": _getBadgeList(presensiMasuk, presensiPulang),
              "shift": item['shift'] ?? {},
              "karyawan": item['karyawan'] ?? {},
              "project": item['project'] ?? {},
              "presensi_masuk": presensiMasuk,
              "presensi_pulang": presensiPulang,
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Gagal memuat data');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _getStatusDisplay(String status) {
    switch (status) {
      case "hadir":
      case "terlambat":
        return "Reguler";
      case "alpa":
        return "Alpa";
      case "izin":
        return "Izin";
      case "libur":
        return "Libur";
      default:
        return status;
    }
  }

  String _parseWaktu(String? waktu) {
    if (waktu == null || waktu == '-') return '-';

    try {
      if (waktu.contains('T')) {
        final dateTime = DateTime.parse(waktu);
        return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
      }

      final parts = waktu.split(':');
      if (parts.length >= 2) {
        return "${parts[0]}:${parts[1]}";
      }

      return waktu;
    } catch (e) {
      return waktu;
    }
  }

  List<String> _getBadgeList(
    Map<String, dynamic>? presensiMasuk,
    Map<String, dynamic>? presensiPulang,
  ) {
    List<String> badges = [];

    if (presensiMasuk != null) {
      final statusMasuk = presensiMasuk['status'] as String?;
      if (statusMasuk == 'terlambat') {
        badges.add('T');
      }
    }

    if (presensiPulang != null) {
      final statusPulang = presensiPulang['status'] as String?;
      if (statusPulang == 'lembur' || statusPulang == 'lembur_pending') {
        badges.add('LB');
      } else if (statusPulang == 'pulang_cepat') {
        badges.add('PC');
      } else if (statusPulang == 'tidak_presensi_pulang') {
        badges.add('TPP');
      }
    }

    return badges;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "hadir":
      case "terlambat":
        return Colors.orange;
      case "alpa":
        return Colors.red;
      case "izin":
        return Colors.blue;
      case "libur":
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  bool _isRegularStatus(String status) {
    return status == "hadir" || status == "terlambat";
  }

  Future<void> _showFilterDialog() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Filter Tanggal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.all_inclusive, color: Colors.orange),
              title: const Text("Semua"),
              trailing: _filter == "Semua"
                  ? const Icon(Icons.check, color: Colors.orange)
                  : null,
              onTap: () {
                setState(() {
                  _filter = "Semua";
                  _customRange = null;
                });
                Navigator.pop(context);
                _loadHistoryAbsensi();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.orange),
              title: const Text("Bulan Ini"),
              trailing: _filter == "Bulan Ini"
                  ? const Icon(Icons.check, color: Colors.orange)
                  : null,
              onTap: () {
                setState(() {
                  _filter = "Bulan Ini";
                  _customRange = null;
                });
                Navigator.pop(context);
                _loadHistoryAbsensi();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.orange),
              title: const Text("Bulan Lalu"),
              trailing: _filter == "Bulan Lalu"
                  ? const Icon(Icons.check, color: Colors.orange)
                  : null,
              onTap: () {
                setState(() {
                  _filter = "Bulan Lalu";
                  _customRange = null;
                });
                Navigator.pop(context);
                _loadHistoryAbsensi();
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range, color: Colors.orange),
              title: const Text("Pilih Tanggal Sendiri"),
              trailing: _filter == "Custom"
                  ? const Icon(Icons.check, color: Colors.orange)
                  : null,
              onTap: () async {
                Navigator.pop(context);
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: _customRange,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Colors.orange,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (range != null) {
                  setState(() {
                    _filter = "Custom";
                    _customRange = range;
                  });
                  _loadHistoryAbsensi();
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
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
            // Header
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
                        color: Colors.orange.withOpacity(0.2),
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
                    "History Absensi",
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

            // Content
            Expanded(
              child: _isLoading
                  ? _buildShimmerLayout(screenWidth, screenHeight, padding)
                  : _errorMessage != null
                  ? _buildErrorState(screenWidth, padding)
                  : _absensi.isEmpty
                  ? const Center(child: Text("Tidak ada data absensi"))
                  : RefreshIndicator(
                      onRefresh: () async {
                        _lastRefreshTime = null;
                        await _loadHistoryAbsensi();
                      },
                      child: ListView.builder(
                        padding: EdgeInsets.all(padding),
                        itemCount: _absensi.length,
                        itemBuilder: (context, index) {
                          final data = _absensi[index];
                          return _buildHistoryCard(
                            data,
                            screenWidth,
                            screenHeight,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFilterDialog,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        label: const Text(
          "Filter Tanggal",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.filter_alt),
      ),
    );
  }

  Widget _buildShimmerLayout(
    double screenWidth,
    double screenHeight,
    double padding,
  ) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: EdgeInsets.all(padding),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            height: screenHeight * 0.11,
            child: Row(
              children: [
                ShimmerBox(width: 6, height: double.infinity, borderRadius: 0),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShimmerBox(width: 40, height: 12, borderRadius: 4),
                    const SizedBox(height: 4),
                    ShimmerBox(width: 40, height: 18, borderRadius: 4),
                  ],
                ),
                const SizedBox(width: 16),
                ShimmerBox(width: 2, height: double.infinity, borderRadius: 0),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                        width: screenWidth * 0.3,
                        height: 16,
                        borderRadius: 4,
                      ),
                      const SizedBox(height: 8),
                      ShimmerBox(
                        width: screenWidth * 0.25,
                        height: 14,
                        borderRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShimmerBox(width: 60, height: 14, borderRadius: 4),
                    const SizedBox(height: 4),
                    ShimmerBox(width: 60, height: 20, borderRadius: 4),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(double screenWidth, double padding) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _lastRefreshTime = null;
                _loadHistoryAbsensi();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    Map<String, dynamic> data,
    double screenWidth,
    double screenHeight,
  ) {
    final tanggal = data["tanggal"] as DateTime;
    final status = data["status"] as String;
    final statusColor = _getStatusColor(status);
    final isRegular = _isRegularStatus(status);

    return GestureDetector(
      onTap: isRegular
          ? () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailAbsensiPage(data: data),
                ),
              );
              // Refresh after returning
              if (mounted && _shouldRefresh) {
                _loadHistoryAbsensi();
              }
            }
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SizedBox(
          height: screenHeight * 0.11,
          child: Row(
            children: [
              // Status color indicator
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),

              // Tanggal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _bulanShort(tanggal.month),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      "${tanggal.day}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Container(width: 2, color: const Color(0xFFF0F0F0)),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            data["hari"],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          ...(data["badge"] as List).map<Widget>(
                            (b) => Container(
                              margin: const EdgeInsets.only(right: 3),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                b.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data["status_display"],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Waktu masuk/pulang - HANYA untuk status reguler
              if (isRegular) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Masuk",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            data["masuk"],
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Container(width: 2, color: const Color(0xFFF0F0F0)),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Pulang",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            data["pulang"],
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _bulanShort(int month) {
    const bulan = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Agu",
      "Sep",
      "Okt",
      "Nov",
      "Des",
    ];
    return bulan[month - 1];
  }
}
