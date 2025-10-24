// tukar_shift_review_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/tukar_shift_provider.dart';
import '../../data/models/tukar_shift_model.dart';
import '../../components/custom_snackbar.dart';

class TukarShiftReviewPage extends StatefulWidget {
  final JadwalShift shiftSaya;
  final ShiftInfo shiftDiminta;
  final KaryawanWithShift karyawanTujuan;

  const TukarShiftReviewPage({
    super.key,
    required this.shiftSaya,
    required this.shiftDiminta,
    required this.karyawanTujuan,
  });

  @override
  State<TukarShiftReviewPage> createState() => _TukarShiftReviewPageState();
}

class _TukarShiftReviewPageState extends State<TukarShiftReviewPage> {
  final TextEditingController _catatanController = TextEditingController();

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  void _showCancelConfirmation() {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleFontSize = (screenWidth * 0.045).clamp(15.0, 18.0);
    final bodyFontSize = (screenWidth * 0.036).clamp(12.0, 14.0);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Batalkan Permintaan?",
            style: TextStyle(fontSize: titleFontSize),
          ),
          content: Text(
            "Apakah Anda yakin ingin membatalkan permintaan tukar shift ini?",
            style: TextStyle(fontSize: bodyFontSize),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Tidak", style: TextStyle(fontSize: bodyFontSize)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                int count = 0;
                Navigator.popUntil(context, (route) {
                  return count++ == 3;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Ya, Batalkan",
                style: TextStyle(fontSize: bodyFontSize),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleFontSize = (screenWidth * 0.045).clamp(15.0, 18.0);
    final bodyFontSize = (screenWidth * 0.036).clamp(12.0, 14.0);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Konfirmasi Permintaan",
            style: TextStyle(fontSize: titleFontSize),
          ),
          content: Text(
            "Apakah Anda yakin ingin mengajukan permintaan tukar shift ini?",
            style: TextStyle(fontSize: bodyFontSize),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Batal", style: TextStyle(fontSize: bodyFontSize)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitRequest();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Ya, Ajukan",
                style: TextStyle(fontSize: bodyFontSize),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitRequest() async {
    final provider = Provider.of<TukarShiftProvider>(context, listen: false);

    final success = await provider.submitTukarShift(
      jadwalPemintaId: widget.shiftSaya.id,
      jadwalTargetId: widget.shiftDiminta.jadwalId,
      catatan: _catatanController.text.trim().isNotEmpty
          ? _catatanController.text.trim()
          : null,
    );

    if (!mounted) return;

    if (success) {
      CustomSnackbar.showSuccess(
        context,
        'Permintaan tukar shift berhasil diajukan',
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      int count = 0;
      Navigator.popUntil(context, (route) {
        return count++ == 3;
      });
    } else {
      CustomSnackbar.showError(
        context,
        provider.errorMessage ?? 'Gagal mengajukan permintaan',
      );
    }
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
        child: Consumer<TukarShiftProvider>(
          builder: (context, provider, child) {
            return Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(
                      context,
                      screenWidth,
                      screenHeight,
                      padding,
                      titleFontSize,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(screenWidth * 0.03),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade700,
                                    size: (screenWidth * 0.05).clamp(
                                      18.0,
                                      20.0,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Expanded(
                                    child: Text(
                                      'Periksa kembali detail tukar shift sebelum mengajukan',
                                      style: TextStyle(
                                        color: Colors.blue.shade900,
                                        fontSize: bodyFontSize,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.025),
                            Text(
                              'Tukar Shift Dengan:',
                              style: TextStyle(
                                fontSize: bodyFontSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.02),
                            _buildKaryawanCard(
                              screenWidth,
                              bodyFontSize,
                              smallFontSize,
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            Text(
                              'Detail Pertukaran:',
                              style: TextStyle(
                                fontSize: bodyFontSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.02),
                            _buildShiftCard(
                              'Shift Saya',
                              widget.shiftSaya,
                              Colors.blue,
                              screenWidth,
                              bodyFontSize,
                              smallFontSize,
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Center(
                              child: Container(
                                padding: EdgeInsets.all(screenWidth * 0.03),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.swap_vert,
                                  color: AppColors.primary,
                                  size: (screenWidth * 0.08).clamp(28.0, 32.0),
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            _buildShiftCardFromShiftInfo(
                              'Shift yang Diminta',
                              widget.shiftDiminta,
                              Colors.green,
                              screenWidth,
                              bodyFontSize,
                              smallFontSize,
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            Text(
                              'Catatan (Opsional):',
                              style: TextStyle(
                                fontSize: bodyFontSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.02),
                            TextFormField(
                              controller: _catatanController,
                              maxLines: 4,
                              maxLength: 500,
                              style: TextStyle(fontSize: bodyFontSize),
                              decoration: InputDecoration(
                                hintText:
                                    'Tambahkan catatan atau alasan tukar shift (opsional)',
                                hintStyle: TextStyle(fontSize: bodyFontSize),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (!provider.isSubmitting)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
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
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _showCancelConfirmation,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(
                                    color: AppColors.error,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.02,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Batal',
                                  style: TextStyle(
                                    fontSize: bodyFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _showConfirmationDialog,
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
                                  'Konfirmasi & Ajukan',
                                  style: TextStyle(
                                    fontSize: bodyFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (provider.isSubmitting)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth * 0.06),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Text(
                                'Mengirim permintaan...',
                                style: TextStyle(
                                  fontSize: bodyFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
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
            "Review Permintaan",
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
    double screenWidth,
    double bodyFontSize,
    double smallFontSize,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.035),
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
      child: Row(
        children: [
          Container(
            width: (screenWidth * 0.135).clamp(48.0, 54.0),
            height: (screenWidth * 0.135).clamp(48.0, 54.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: AppColors.primary,
              size: (screenWidth * 0.07).clamp(24.0, 28.0),
            ),
          ),
          SizedBox(width: screenWidth * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.karyawanTujuan.nama,
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '📞 ${widget.karyawanTujuan.noTelp}',
                  style: TextStyle(
                    fontSize: smallFontSize,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${widget.karyawanTujuan.jabatan} - ${widget.karyawanTujuan.divisi}',
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
    );
  }

  Widget _buildShiftCard(
    String label,
    JadwalShift shift,
    Color color,
    double screenWidth,
    double bodyFontSize,
    double smallFontSize,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.025,
              vertical: screenWidth * 0.01,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: smallFontSize,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          SizedBox(height: screenWidth * 0.03),
          Container(
            padding: EdgeInsets.all(screenWidth * 0.03),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: color,
                  size: (screenWidth * 0.05).clamp(18.0, 20.0),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE', 'id_ID').format(shift.tanggal),
                        style: TextStyle(
                          fontSize: bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'dd MMMM yyyy',
                          'id_ID',
                        ).format(shift.tanggal),
                        style: TextStyle(
                          fontSize: bodyFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenWidth * 0.03),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.025),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shift',
                        style: TextStyle(
                          fontSize: (screenWidth * 0.029).clamp(10.0, 11.0),
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.01),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                          vertical: screenWidth * 0.0125,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Shift ${shift.shiftCode}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: smallFontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.025),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jam Kerja',
                        style: TextStyle(
                          fontSize: (screenWidth * 0.029).clamp(10.0, 11.0),
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.01),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: color,
                            size: (screenWidth * 0.04).clamp(14.0, 16.0),
                          ),
                          SizedBox(width: screenWidth * 0.015),
                          Flexible(
                            child: Text(
                              '${shift.waktuMulai} - ${shift.waktuSelesai}',
                              style: TextStyle(
                                fontSize: bodyFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCardFromShiftInfo(
    String label,
    ShiftInfo shift,
    Color color,
    double screenWidth,
    double bodyFontSize,
    double smallFontSize,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.025,
              vertical: screenWidth * 0.01,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: smallFontSize,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          SizedBox(height: screenWidth * 0.03),
          Container(
            padding: EdgeInsets.all(screenWidth * 0.03),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: color,
                  size: (screenWidth * 0.05).clamp(18.0, 20.0),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE', 'id_ID').format(shift.tanggal),
                        style: TextStyle(
                          fontSize: bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'dd MMMM yyyy',
                          'id_ID',
                        ).format(shift.tanggal),
                        style: TextStyle(
                          fontSize: bodyFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenWidth * 0.03),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.025),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shift',
                        style: TextStyle(
                          fontSize: (screenWidth * 0.029).clamp(10.0, 11.0),
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.01),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                          vertical: screenWidth * 0.0125,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Shift ${shift.shiftCode}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: smallFontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.025),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jam Kerja',
                        style: TextStyle(
                          fontSize: (screenWidth * 0.029).clamp(10.0, 11.0),
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.01),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: color,
                            size: (screenWidth * 0.04).clamp(14.0, 16.0),
                          ),
                          SizedBox(width: screenWidth * 0.015),
                          Flexible(
                            child: Text(
                              '${shift.waktuMulai} - ${shift.waktuSelesai}',
                              style: TextStyle(
                                fontSize: bodyFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
