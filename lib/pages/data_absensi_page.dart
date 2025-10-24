import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'history_absensi_page.dart';
import 'data_izin_page.dart';
import '../components/bottom_curve_clipper.dart';
import '../providers/presensi_provider.dart';
import '../components/shimmer_loading.dart';

class DataAbsensiPage extends StatefulWidget {
  final bool isForceLoading; // ✅ NEW parameter

  const DataAbsensiPage({super.key, this.isForceLoading = false});

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
    if (_selectedPeriod == null || _periodOptions.isEmpty) {
      return "Pilih Periode";
    }
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

    // Responsive sizing - adopsi dari home_page.dart
    final bool isVerySmallScreen = screenWidth < 340;
    final bool isSmallScreen = screenWidth >= 340 && screenWidth < 360;

    final padding = screenWidth * 0.05;
    final titleFontSize = (screenWidth * 0.052).clamp(16.0, 22.0);
    final bodyFontSize = (screenWidth * 0.034).clamp(11.0, 15.0);
    final smallFontSize = (screenWidth * 0.035).clamp(10.0, 13.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<PresensiProvider>(
        builder: (context, provider, child) {
          final shouldShowShimmer =
              widget.isForceLoading || provider.isLoadingStatistik;
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
                child: shouldShowShimmer
                    ? _buildShimmerLayout(
                        screenWidth,
                        screenHeight,
                        padding,
                        titleFontSize,
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          padding,
                          screenHeight * 0.06,
                          padding,
                          screenHeight * 0.03,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Data Absensi",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            if (provider.errorMessageStatistik != null)
                              _buildErrorContainer(
                                provider.errorMessageStatistik!,
                                bodyFontSize,
                              )
                            else if (provider.statistikPeriode == null)
                              _buildEmptyContainer(bodyFontSize)
                            else
                              _buildStatistikContainer(
                                provider.statistikPeriode,
                                screenWidth,
                                screenHeight,
                                bodyFontSize,
                                smallFontSize,
                                isVerySmallScreen,
                              ),
                            SizedBox(height: screenHeight * 0.02),
                            _buildMenuCard(
                              icon: Icons.calendar_today,
                              title: "Data Absensi",
                              subtitle: "Lihat riwayat absensi",
                              screenWidth: screenWidth,
                              screenHeight: screenHeight,
                              bodyFontSize: bodyFontSize,
                              smallFontSize: smallFontSize,
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
                              screenWidth: screenWidth,
                              screenHeight: screenHeight,
                              bodyFontSize: bodyFontSize,
                              smallFontSize: smallFontSize,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const DataIzinPage(),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: screenHeight * 0.025),
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

  Widget _buildShimmerLayout(
    double screenWidth,
    double screenHeight,
    double padding,
    double titleFontSize,
  ) {
    return ShimmerLoading(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          padding,
          screenHeight * 0.06,
          padding,
          screenHeight * 0.03,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(
              width: screenWidth * 0.4,
              height: titleFontSize,
              borderRadius: 4,
            ),
            SizedBox(height: screenHeight * 0.02),
            ShimmerBox(
              width: double.infinity,
              height: screenHeight * 0.35,
              borderRadius: 16,
            ),
            SizedBox(height: screenHeight * 0.02),
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
            SizedBox(height: screenHeight * 0.025),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContainer(String error, double bodyFontSize) {
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
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: bodyFontSize,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContainer(double bodyFontSize) {
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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'Tidak ada data statistik',
            style: TextStyle(fontSize: bodyFontSize),
          ),
        ),
      ),
    );
  }

  Widget _buildStatistikContainer(
    dynamic statistik,
    double screenWidth,
    double screenHeight,
    double bodyFontSize,
    double smallFontSize,
    bool isVerySmallScreen,
  ) {
    if (_periodOptions.isEmpty) {
      return _buildEmptyContainer(bodyFontSize);
    }

    final period = _periodOptions.firstWhere(
      (p) => p.value == _selectedPeriod,
      orElse: () => _periodOptions.first,
    );

    final daysInPeriod = period.endDate.difference(period.startDate).inDays + 1;

    final hadir = statistik.hadir;
    final izin = statistik.izin;
    final alpa = statistik.alpa;
    final sakit = statistik.sakit;
    final cuti = statistik.cuti;
    final lembur = statistik.lembur;
    final terlambat = statistik.terlambat;
    final pulangCepat = statistik.pulangCepat;
    final tidakPresensiPulang = statistik.tidakPresensiPulang;

    // Responsive font sizes
    final headerFontSize = (screenWidth * 0.045).clamp(15.0, 18.0);
    final periodButtonFontSize = (screenWidth * 0.032).clamp(11.0, 13.0);
    final statTitleFontSize = (screenWidth * 0.034).clamp(12.0, 14.0);
    final statValueFontSize = (screenWidth * 0.032).clamp(11.0, 13.0);

    return Container(
      padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
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
              Flexible(
                child: Text(
                  "Rekap Absensi",
                  style: TextStyle(
                    fontSize: headerFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              InkWell(
                onTap: _pickPeriod,
                borderRadius: BorderRadius.circular(23),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isVerySmallScreen ? 8 : 12,
                    vertical: isVerySmallScreen ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA726),
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _periodText,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: periodButtonFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                        size: isVerySmallScreen ? 18 : 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isVerySmallScreen ? 8 : 12),
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
                  screenWidth: screenWidth,
                  titleFontSize: statTitleFontSize,
                  valueFontSize: statValueFontSize,
                  isVerySmallScreen: isVerySmallScreen,
                ),
              ),
              _buildVerticalDivider(isVerySmallScreen),
              Expanded(
                child: _buildRekapItem(
                  title: "Izin",
                  value: "$izin Hari",
                  valueColor: izin > 0 ? Colors.blue : Colors.black87,
                  barColor: izin > 0 ? Colors.blue : Colors.grey,
                  progress: izin / daysInPeriod,
                  screenWidth: screenWidth,
                  titleFontSize: statTitleFontSize,
                  valueFontSize: statValueFontSize,
                  isVerySmallScreen: isVerySmallScreen,
                ),
              ),
              _buildVerticalDivider(isVerySmallScreen),
              Expanded(
                child: _buildRekapItem(
                  title: "Alpa",
                  value: "$alpa Hari",
                  valueColor: alpa > 0 ? Colors.red : Colors.black87,
                  barColor: alpa > 0 ? Colors.red : Colors.grey,
                  progress: alpa / daysInPeriod,
                  screenWidth: screenWidth,
                  titleFontSize: statTitleFontSize,
                  valueFontSize: statValueFontSize,
                  isVerySmallScreen: isVerySmallScreen,
                ),
              ),
            ],
          ),

          SizedBox(height: isVerySmallScreen ? 8 : 12),
          const Divider(thickness: 1, color: Colors.black26),

          // SAKIT & CUTI
          Row(
            children: [
              Expanded(
                child: _buildRekapItem(
                  title: "Sakit",
                  value: "$sakit Hari",
                  valueColor: sakit > 0 ? Colors.orange : Colors.black87,
                  barColor: sakit > 0 ? Colors.orange : Colors.grey,
                  progress: izin > 0 ? (sakit / izin) : 0.0,
                  screenWidth: screenWidth,
                  titleFontSize: statTitleFontSize,
                  valueFontSize: statValueFontSize,
                  isVerySmallScreen: isVerySmallScreen,
                ),
              ),
              _buildVerticalDivider(isVerySmallScreen),
              Expanded(
                child: _buildRekapItem(
                  title: "Cuti",
                  value: "$cuti Hari",
                  valueColor: cuti > 0 ? Colors.purple : Colors.black87,
                  barColor: cuti > 0 ? Colors.purple : Colors.grey,
                  progress: izin > 0 ? (cuti / izin) : 0.0,
                  screenWidth: screenWidth,
                  titleFontSize: statTitleFontSize,
                  valueFontSize: statValueFontSize,
                  isVerySmallScreen: isVerySmallScreen,
                ),
              ),
            ],
          ),

          SizedBox(height: isVerySmallScreen ? 8 : 12),
          const Divider(thickness: 1, color: Colors.black26),

          // LEMBUR & TERLAMBAT
          Row(
            children: [
              Expanded(
                child: _buildRekapItem(
                  title: "Lembur",
                  value: "$lembur Kali",
                  valueColor: lembur > 0 ? Colors.teal : Colors.black87,
                  barColor: lembur > 0 ? Colors.teal : Colors.grey,
                  progress: hadir > 0 ? (lembur / hadir) : 0.0,
                  screenWidth: screenWidth,
                  titleFontSize: statTitleFontSize,
                  valueFontSize: statValueFontSize,
                  isVerySmallScreen: isVerySmallScreen,
                ),
              ),
              _buildVerticalDivider(isVerySmallScreen),
              Expanded(
                child: _buildRekapItem(
                  title: "Terlambat",
                  value: "$terlambat Kali",
                  valueColor: terlambat > 0 ? Colors.amber : Colors.black87,
                  barColor: terlambat > 0 ? Colors.amber : Colors.grey,
                  progress: hadir > 0 ? (terlambat / hadir) : 0.0,
                  screenWidth: screenWidth,
                  titleFontSize: statTitleFontSize,
                  valueFontSize: statValueFontSize,
                  isVerySmallScreen: isVerySmallScreen,
                ),
              ),
            ],
          ),

          SizedBox(height: isVerySmallScreen ? 8 : 12),
          const Divider(thickness: 1, color: Colors.black26),

          // PULANG CEPAT & TIDAK ABSEN PULANG
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
                  progress: hadir > 0 ? (pulangCepat / hadir) : 0.0,
                  screenWidth: screenWidth,
                  titleFontSize: statTitleFontSize,
                  valueFontSize: statValueFontSize,
                  isVerySmallScreen: isVerySmallScreen,
                ),
              ),
              _buildVerticalDivider(isVerySmallScreen),
              Expanded(
                child: _buildRekapItem(
                  title: "Tidak Presensi Pulang",
                  value: "$tidakPresensiPulang Kali",
                  valueColor: tidakPresensiPulang > 0
                      ? Colors.pink
                      : Colors.black87,
                  barColor: tidakPresensiPulang > 0 ? Colors.pink : Colors.grey,
                  progress: hadir > 0 ? (tidakPresensiPulang / hadir) : 0.0,
                  screenWidth: screenWidth,
                  titleFontSize: statTitleFontSize,
                  valueFontSize: statValueFontSize,
                  isVerySmallScreen: isVerySmallScreen,
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
    required double screenWidth,
    required double titleFontSize,
    required double valueFontSize,
    required bool isVerySmallScreen,
  }) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isVerySmallScreen ? 3 : 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isVerySmallScreen ? 0 : 1),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.normal,
              color: valueColor,
            ),
          ),
          SizedBox(height: isVerySmallScreen ? 3 : 4),
          Container(
            height: isVerySmallScreen ? 5 : 6,
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

  Widget _buildVerticalDivider(bool isVerySmallScreen) {
    return Container(
      width: 1,
      height: isVerySmallScreen ? 40 : 50,
      color: Colors.black26,
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required double screenWidth,
    required double screenHeight,
    required double bodyFontSize,
    required double smallFontSize,
    required VoidCallback onTap,
  }) {
    final cardHeight = (screenHeight * 0.08).clamp(60.0, 70.0);
    final iconSize = (screenWidth * 0.06).clamp(20.0, 26.0);

    return Card(
      elevation: 2,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: cardHeight,
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.01,
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.orange, size: iconSize),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: bodyFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: smallFontSize,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey, size: iconSize),
            ],
          ),
        ),
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
