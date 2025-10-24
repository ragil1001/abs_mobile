import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/tukar_shift_provider.dart';
import '../../data/models/tukar_shift_model.dart';
import '../../components/custom_snackbar.dart';
import 'tukar_shift_select_karyawan_page.dart';

class TukarShiftRequestPage extends StatefulWidget {
  const TukarShiftRequestPage({super.key});

  @override
  State<TukarShiftRequestPage> createState() => _TukarShiftRequestPageState();
}

class _TukarShiftRequestPageState extends State<TukarShiftRequestPage> {
  DateTime? _selectedDate;
  int? _selectedShiftId;
  List<JadwalShift> _shifts = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadShifts();
    });
  }

  void _loadShifts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final provider = Provider.of<TukarShiftProvider>(context, listen: false);
    await provider.loadAvailableShifts(
      startDate: _selectedDate?.toString().split(' ')[0],
      endDate: _selectedDate?.toString().split(' ')[0],
    );

    if (mounted) {
      setState(() {
        _shifts = provider.availableShifts;
        _isLoading = provider.isLoadingShifts;
        _errorMessage = provider.errorMessageShifts;
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _selectedShiftId = null;
      });
      _loadShifts();
    }
  }

  void _selectShift(int shiftId) {
    setState(() {
      if (_selectedShiftId == shiftId) {
        _selectedShiftId = null;
      } else {
        _selectedShiftId = shiftId;
      }
    });
  }

  void _proceedToSelectKaryawan() {
    if (_selectedShiftId == null) {
      CustomSnackbar.showWarning(
        context,
        'Pilih shift yang ingin ditukar terlebih dahulu',
      );
      return;
    }

    final selectedShift = _shifts.firstWhere(
      (shift) => shift.id == _selectedShiftId,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TukarShiftSelectKaryawanPage(selectedShift: selectedShift),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.05;
    final titleFontSize = (screenWidth * 0.048).clamp(16.0, 20.0);
    final bodyFontSize = (screenWidth * 0.036).clamp(12.0, 14.0);
    final smallFontSize = (screenWidth * 0.032).clamp(10.0, 12.0);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 253, 253),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              context,
              screenWidth,
              screenHeight,
              padding,
              titleFontSize,
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(padding),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: (screenWidth * 0.05).clamp(18.0, 20.0),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: Text(
                      'Pilih shift Anda yang ingin ditukar dengan shift karyawan lain',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: bodyFontSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(padding),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: Icon(
                        Icons.calendar_today,
                        size: (screenWidth * 0.045).clamp(16.0, 18.0),
                      ),
                      label: Text(
                        _selectedDate == null
                            ? 'Filter Tanggal'
                            : DateFormat(
                                'dd MMMM yyyy',
                                'id_ID',
                              ).format(_selectedDate!),
                        style: TextStyle(fontSize: bodyFontSize),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.015,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (_selectedDate != null) ...[
                    SizedBox(width: screenWidth * 0.02),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: (screenWidth * 0.05).clamp(18.0, 20.0),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                          _selectedShiftId = null;
                        });
                        _loadShifts();
                      },
                      color: AppColors.error,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: (screenWidth * 0.16).clamp(48.0, 64.0),
                              color: AppColors.error.withOpacity(0.5),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: bodyFontSize,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            ElevatedButton(
                              onPressed: _loadShifts,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.08,
                                  vertical: screenHeight * 0.015,
                                ),
                              ),
                              child: Text(
                                'Coba Lagi',
                                style: TextStyle(fontSize: bodyFontSize),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _shifts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: (screenWidth * 0.16).clamp(48.0, 64.0),
                            color: Colors.grey.shade300,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            'Tidak ada shift yang tersedia',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: bodyFontSize,
                            ),
                          ),
                          if (_selectedDate != null) ...[
                            SizedBox(height: screenHeight * 0.01),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedDate = null;
                                  _selectedShiftId = null;
                                });
                                _loadShifts();
                              },
                              child: Text(
                                'Hapus Filter',
                                style: TextStyle(fontSize: bodyFontSize),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      itemCount: _shifts.length,
                      itemBuilder: (context, index) {
                        final shift = _shifts[index];
                        final isSelected = _selectedShiftId == shift.id;
                        return _buildShiftCard(
                          shift,
                          isSelected,
                          screenWidth,
                          bodyFontSize,
                          smallFontSize,
                        );
                      },
                    ),
            ),
            Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _proceedToSelectKaryawan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Lanjut Pilih Karyawan',
                      style: TextStyle(
                        fontSize: bodyFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
    double titleFontSize,
  ) {
    final iconSize = (screenWidth * 0.1).clamp(36.0, 42.0);

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
                size: (screenWidth * 0.045).clamp(16.0, 18.0),
                color: Colors.black87,
              ),
            ),
          ),
          const Spacer(),
          Text(
            "Pilih Shift Anda",
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

  Widget _buildShiftCard(
    JadwalShift shift,
    bool isSelected,
    double screenWidth,
    double bodyFontSize,
    double smallFontSize,
  ) {
    return GestureDetector(
      onTap: () => _selectShift(shift.id),
      child: Container(
        margin: EdgeInsets.only(bottom: screenWidth * 0.03),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.035),
          child: Row(
            children: [
              Container(
                width: (screenWidth * 0.15).clamp(50.0, 60.0),
                padding: EdgeInsets.symmetric(
                  vertical: screenWidth * 0.03,
                  horizontal: screenWidth * 0.02,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSelected
                        ? [AppColors.primary, Colors.deepOrange.shade600]
                        : [Colors.blue.shade400, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (isSelected ? AppColors.primary : Colors.blue)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '${shift.tanggal.day}',
                      style: TextStyle(
                        fontSize: (screenWidth * 0.06).clamp(20.0, 24.0),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    Text(
                      DateFormat(
                        'MMM',
                        'id_ID',
                      ).format(shift.tanggal).toUpperCase(),
                      style: TextStyle(
                        fontSize: (screenWidth * 0.026).clamp(9.0, 10.0),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: screenWidth * 0.035),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift.hari,
                      style: TextStyle(
                        fontSize: bodyFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.025,
                        vertical: screenWidth * 0.01,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Shift ${shift.shiftCode}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: smallFontSize,
                        ),
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: (screenWidth * 0.038).clamp(13.0, 15.0),
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: screenWidth * 0.015),
                        Text(
                          '${shift.waktuMulai ?? '-'} - ${shift.waktuSelesai ?? '-'}',
                          style: TextStyle(
                            fontSize: smallFontSize,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.015),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: (screenWidth * 0.05).clamp(18.0, 20.0),
                  ),
                )
              else
                Container(
                  width: (screenWidth * 0.07).clamp(24.0, 28.0),
                  height: (screenWidth * 0.07).clamp(24.0, 28.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
