import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/jadwal_provider.dart';
import '../providers/presensi_provider.dart';
import '../core/constants/app_colors.dart';
import '../components/shimmer_loading.dart';

class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  String? _selectedBulan;
  List<PeriodOption> _periodOptions = [];
  bool _isInitialized = false;
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;

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

  bool get _shouldRefresh {
    if (_lastRefreshTime == null) return true;
    return DateTime.now().difference(_lastRefreshTime!).inSeconds > 30;
  }

  void _initializePeriods() async {
    if (_isInitialized) return;

    setState(() => _isRefreshing = true);

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
          _isRefreshing = false;
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
          _isRefreshing = false;
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
      await _loadJadwal();

      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _loadJadwal() async {
    if (_selectedBulan == null || !mounted || !_shouldRefresh) return;

    _lastRefreshTime = DateTime.now();
    final jadwalProvider = Provider.of<JadwalProvider>(context, listen: false);
    await jadwalProvider.loadJadwalBulan(_selectedBulan!);
  }

  void _previousMonth() {
    if (_periodOptions.isEmpty || _selectedBulan == null) return;

    final currentIndex = _periodOptions.indexWhere(
      (p) => p.value == _selectedBulan,
    );
    if (currentIndex > 0) {
      setState(() {
        _selectedBulan = _periodOptions[currentIndex - 1].value;
        _lastRefreshTime = null;
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
        _lastRefreshTime = null;
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

  void _showTukarShiftInfo(jadwal) {
    if (!jadwal.isDitukar || jadwal.tukarShiftInfo == null) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallScreen = screenWidth < 340;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isVerySmallScreen ? 6 : 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.swap_horiz,
                  color: AppColors.primary,
                  size: isVerySmallScreen ? 20 : 24,
                ),
              ),
              SizedBox(width: isVerySmallScreen ? 8 : 12),
              Flexible(
                child: Text(
                  'Shift Ditukar',
                  style: TextStyle(fontSize: isVerySmallScreen ? 16 : 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shift ini telah ditukar dengan:',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: isVerySmallScreen ? 12 : 14,
                ),
              ),
              SizedBox(height: isVerySmallScreen ? 8 : 12),
              Container(
                padding: EdgeInsets.all(isVerySmallScreen ? 10 : 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: isVerySmallScreen ? 38 : 44,
                      height: isVerySmallScreen ? 38 : 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.3),
                            AppColors.primary.withOpacity(0.2),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: isVerySmallScreen ? 22 : 26,
                      ),
                    ),
                    SizedBox(width: isVerySmallScreen ? 8 : 12),
                    Expanded(
                      child: Text(
                        jadwal.tukarShiftInfo!.dengan,
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen ? 16 : 20,
                  vertical: isVerySmallScreen ? 10 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Tutup',
                style: TextStyle(fontSize: isVerySmallScreen ? 13 : 15),
              ),
            ),
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

    final bool isVerySmallScreen = screenWidth < 340;

    if (_isRefreshing) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 254, 253, 253),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, screenWidth, screenHeight, padding),
              _buildMonthNavigationShimmer(screenWidth),
              Expanded(child: _buildShimmerLayout(screenWidth, padding)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 253, 253),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, screenWidth, screenHeight, padding),
            _buildMonthNavigation(screenWidth, isVerySmallScreen),
            Expanded(
              child: Consumer<JadwalProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return _buildShimmerLayout(screenWidth, padding);
                  }

                  if (provider.errorMessage != null) {
                    return _buildErrorState(
                      provider.errorMessage!,
                      screenWidth,
                    );
                  }

                  final jadwals = provider.jadwalBulan?.jadwals ?? [];

                  if (jadwals.isEmpty) {
                    return _buildEmptyState(screenWidth);
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      _lastRefreshTime = null;
                      await provider.refreshJadwalBulan(_selectedBulan!);
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                      itemCount: jadwals.length,
                      itemBuilder: (context, index) {
                        final jadwal = jadwals[index];
                        return _buildJadwalCard(
                          jadwal,
                          screenWidth,
                          isVerySmallScreen,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLayout(double screenWidth, double padding) {
    final isVerySmallScreen = screenWidth < 340;

    return ShimmerLoading(
      child: ListView.builder(
        padding: EdgeInsets.all(isVerySmallScreen ? 12 : padding),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: isVerySmallScreen ? 10 : 12),
            child: Row(
              children: [
                ShimmerBox(
                  width: isVerySmallScreen ? 50 : 60,
                  height: isVerySmallScreen ? 70 : 80,
                  borderRadius: 12,
                ),
                SizedBox(width: isVerySmallScreen ? 10 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                        width: screenWidth * 0.4,
                        height: isVerySmallScreen ? 14 : 16,
                        borderRadius: 4,
                      ),
                      SizedBox(height: isVerySmallScreen ? 6 : 8),
                      ShimmerBox(
                        width: screenWidth * 0.3,
                        height: isVerySmallScreen ? 12 : 14,
                        borderRadius: 4,
                      ),
                      SizedBox(height: isVerySmallScreen ? 6 : 8),
                      ShimmerBox(
                        width: screenWidth * 0.5,
                        height: isVerySmallScreen ? 12 : 14,
                        borderRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthNavigationShimmer(double screenWidth) {
    final isVerySmallScreen = screenWidth < 340;

    return ShimmerLoading(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isVerySmallScreen ? 10 : 12,
          vertical: isVerySmallScreen ? 8 : 10,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShimmerBox(
              width: isVerySmallScreen ? 35 : 40,
              height: isVerySmallScreen ? 35 : 40,
              borderRadius: 10,
            ),
            ShimmerBox(
              width: screenWidth * 0.5,
              height: isVerySmallScreen ? 18 : 20,
              borderRadius: 4,
            ),
            ShimmerBox(
              width: isVerySmallScreen ? 35 : 40,
              height: isVerySmallScreen ? 35 : 40,
              borderRadius: 10,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, double screenWidth) {
    final bodyFontSize = (screenWidth * 0.034).clamp(11.0, 15.0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: bodyFontSize),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _lastRefreshTime = null;
                _loadJadwal();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(double screenWidth) {
    final bodyFontSize = (screenWidth * 0.034).clamp(11.0, 15.0);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada jadwal untuk bulan ini',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: bodyFontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    double padding,
  ) {
    final titleFontSize = (screenWidth * 0.048).clamp(16.0, 22.0);
    final iconSize = (screenWidth * 0.1).clamp(40.0, 48.0);
    final iconInnerSize = (screenWidth * 0.045).clamp(18.0, 22.0);

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
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: iconInnerSize,
                color: Colors.black87,
              ),
            ),
          ),
          const Spacer(),
          Text(
            "Jadwal Shift",
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          SizedBox(width: iconSize),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation(double screenWidth, bool isVerySmallScreen) {
    final navButtonSize = isVerySmallScreen ? 35.0 : 40.0;
    final navIconSize = isVerySmallScreen ? 24.0 : 28.0;
    final monthFontSize = (screenWidth * 0.038).clamp(14.0, 16.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallScreen ? 10 : 12,
        vertical: isVerySmallScreen ? 8 : 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _canGoPrevious ? _previousMonth : null,
            child: Container(
              width: navButtonSize,
              height: navButtonSize,
              decoration: BoxDecoration(
                color: _canGoPrevious
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.chevron_left,
                color: _canGoPrevious
                    ? AppColors.primary
                    : Colors.grey.shade400,
                size: navIconSize,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _monthDisplay,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: monthFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 0.3,
              ),
            ),
          ),
          GestureDetector(
            onTap: _canGoNext ? _nextMonth : null,
            child: Container(
              width: navButtonSize,
              height: navButtonSize,
              decoration: BoxDecoration(
                color: _canGoNext
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.chevron_right,
                color: _canGoNext ? AppColors.primary : Colors.grey.shade400,
                size: navIconSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalCard(jadwal, double screenWidth, bool isVerySmallScreen) {
    final isToday =
        jadwal.tanggal == DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Debug print untuk melihat data
    debugPrint('🔍 Jadwal Data:');
    debugPrint('   Tanggal: ${jadwal.tanggal}');
    debugPrint('   Shift: ${jadwal.shiftCode}');
    debugPrint('   Waktu Mulai: ${jadwal.waktuMulai}');
    debugPrint('   Waktu Selesai: ${jadwal.waktuSelesai}');
    debugPrint('   Is Libur: ${jadwal.isLibur}');

    // Responsive font sizes
    final dateBoxWidth = isVerySmallScreen ? 50.0 : 60.0;
    final dateFontSize = isVerySmallScreen ? 20.0 : 24.0;
    final monthFontSize = isVerySmallScreen ? 9.0 : 10.0;
    final dayFontSize = (screenWidth * 0.036).clamp(13.0, 15.0);
    final todayBadgeFontSize = isVerySmallScreen ? 9.0 : 10.0;
    final shiftFontSize = (screenWidth * 0.03).clamp(11.0, 12.0);
    final timeFontSize = (screenWidth * 0.032).clamp(11.0, 13.0);
    final infoFontSize = isVerySmallScreen ? 10.0 : 11.0;
    final iconSize = isVerySmallScreen ? 14.0 : 15.0;
    final infoIconSize = isVerySmallScreen ? 16.0 : 18.0;
    final starSize = isVerySmallScreen ? 12.0 : 14.0;

    return GestureDetector(
      onTap: jadwal.isDitukar ? () => _showTukarShiftInfo(jadwal) : null,
      child: Container(
        margin: EdgeInsets.only(bottom: isVerySmallScreen ? 10 : 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isToday
              ? Border.all(color: AppColors.primary, width: 2)
              : jadwal.isDitukar
              ? Border.all(color: Colors.orange.shade300, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: isToday
                  ? AppColors.primary.withOpacity(0.15)
                  : jadwal.isDitukar
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isVerySmallScreen ? 10 : 14),
          child: Row(
            children: [
              // Date Box with Star
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: dateBoxWidth,
                    padding: EdgeInsets.symmetric(
                      vertical: isVerySmallScreen ? 10 : 12,
                      horizontal: isVerySmallScreen ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: jadwal.isLibur
                            ? [Colors.green.shade400, Colors.green.shade600]
                            : jadwal.isWeekend
                            ? [Colors.red.shade400, Colors.red.shade600]
                            : jadwal.isDitukar
                            ? [Colors.orange.shade400, Colors.orange.shade600]
                            : [AppColors.primary, Colors.deepOrange.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (jadwal.isLibur
                                      ? Colors.green
                                      : jadwal.isWeekend
                                      ? Colors.red
                                      : jadwal.isDitukar
                                      ? Colors.orange
                                      : AppColors.primary)
                                  .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          jadwal.tanggalFormat,
                          style: TextStyle(
                            fontSize: dateFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: isVerySmallScreen ? 3 : 4),
                        Text(
                          jadwal.bulanFormat.toUpperCase(),
                          style: TextStyle(
                            fontSize: monthFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Star Badge
                  if (jadwal.isDitukar)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: EdgeInsets.all(isVerySmallScreen ? 4 : 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade300,
                              Colors.amber.shade500,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.5),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.star,
                          color: Colors.white,
                          size: starSize,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(width: isVerySmallScreen ? 10 : 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            jadwal.hari,
                            style: TextStyle(
                              fontSize: dayFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isToday) ...[
                          SizedBox(width: isVerySmallScreen ? 6 : 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isVerySmallScreen ? 6 : 8,
                              vertical: isVerySmallScreen ? 2 : 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, Colors.deepOrange],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Hari Ini',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: todayBadgeFontSize,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    SizedBox(height: isVerySmallScreen ? 6 : 8),

                    if (jadwal.isLibur)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isVerySmallScreen ? 10 : 12,
                          vertical: isVerySmallScreen ? 5 : 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade50,
                              Colors.green.shade100,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.wb_sunny,
                              size: iconSize,
                              color: Colors.green.shade700,
                            ),
                            SizedBox(width: isVerySmallScreen ? 4 : 6),
                            Text(
                              'Hari Libur',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: timeFontSize,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isVerySmallScreen ? 8 : 10,
                              vertical: isVerySmallScreen ? 3 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: jadwal.isDitukar
                                  ? Colors.orange.withOpacity(0.15)
                                  : AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Shift ${jadwal.shiftCode}',
                              style: TextStyle(
                                color: jadwal.isDitukar
                                    ? Colors.orange.shade700
                                    : AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: shiftFontSize,
                              ),
                            ),
                          ),
                          if (jadwal.isDitukar) ...[
                            SizedBox(width: isVerySmallScreen ? 6 : 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isVerySmallScreen ? 6 : 8,
                                vertical: isVerySmallScreen ? 2 : 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber.shade100,
                                    Colors.amber.shade200,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.amber.shade400,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.swap_horiz,
                                    size: isVerySmallScreen ? 11 : 12,
                                    color: Colors.amber.shade700,
                                  ),
                                  SizedBox(width: isVerySmallScreen ? 3 : 4),
                                  Text(
                                    'Ditukar',
                                    style: TextStyle(
                                      color: Colors.amber.shade700,
                                      fontSize: todayBadgeFontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: isVerySmallScreen ? 6 : 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: iconSize,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: isVerySmallScreen ? 4 : 6),
                          Flexible(
                            child: Text(
                              '${jadwal.waktuMulai ?? '-'} - ${jadwal.waktuSelesai ?? '-'}',
                              style: TextStyle(
                                fontSize: timeFontSize,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (jadwal.isDitukar &&
                          jadwal.tukarShiftInfo != null) ...[
                        SizedBox(height: isVerySmallScreen ? 4 : 6),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: iconSize - 1,
                              color: Colors.amber.shade700,
                            ),
                            SizedBox(width: isVerySmallScreen ? 3 : 4),
                            Expanded(
                              child: Text(
                                'dengan ${jadwal.tukarShiftInfo!.dengan}',
                                style: TextStyle(
                                  fontSize: infoFontSize,
                                  color: Colors.amber.shade700,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              // Info Icon
              if (jadwal.isDitukar)
                Container(
                  padding: EdgeInsets.all(isVerySmallScreen ? 5 : 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    size: infoIconSize,
                    color: Colors.amber.shade700,
                  ),
                ),
            ],
          ),
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
