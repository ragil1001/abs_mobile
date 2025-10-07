import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'home_page.dart';
import 'history_absensi_page.dart';
import 'data_izin_page.dart';
import '../components/bottom_curve_clipper.dart';
import '../providers/presensi_provider.dart';
import '../providers/auth_provider.dart';
import '../components/shimmer_loading.dart';

class DataAbsensiPage extends StatefulWidget {
  const DataAbsensiPage({super.key});

  @override
  State<DataAbsensiPage> createState() => _DataAbsensiPageState();
}

class _DataAbsensiPageState extends State<DataAbsensiPage> {
  String? _selectedPeriod;
  List<PeriodOption> _periodOptions = [];
  bool _isInitialized = false;

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
    _periodOptions.clear();
    _selectedPeriod = null;
    _isInitialized = false;
    super.dispose();
  }

  void _initializePeriods() async {
    if (_isInitialized) return;

    final presensiProvider = Provider.of<PresensiProvider>(
      context,
      listen: false,
    );

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

    final projectStart = DateTime.parse(presensiData.projectInfo!.tanggalMulai);
    final today = DateTime.now();

    final periods = <PeriodOption>[];
    var currentDate = DateTime(
      projectStart.year,
      projectStart.month,
      projectStart.day,
    );
    final endDate = DateTime(today.year, today.month + 3, today.day);

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

    final currentMonth = DateFormat('yyyy-MM').format(today);
    final defaultPeriod = periods.firstWhere(
      (p) => p.value == currentMonth,
      orElse: () => periods.last,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<PresensiProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
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
              RefreshIndicator(
                onRefresh: () async {
                  _loadStatistik();
                },
                child: provider.isLoadingStatistik
                    ? _buildShimmerLayout(screenWidth, screenHeight)
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Data Absensi",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (provider.errorMessageStatistik != null)
                              _buildErrorContainer(
                                provider.errorMessageStatistik!,
                              )
                            else if (provider.statistikPeriode == null)
                              _buildEmptyContainer()
                            else
                              _buildStatistikContainer(
                                provider.statistikPeriode,
                              ),
                            const SizedBox(height: 20),
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
                                  MaterialPageRoute(
                                    builder: (_) => const DataIzinPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 25),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShimmerLayout(double screenWidth, double screenHeight) {
    return ShimmerLoading(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Text
            ShimmerBox(width: screenWidth * 0.4, height: 20, borderRadius: 4),
            const SizedBox(height: 20),
            // Rekap Container
            ShimmerBox(
              width: double.infinity,
              height: screenHeight * 0.35,
              borderRadius: 16,
            ),
            const SizedBox(height: 20),
            // Menu Cards
            ShimmerBox(
              width: double.infinity,
              height: (screenHeight * 0.08).clamp(60.0, 70.0),
              borderRadius: 12,
            ),
            const SizedBox(height: 12),
            ShimmerBox(
              width: double.infinity,
              height: (screenHeight * 0.08).clamp(60.0, 70.0),
              borderRadius: 12,
            ),
            const SizedBox(height: 25),
          ],
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
    if (_periodOptions.isEmpty) {
      return _buildEmptyContainer();
    }

    // Get periode info
    final period = _periodOptions.firstWhere(
      (p) => p.value == _selectedPeriod,
      orElse: () => _periodOptions.first,
    );

    // CRITICAL: Hitung jumlah hari dalam periode
    final daysInPeriod = period.endDate.difference(period.startDate).inDays + 1;

    // LOGIKA BARU untuk progress bar:
    // 1. Hadir, Izin, Alpa → max = daysInPeriod
    // 2. Sakit, Cuti → max = izin (subset dari izin)
    // 3. Lembur, Pulang Cepat, TPP → max = hadir (subset dari hadir)
    // 4. Terlambat → max = hadir (tapi tidak mengurangi quota Lembur/PC/TPP)

    final hadir = statistik.hadir;
    final izin = statistik.izin;
    final alpa = statistik.alpa;
    final sakit = statistik.sakit;
    final cuti = statistik.cuti;
    final lembur = statistik.lembur;
    final terlambat = statistik.terlambat;
    final pulangCepat = statistik.pulangCepat;
    final tidakPresensiPulang = statistik.tidakPresensiPulang;

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

          // STATISTIK UTAMA: Hadir, Izin, Alpa
          Row(
            children: [
              Expanded(
                child: _buildRekapItem(
                  title: "Hadir",
                  value: "$hadir Hari",
                  valueColor: hadir > 0 ? Colors.green : Colors.black87,
                  barColor: hadir > 0 ? Colors.green : Colors.grey,
                  progress: hadir / daysInPeriod,
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildRekapItem(
                  title: "Izin",
                  value: "$izin Hari",
                  valueColor: izin > 0 ? Colors.blue : Colors.black87,
                  barColor: izin > 0 ? Colors.blue : Colors.grey,
                  progress: izin / daysInPeriod,
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildRekapItem(
                  title: "Alpa",
                  value: "$alpa Hari",
                  valueColor: alpa > 0 ? Colors.red : Colors.black87,
                  barColor: alpa > 0 ? Colors.red : Colors.grey,
                  progress: alpa / daysInPeriod,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(thickness: 1, color: Colors.black26),

          // SAKIT & CUTI (subset dari Izin)
          Row(
            children: [
              Expanded(
                child: _buildRekapItem(
                  title: "Sakit",
                  value: "$sakit Hari",
                  valueColor: sakit > 0 ? Colors.orange : Colors.black87,
                  barColor: sakit > 0 ? Colors.orange : Colors.grey,
                  // CRITICAL: max bar = izin (bukan daysInPeriod)
                  progress: izin > 0 ? (sakit / izin) : 0.0,
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildRekapItem(
                  title: "Cuti",
                  value: "$cuti Hari",
                  valueColor: cuti > 0 ? Colors.purple : Colors.black87,
                  barColor: cuti > 0 ? Colors.purple : Colors.grey,
                  // CRITICAL: max bar = izin (bukan daysInPeriod)
                  progress: izin > 0 ? (cuti / izin) : 0.0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(thickness: 1, color: Colors.black26),

          // LEMBUR & TERLAMBAT (terkait Hadir)
          Row(
            children: [
              Expanded(
                child: _buildRekapItem(
                  title: "Lembur",
                  value: "$lembur Kali",
                  valueColor: lembur > 0 ? Colors.teal : Colors.black87,
                  barColor: lembur > 0 ? Colors.teal : Colors.grey,
                  // CRITICAL: max bar = hadir
                  progress: hadir > 0 ? (lembur / hadir) : 0.0,
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildRekapItem(
                  title: "Terlambat",
                  value: "$terlambat Kali",
                  valueColor: terlambat > 0 ? Colors.amber : Colors.black87,
                  barColor: terlambat > 0 ? Colors.amber : Colors.grey,
                  // CRITICAL: max bar = hadir
                  progress: hadir > 0 ? (terlambat / hadir) : 0.0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(thickness: 1, color: Colors.black26),

          // PULANG CEPAT & TIDAK ABSEN PULANG (subset dari Hadir)
          Row(
            children: [
              Expanded(
                child: _buildRekapItem(
                  title: "Pulang Cepat",
                  value: "$pulangCepat Kali",
                  valueColor: pulangCepat > 0
                      ? Colors.deepOrange
                      : Colors.black87,
                  barColor: pulangCepat > 0 ? Colors.deepOrange : Colors.grey,
                  // CRITICAL: max bar = hadir
                  progress: hadir > 0 ? (pulangCepat / hadir) : 0.0,
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildRekapItem(
                  title: "Tidak Absen Pulang",
                  value: "$tidakPresensiPulang Kali",
                  valueColor: tidakPresensiPulang > 0
                      ? Colors.pink
                      : Colors.black87,
                  barColor: tidakPresensiPulang > 0 ? Colors.pink : Colors.grey,
                  // CRITICAL: max bar = hadir
                  progress: hadir > 0 ? (tidakPresensiPulang / hadir) : 0.0,
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
