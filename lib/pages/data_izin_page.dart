// lib/pages/data_izin_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/izin_provider.dart';
import '../core/constants/app_colors.dart';
import '../data/models/pengajuan_izin_model.dart';
import '../components/custom_snackbar.dart';
import 'detail_izin_page.dart';

class DataIzinPage extends StatefulWidget {
  const DataIzinPage({super.key});

  @override
  State<DataIzinPage> createState() => _DataIzinPageState();
}

class _DataIzinPageState extends State<DataIzinPage> {
  String _filter = "Semua";
  DateTimeRange? _customRange;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  bool get _shouldRefresh {
    if (_lastRefreshTime == null) return true;
    return DateTime.now().difference(_lastRefreshTime!).inSeconds > 30;
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    _lastRefreshTime = DateTime.now();

    final izinProvider = Provider.of<IzinProvider>(context, listen: false);
    await izinProvider.loadPengajuan();
  }

  // When navigating to detail, refresh on return
  void _navigateToDetail(int izinId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailIzinPage(izinId: izinId)),
    );

    // Refresh after returning
    if (mounted && _shouldRefresh) {
      _lastRefreshTime = null;
      _loadData();
    }
  }

  List<PengajuanIzin> _getFilteredIzin(List<PengajuanIzin> disetujuiList) {
    final now = DateTime.now();

    if (_filter == "Semua") return disetujuiList;

    if (_filter == "Bulan Ini") {
      return disetujuiList.where((izin) {
        return izin.tanggalMulai.month == now.month &&
            izin.tanggalMulai.year == now.year;
      }).toList();
    }

    if (_filter == "Bulan Lalu") {
      final lastMonth = DateTime(now.year, now.month - 1);
      return disetujuiList.where((izin) {
        return izin.tanggalMulai.month == lastMonth.month &&
            izin.tanggalMulai.year == lastMonth.year;
      }).toList();
    }

    if (_filter == "Custom" && _customRange != null) {
      return disetujuiList.where((izin) {
        return izin.tanggalMulai.isAfter(
              _customRange!.start.subtract(const Duration(days: 1)),
            ) &&
            izin.tanggalMulai.isBefore(
              _customRange!.end.add(const Duration(days: 1)),
            );
      }).toList();
    }

    return disetujuiList;
  }

  Future<void> _showFilterDialog() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Filter Tanggal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.all_inclusive,
                color: AppColors.primary,
              ),
              title: const Text("Semua"),
              trailing: _filter == "Semua"
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() {
                  _filter = "Semua";
                  _customRange = null;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.calendar_today,
                color: AppColors.primary,
              ),
              title: const Text("Bulan Ini"),
              trailing: _filter == "Bulan Ini"
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() {
                  _filter = "Bulan Ini";
                  _customRange = null;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.calendar_month,
                color: AppColors.primary,
              ),
              title: const Text("Bulan Lalu"),
              trailing: _filter == "Bulan Lalu"
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() {
                  _filter = "Bulan Lalu";
                  _customRange = null;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range, color: AppColors.primary),
              title: const Text("Pilih Tanggal Sendiri"),
              trailing: _filter == "Custom"
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () async {
                Navigator.pop(context);
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  initialDateRange: _customRange,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.primary,
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
        child: Consumer<IzinProvider>(
          builder: (context, izinProvider, child) {
            if (izinProvider.isLoading) {
              return Column(
                children: [
                  _buildHeader(context, screenWidth, screenHeight, padding),
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            if (izinProvider.state == IzinState.error) {
              return Column(
                children: [
                  _buildHeader(context, screenWidth, screenHeight, padding),
                  Expanded(
                    child: Center(
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
                            izinProvider.errorMessage ?? 'Terjadi kesalahan',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadData,
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
                    ),
                  ),
                ],
              );
            }

            final disetujuiList = izinProvider.disetujuiList;
            final filteredList = _getFilteredIzin(disetujuiList);

            return Column(
              children: [
                _buildHeader(context, screenWidth, screenHeight, padding),
                if (_filter != "Semua")
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    color: AppColors.primary.withOpacity(0.1),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_alt,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _filter == "Custom" && _customRange != null
                                ? 'Filter: ${DateFormat('dd MMM yyyy', 'id_ID').format(_customRange!.start)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(_customRange!.end)}'
                                : 'Filter: $_filter',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _filter = "Semua";
                              _customRange = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada data izin yang disetujui',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                              if (_filter != "Semua") ...[
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _filter = "Semua";
                                      _customRange = null;
                                    });
                                  },
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Hapus Filter'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final izin = filteredList[index];
                              return _buildIzinCard(izin);
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFilterDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        label: const Text(
          "Filter Tanggal",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.filter_alt),
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
            "Data Izin",
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

  Widget _buildIzinCard(PengajuanIzin izin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailIzinPage(izinId: izin.id)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: izin.jenisIzin == "Sakit"
                          ? AppColors.error.withOpacity(0.2)
                          : AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      izin.jenisIzin,
                      style: TextStyle(
                        color: izin.jenisIzin == "Sakit"
                            ? AppColors.error
                            : AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Disetujui',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${izin.durasiHari}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        const Text(
                          'Hari',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                  'id_ID',
                                ).format(izin.tanggalMulai),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.event,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                  'id_ID',
                                ).format(izin.tanggalSelesai),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (izin.keterangan != null &&
                            izin.keterangan!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            izin.keterangan!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Disetujui: ${DateFormat('dd MMM yyyy', 'id_ID').format(izin.diprosesPada ?? izin.createdAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  if (izin.fileUrl != null)
                    const Icon(
                      Icons.attach_file,
                      size: 16,
                      color: AppColors.primary,
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
