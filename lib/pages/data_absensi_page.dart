import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'home_page.dart';
import 'history_absensi_page.dart';
import 'data_izin_page.dart';
import '../components/bottom_curve_clipper.dart';
import '../providers/presensi_provider.dart';
import '../providers/auth_provider.dart';

class DataAbsensiPage extends StatefulWidget {
  const DataAbsensiPage({super.key});

  @override
  State<DataAbsensiPage> createState() => _DataAbsensiPageState();
}

class _DataAbsensiPageState extends State<DataAbsensiPage> {
  String? _selectedPeriod;
  List<PeriodOption> _periodOptions = [];
  bool _isInitialized = false; // TAMBAH INI

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized) {
        _initializePeriods();
      }
    });
  }

  @override
  void dispose() {
    // Clear state saat dispose
    _periodOptions.clear();
    _selectedPeriod = null;
    _isInitialized = false;
    super.dispose();
  }

  void _initializePeriods() async {
    if (_isInitialized) return; // Prevent multiple initialization

    final presensiProvider = Provider.of<PresensiProvider>(
      context,
      listen: false,
    );

    // Load presensi data dulu untuk mendapatkan info project
    if (presensiProvider.presensiData == null) {
      await presensiProvider.loadPresensiData();
    }

    final presensiData = presensiProvider.presensiData;
    if (presensiData == null || presensiData.projectInfo == null) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
      return;
    }

    // Ambil tanggal mulai project dari backend
    final projectStart = DateTime.parse(presensiData.projectInfo!.tanggalMulai);
    final today = DateTime.now();

    final periods = <PeriodOption>[];
    var currentDate = DateTime(
      projectStart.year,
      projectStart.month,
      projectStart.day,
    );
    final endDate = DateTime(today.year, today.month + 3, today.day);

    // Generate periods dari project start hingga 3 bulan ke depan
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final periodStart = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
      );
      final periodEnd = DateTime(
        currentDate.year,
        currentDate.month + 1,
        currentDate.day,
      ).subtract(const Duration(days: 1));

      // Format singkat: MMM yyyy (Okt 2025)
      final startMonth = DateFormat('MMM yyyy', 'id_ID').format(periodStart);
      final endMonth = DateFormat('MMM yyyy', 'id_ID').format(periodEnd);

      final label = startMonth == endMonth
          ? startMonth
          : '$startMonth - $endMonth';

      periods.add(
        PeriodOption(
          value: DateFormat('yyyy-MM').format(periodStart),
          label: label,
          startDate: periodStart,
          endDate: periodEnd,
        ),
      );

      currentDate = DateTime(
        currentDate.year,
        currentDate.month + 1,
        currentDate.day,
      );
    }

    if (periods.isEmpty) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
      return;
    }

    // Find current month period sebagai default
    final currentMonth = DateFormat('yyyy-MM').format(today);
    final defaultPeriod = periods.firstWhere(
      (p) => p.value == currentMonth,
      orElse: () =>
          periods.last, // Jika bulan ini tidak ada, pilih yang terakhir
    );

    if (mounted) {
      setState(() {
        _periodOptions = periods;
        _selectedPeriod = defaultPeriod.value;
        _isInitialized = true;
      });
      _loadStatistik();
    }
  }

  void _loadStatistik() {
    if (_selectedPeriod == null || !mounted) return;

    final presensiProvider = Provider.of<PresensiProvider>(
      context,
      listen: false,
    );
    presensiProvider.loadStatistikPeriode(_selectedPeriod!);
  }

  Future<void> _pickPeriod() async {
    if (_periodOptions.isEmpty) return;

    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Pilih Periode"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _periodOptions.length,
              itemBuilder: (context, index) {
                final period = _periodOptions[index];
                final isSelected = _selectedPeriod == period.value;

                return ListTile(
                  title: Text(period.label),
                  selected: isSelected,
                  selectedTileColor: Colors.orange.shade50,
                  onTap: () => Navigator.pop(context, period.value),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
          ],
        );
      },
    );

    if (selected != null && selected != _selectedPeriod) {
      setState(() {
        _selectedPeriod = selected;
      });
      _loadStatistik();
    }
  }

  String get _periodText {
    if (_selectedPeriod == null || _periodOptions.isEmpty)
      return "Pilih Periode";
    final period = _periodOptions.firstWhere(
      (p) => p.value == _selectedPeriod,
      orElse: () => _periodOptions.isNotEmpty
          ? _periodOptions.first
          : PeriodOption(
              value: '',
              label: 'Pilih Periode',
              startDate: DateTime.now(),
              endDate: DateTime.now(),
            ),
    );
    return period.label;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Header background
          ClipPath(
            clipper: BottomCurveClipper(),
            child: Container(
              width: double.infinity,
              height: 300,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Content
          RefreshIndicator(
            onRefresh: () async {
              _loadStatistik();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    "Data Absensi",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Statistik Container
                  Consumer<PresensiProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoadingStatistik) {
                        return _buildLoadingContainer();
                      }

                      if (provider.errorMessageStatistik != null) {
                        return _buildErrorContainer(
                          provider.errorMessageStatistik!,
                        );
                      }

                      final statistik = provider.statistikPeriode;
                      if (statistik == null) {
                        return _buildEmptyContainer();
                      }

                      return _buildStatistikContainer(statistik);
                    },
                  ),

                  const SizedBox(height: 20),

                  // Menu Cards
                  _buildMenuCard(
                    icon: Icons.calendar_today,
                    title: "Data Absensi",
                    subtitle: "Lihat riwayat absensi",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HistoryAbsensiPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    icon: Icons.description,
                    title: "Data Izin",
                    subtitle: "Data Izin / Cuti yang sudah disetujui",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DataIzinPage()),
                      );
                    },
                  ),

                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      ),
    );
  }

  Widget _buildErrorContainer(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 40),
          const SizedBox(height: 12),
          Text(
            error,
            style: TextStyle(color: Colors.red.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('Tidak ada data statistik'),
        ),
      ),
    );
  }

  Widget _buildStatistikContainer(dynamic statistik) {
    // Safety check: pastikan _periodOptions tidak kosong
    if (_periodOptions.isEmpty) {
      return _buildEmptyContainer();
    }

    // Hitung jumlah hari dalam periode
    final period = _periodOptions.firstWhere(
      (p) => p.value == _selectedPeriod,
      orElse: () => _periodOptions.first,
    );
    final daysInPeriod = period.endDate.difference(period.startDate).inDays + 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Rekap Absensi",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              InkWell(
                onTap: _pickPeriod,
                borderRadius: BorderRadius.circular(23),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA726),
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _periodText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(thickness: 1, color: Colors.black26),

          // Statistik utama: Hadir, Izin, Alpa
          Row(
            children: [
              Expanded(
                child: _buildRekapItem(
                  title: "Hadir",
                  value: "${statistik.hadir} Hari",
                  valueColor: statistik.hadir > 0
                      ? Colors.green
                      : Colors.black87,
                  barColor: statistik.hadir > 0 ? Colors.green : Colors.grey,
                  progress: statistik.hadir / daysInPeriod,
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildRekapItem(
                  title: "Izin",
                  value: "${statistik.izin} Hari",
                  valueColor: statistik.izin > 0 ? Colors.blue : Colors.black87,
                  barColor: statistik.izin > 0 ? Colors.blue : Colors.grey,
                  progress: statistik.izin / daysInPeriod,
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildRekapItem(
                  title: "Alpa",
                  value: "${statistik.alpa} Hari",
                  valueColor: statistik.alpa > 0 ? Colors.red : Colors.black87,
                  barColor: statistik.alpa > 0 ? Colors.red : Colors.grey,
                  progress: statistik.alpa / daysInPeriod,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(thickness: 1, color: Colors.black26),

          // Sakit & Cuti
          Row(
            children: [
              Expanded(
                child: _buildRekapItem(
                  title: "Sakit",
                  value: "${statistik.sakit} Hari",
                  valueColor: statistik.sakit > 0
                      ? Colors.orange
                      : Colors.black87,
                  barColor: statistik.sakit > 0 ? Colors.orange : Colors.grey,
                  progress: statistik.sakit / daysInPeriod,
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildRekapItem(
                  title: "Cuti",
                  value: "${statistik.cuti} Hari",
                  valueColor: statistik.cuti > 0
                      ? Colors.purple
                      : Colors.black87,
                  barColor: statistik.cuti > 0 ? Colors.purple : Colors.grey,
                  progress: statistik.cuti / daysInPeriod,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(thickness: 1, color: Colors.black26),

          // Lembur & Terlambat
          Row(
            children: [
              Expanded(
                child: _buildRekapItem(
                  title: "Lembur",
                  value: "${statistik.lembur} Kali",
                  valueColor: statistik.lembur > 0
                      ? Colors.teal
                      : Colors.black87,
                  barColor: statistik.lembur > 0 ? Colors.teal : Colors.grey,
                  progress: statistik.lembur / daysInPeriod,
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildRekapItem(
                  title: "Terlambat",
                  value: "${statistik.terlambat} Kali",
                  valueColor: statistik.terlambat > 0
                      ? Colors.amber
                      : Colors.black87,
                  barColor: statistik.terlambat > 0
                      ? Colors.amber
                      : Colors.grey,
                  progress: statistik.terlambat / daysInPeriod,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(thickness: 1, color: Colors.black26),

          // Pulang Cepat & Tidak Absen Pulang
          Row(
            children: [
              Expanded(
                child: _buildRekapItem(
                  title: "Pulang Cepat",
                  value: "${statistik.pulangCepat} Kali",
                  valueColor: statistik.pulangCepat > 0
                      ? Colors.deepOrange
                      : Colors.black87,
                  barColor: statistik.pulangCepat > 0
                      ? Colors.deepOrange
                      : Colors.grey,
                  progress: statistik.pulangCepat / daysInPeriod,
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildRekapItem(
                  title: "Tidak Absen Pulang",
                  value: "${statistik.tidakPresensiPulang} Kali",
                  valueColor: statistik.tidakPresensiPulang > 0
                      ? Colors.pink
                      : Colors.black87,
                  barColor: statistik.tidakPresensiPulang > 0
                      ? Colors.pink
                      : Colors.grey,
                  progress: statistik.tidakPresensiPulang / daysInPeriod,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRekapItem({
    required String title,
    required String value,
    required Color valueColor,
    required Color barColor,
    required double progress,
  }) {
    // Clamp progress between 0 and 1
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          // Progress bar container
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clampedProgress,
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(width: 1, height: 50, color: Colors.black26);
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

// Helper class untuk period options
class PeriodOption {
  final String value;
  final String label;
  final DateTime startDate;
  final DateTime endDate;

  PeriodOption({
    required this.value,
    required this.label,
    required this.startDate,
    required this.endDate,
  });
}
