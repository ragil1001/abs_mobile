import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/tukar_shift_model.dart';

class TukarShiftDetailPage extends StatelessWidget {
  final TukarShiftRequest request;

  const TukarShiftDetailPage({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.05;
    final titleFontSize = (screenWidth * 0.048).clamp(16.0, 20.0);
    final bodyFontSize = (screenWidth * 0.036).clamp(12.0, 14.0);
    final smallFontSize = (screenWidth * 0.032).clamp(10.0, 12.0);

    final status = request.status;
    final jenis = request.jenis;
    final shiftSaya = request.shiftSaya;
    final shiftDiminta = request.shiftDiminta;
    final karyawanTujuan = request.karyawanTujuan;
    final catatan = request.catatan;
    final alasanPenolakan = request.alasanPenolakan;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Menunggu Persetujuan';
        statusIcon = Icons.hourglass_empty;
        break;
      case 'disetujui':
        statusColor = AppColors.success;
        statusText = 'Disetujui';
        statusIcon = Icons.check_circle;
        break;
      case 'ditolak':
        statusColor = AppColors.error;
        statusText = 'Ditolak';
        statusIcon = Icons.cancel;
        break;
      case 'dibatalkan':
        statusColor = Colors.grey;
        statusText = 'Dibatalkan';
        statusIcon = Icons.block;
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
        statusIcon = Icons.help;
    }

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
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(screenWidth * 0.045),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(screenWidth * 0.03),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              statusIcon,
                              color: statusColor,
                              size: (screenWidth * 0.1).clamp(36.0, 40.0),
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.03),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: (screenWidth * 0.045).clamp(15.0, 18.0),
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.015),
                          Text(
                            'Diajukan: ${DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(request.tanggalRequest)}',
                            style: TextStyle(
                              fontSize: smallFontSize,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (request.tanggalDiproses != null) ...[
                            SizedBox(height: screenWidth * 0.007),
                            Text(
                              'Diproses: ${DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(request.tanggalDiproses!)}',
                              style: TextStyle(
                                fontSize: smallFontSize,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.025),

                    // Jenis permintaan badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.035,
                        vertical: screenWidth * 0.02,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: jenis == 'saya'
                              ? [Colors.blue.shade100, Colors.blue.shade50]
                              : [Colors.purple.shade100, Colors.purple.shade50],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: jenis == 'saya'
                              ? Colors.blue.shade300
                              : Colors.purple.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            jenis == 'saya'
                                ? Icons.arrow_forward
                                : Icons.arrow_back,
                            color: jenis == 'saya'
                                ? Colors.blue.shade700
                                : Colors.purple.shade700,
                            size: (screenWidth * 0.045).clamp(16.0, 18.0),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            jenis == 'saya'
                                ? 'Permintaan Saya'
                                : 'Permintaan Masuk',
                            style: TextStyle(
                              color: jenis == 'saya'
                                  ? Colors.blue.shade700
                                  : Colors.purple.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: bodyFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.025),

                    // Karyawan tujuan
                    Text(
                      'Karyawan:',
                      style: TextStyle(
                        fontSize: bodyFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.025),
                    Container(
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
                                  karyawanTujuan.nama,
                                  style: TextStyle(
                                    fontSize: bodyFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: screenWidth * 0.007),
                                Text(
                                  '📞 ${karyawanTujuan.noTelp}',
                                  style: TextStyle(
                                    fontSize: smallFontSize,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: screenWidth * 0.005),
                                Text(
                                  '${karyawanTujuan.jabatan} - ${karyawanTujuan.divisi}',
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

                    SizedBox(height: screenHeight * 0.03),

                    // Shift exchange details
                    Text(
                      'Detail Pertukaran:',
                      style: TextStyle(
                        fontSize: bodyFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.025),

                    _buildShiftCard(
                      jenis == 'saya'
                          ? 'Shift Saya'
                          : 'Shift ${karyawanTujuan.nama}',
                      shiftSaya,
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
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.15),
                              AppColors.primary.withOpacity(0.05),
                            ],
                          ),
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

                    _buildShiftCard(
                      jenis == 'saya'
                          ? 'Shift ${karyawanTujuan.nama}'
                          : 'Shift Saya',
                      shiftDiminta,
                      Colors.green,
                      screenWidth,
                      bodyFontSize,
                      smallFontSize,
                    ),

                    SizedBox(height: screenHeight * 0.03),

                    // Catatan
                    if (catatan != null && catatan.isNotEmpty) ...[
                      Text(
                        'Catatan:',
                        style: TextStyle(
                          fontSize: bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.025),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenWidth * 0.035),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          catatan,
                          style: TextStyle(fontSize: bodyFontSize, height: 1.5),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.025),
                    ],

                    // Alasan penolakan
                    if (alasanPenolakan != null &&
                        alasanPenolakan.isNotEmpty) ...[
                      Text(
                        'Alasan Penolakan:',
                        style: TextStyle(
                          fontSize: bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.025),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenWidth * 0.035),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.error,
                              size: (screenWidth * 0.055).clamp(20.0, 22.0),
                            ),
                            SizedBox(width: screenWidth * 0.025),
                            Expanded(
                              child: Text(
                                alasanPenolakan,
                                style: TextStyle(
                                  fontSize: bodyFontSize,
                                  color: Colors.grey.shade800,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
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
            "Detail Tukar Shift",
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
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenWidth * 0.015,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: smallFontSize,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.9),
              ),
            ),
          ),
          SizedBox(height: screenWidth * 0.035),

          Container(
            padding: EdgeInsets.all(screenWidth * 0.03),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
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
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
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
                      SizedBox(height: screenWidth * 0.015),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.025,
                          vertical: screenWidth * 0.0125,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
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
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
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
                      SizedBox(height: screenWidth * 0.015),
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
                              shift.waktu ??
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
