import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/tukar_shift_provider.dart';
import '../../data/models/tukar_shift_model.dart';
import '../../components/custom_snackbar.dart';
import 'tukar_shift_review_page.dart';

class TukarShiftSelectKaryawanPage extends StatefulWidget {
  final JadwalShift selectedShift;

  const TukarShiftSelectKaryawanPage({super.key, required this.selectedShift});

  @override
  State<TukarShiftSelectKaryawanPage> createState() =>
      _TukarShiftSelectKaryawanPageState();
}

class _TukarShiftSelectKaryawanPageState
    extends State<TukarShiftSelectKaryawanPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  KaryawanWithShift? _selectedKaryawan;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadKaryawan() {
    if (_selectedDate == null) return;

    final provider = Provider.of<TukarShiftProvider>(context, listen: false);
    provider.loadKaryawanWithShift(
      tanggal: _selectedDate!.toString().split(' ')[0],
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
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
        _selectedKaryawan = null;
      });
      _loadKaryawan();
    }
  }

  void _selectKaryawan(KaryawanWithShift karyawan) {
    setState(() {
      _selectedKaryawan = karyawan;
    });
  }

  void _proceedToReview() {
    if (_selectedKaryawan == null) {
      CustomSnackbar.showWarning(
        context,
        'Pilih karyawan dan tanggal terlebih dahulu',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TukarShiftReviewPage(
          shiftSaya: widget.selectedShift,
          shiftDiminta: _selectedKaryawan!.shift,
          karyawanTujuan: _selectedKaryawan!,
        ),
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
    final myShift = widget.selectedShift;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: (screenWidth * 0.05).clamp(18.0, 20.0),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Shift yang akan ditukar:',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: bodyFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenWidth * 0.025),
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.025,
                            vertical: screenWidth * 0.015,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Shift ${myShift.shiftCode}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: smallFontSize,
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat(
                                  'EEEE, dd MMMM yyyy',
                                  'id_ID',
                                ).format(myShift.tanggal),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: bodyFontSize,
                                ),
                              ),
                              Text(
                                '${myShift.waktuMulai} - ${myShift.waktuSelesai}',
                                style: TextStyle(
                                  fontSize: smallFontSize,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    style: TextStyle(fontSize: bodyFontSize),
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau no telepon...',
                      hintStyle: TextStyle(fontSize: bodyFontSize),
                      prefixIcon: Icon(
                        Icons.search,
                        size: (screenWidth * 0.06).clamp(20.0, 24.0),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close,
                                size: (screenWidth * 0.05).clamp(18.0, 20.0),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                                if (_selectedDate != null) {
                                  _loadKaryawan();
                                }
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.015,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    onSubmitted: (value) {
                      if (_selectedDate != null) {
                        _loadKaryawan();
                      }
                    },
                  ),
                  SizedBox(height: screenWidth * 0.025),
                  Row(
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
                                ? 'Pilih Tanggal Shift'
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
                              _selectedKaryawan = null;
                            });
                            final provider = Provider.of<TukarShiftProvider>(
                              context,
                              listen: false,
                            );
                            provider.clearKaryawanList();
                          },
                          color: AppColors.error,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<TukarShiftProvider>(
                builder: (context, provider, child) {
                  if (_selectedDate == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search,
                            size: (screenWidth * 0.16).clamp(48.0, 64.0),
                            color: Colors.grey.shade300,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            'Pilih tanggal untuk melihat karyawan',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: bodyFontSize,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (provider.isLoadingKaryawan) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    );
                  }

                  if (provider.errorMessageKaryawan != null) {
                    return Center(
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
                              provider.errorMessageKaryawan!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: bodyFontSize,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            ElevatedButton(
                              onPressed: _loadKaryawan,
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
                    );
                  }

                  final karyawanList = provider.karyawanList;

                  if (karyawanList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search,
                            size: (screenWidth * 0.16).clamp(48.0, 64.0),
                            color: Colors.grey.shade300,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            'Tidak ada karyawan yang ditemukan',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: bodyFontSize,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    itemCount: karyawanList.length,
                    itemBuilder: (context, index) {
                      final karyawan = karyawanList[index];
                      final isSelected = _selectedKaryawan?.id == karyawan.id;
                      return _buildKaryawanCard(
                        karyawan,
                        isSelected,
                        screenWidth,
                        bodyFontSize,
                        smallFontSize,
                      );
                    },
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
                    onPressed: _proceedToReview,
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
                      'Review Permintaan',
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
            "Pilih Karyawan",
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

  Widget _buildKaryawanCard(
    KaryawanWithShift karyawan,
    bool isSelected,
    double screenWidth,
    double bodyFontSize,
    double smallFontSize,
  ) {
    final shift = karyawan.shift;

    return GestureDetector(
      onTap: () => _selectKaryawan(karyawan),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: (screenWidth * 0.135).clamp(48.0, 54.0),
                height: (screenWidth * 0.135).clamp(48.0, 54.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSelected
                        ? [
                            AppColors.primary.withOpacity(0.2),
                            AppColors.primary.withOpacity(0.1),
                          ]
                        : [Colors.grey.shade200, Colors.grey.shade100],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: isSelected ? AppColors.primary : Colors.grey.shade600,
                  size: (screenWidth * 0.07).clamp(24.0, 28.0),
                ),
              ),
              SizedBox(width: screenWidth * 0.035),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      karyawan.nama,
                      style: TextStyle(
                        fontSize: bodyFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.007),
                    Text(
                      '📞 ${karyawan.noTelp}',
                      style: TextStyle(
                        fontSize: smallFontSize,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.005),
                    Text(
                      '${karyawan.jabatan} - ${karyawan.divisi}',
                      style: TextStyle(
                        fontSize: smallFontSize,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.025),
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.025),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade50, Colors.green.shade100],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shift Tersedia:',
                            style: TextStyle(
                              fontSize: (screenWidth * 0.029).clamp(10.0, 11.0),
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.015),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.02,
                                  vertical: screenWidth * 0.01,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  'Shift ${shift.shiftCode}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: (screenWidth * 0.029).clamp(
                                      10.0,
                                      11.0,
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Expanded(
                                child: Text(
                                  '${shift.waktuMulai} - ${shift.waktuSelesai}',
                                  style: TextStyle(
                                    fontSize: smallFontSize,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: screenWidth * 0.025),
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
