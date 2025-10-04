import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/jadwal_provider.dart';
import '../providers/presensi_provider.dart';
import '../core/constants/app_colors.dart';

class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  String? _selectedBulan;
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
    _selectedBulan = null;
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
    var currentDate = DateTime(projectStart.year, projectStart.month, 1);
    final endDate = DateTime(today.year, today.month + 3, 1);

    while (currentDate.isBefore(endDate)) {
      final periodStart = DateTime(currentDate.year, currentDate.month, 1);

      final label = DateFormat('MMMM yyyy', 'id_ID').format(periodStart);

      periods.add(
        PeriodOption(
          value: DateFormat('yyyy-MM').format(periodStart),
          label: label,
          startDate: periodStart,
          endDate: DateTime(periodStart.year, periodStart.month + 1, 0),
        ),
      );

      currentDate = DateTime(currentDate.year, currentDate.month + 1, 1);
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
        _selectedBulan = defaultPeriod.value;
        _isInitialized = true;
      });
      _loadJadwal();
    }
  }

  void _loadJadwal() {
    if (_selectedBulan == null || !mounted) return;

    final jadwalProvider = Provider.of<JadwalProvider>(context, listen: false);
    jadwalProvider.loadJadwalBulan(_selectedBulan!);
  }

  void _previousMonth() {
    if (_periodOptions.isEmpty || _selectedBulan == null) return;

    final currentIndex = _periodOptions.indexWhere(
      (p) => p.value == _selectedBulan,
    );
    if (currentIndex > 0) {
      setState(() {
        _selectedBulan = _periodOptions[currentIndex - 1].value;
      });
      _loadJadwal();
    }
  }

  void _nextMonth() {
    if (_periodOptions.isEmpty || _selectedBulan == null) return;

    final currentIndex = _periodOptions.indexWhere(
      (p) => p.value == _selectedBulan,
    );
    if (currentIndex < _periodOptions.length - 1) {
      setState(() {
        _selectedBulan = _periodOptions[currentIndex + 1].value;
      });
      _loadJadwal();
    }
  }

  String get _monthDisplay {
    if (_selectedBulan == null || _periodOptions.isEmpty) return '';
    final period = _periodOptions.firstWhere(
      (p) => p.value == _selectedBulan,
      orElse: () => _periodOptions.first,
    );
    return period.label;
  }

  bool get _canGoPrevious {
    if (_periodOptions.isEmpty || _selectedBulan == null) return false;
    final currentIndex = _periodOptions.indexWhere(
      (p) => p.value == _selectedBulan,
    );
    return currentIndex > 0;
  }

  bool get _canGoNext {
    if (_periodOptions.isEmpty || _selectedBulan == null) return false;
    final currentIndex = _periodOptions.indexWhere(
      (p) => p.value == _selectedBulan,
    );
    return currentIndex < _periodOptions.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Jadwal Shift Kerja'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Month Navigation Header
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _canGoPrevious ? _previousMonth : null,
                  icon: const Icon(Icons.chevron_left),
                  color: AppColors.primary,
                  disabledColor: Colors.grey.shade300,
                  iconSize: 28,
                ),
                Expanded(
                  child: Text(
                    _monthDisplay,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _canGoNext ? _nextMonth : null,
                  icon: const Icon(Icons.chevron_right),
                  color: AppColors.primary,
                  disabledColor: Colors.grey.shade300,
                  iconSize: 28,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Consumer<JadwalProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  );
                }

                if (provider.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.error.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            provider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadJadwal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final jadwals = provider.jadwalBulan?.jadwals ?? [];

                if (jadwals.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada jadwal untuk bulan ini',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.refreshJadwalBulan(_selectedBulan!),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: jadwals.length,
                    itemBuilder: (context, index) {
                      final jadwal = jadwals[index];
                      return _buildJadwalCard(jadwal);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalCard(jadwal) {
    final isToday =
        jadwal.tanggal == DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: isToday
                ? AppColors.primary.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Left side - Date
            Container(
              width: 56,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: jadwal.isLibur
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : jadwal.isWeekend
                      ? [Colors.red.shade400, Colors.red.shade600]
                      : [AppColors.primary, Colors.deepOrange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    jadwal.tanggalFormat,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    jadwal.bulanFormat.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Right side - Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        jadwal.hari,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Hari Ini',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 6),

                  if (jadwal.isLibur)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wb_sunny,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Libur',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'Shift ${jadwal.shiftCode}',
                            style: TextStyle(
                              color: AppColors.primary.withOpacity(0.9),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${jadwal.waktuMulai ?? '-'} - ${jadwal.waktuSelesai ?? '-'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class
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
