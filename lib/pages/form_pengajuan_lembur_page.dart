// lib/pages/form_pengajuan_lembur_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../providers/lembur_provider.dart';
import '../core/constants/app_colors.dart';
import '../components/custom_snackbar.dart';

class FormPengajuanLemburPage extends StatefulWidget {
  const FormPengajuanLemburPage({super.key});

  @override
  State<FormPengajuanLemburPage> createState() =>
      _FormPengajuanLemburPageState();
}

class _FormPengajuanLemburPageState extends State<FormPengajuanLemburPage> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _tanggalLembur;
  File? _selectedFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tanggalLembur ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
      helpText: 'Pilih Tanggal Lembur',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _tanggalLembur = picked;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        if (fileSize > 10 * 1024 * 1024) {
          if (!mounted) return;
          CustomSnackbar.showError(context, 'Ukuran file maksimal 10MB');
          return;
        }

        setState(() {
          _selectedFile = file;
        });
      }
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.showError(context, 'Gagal memilih file: ${e.toString()}');
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tanggalLembur == null) {
      CustomSnackbar.showWarning(context, 'Tanggal lembur wajib dipilih');
      return;
    }

    if (_selectedFile == null) {
      CustomSnackbar.showWarning(context, 'File SKL wajib diupload');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final lemburProvider = Provider.of<LemburProvider>(
        context,
        listen: false,
      );

      final success = await lemburProvider.ajukanLembur(
        tanggal: _tanggalLembur!,
        fileSkl: _selectedFile!,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        CustomSnackbar.showSuccess(
          context,
          'Pengajuan lembur berhasil dikirim',
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        CustomSnackbar.showError(
          context,
          lemburProvider.errorMessage ?? 'Gagal mengajukan lembur',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      CustomSnackbar.showError(context, 'Terjadi kesalahan: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.06;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, screenWidth, screenHeight, padding),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: padding,
                    vertical: screenHeight * 0.02,
                  ),
                  children: [
                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.deepPurple.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.deepPurple,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ajukan lembur dengan melampirkan Surat Keterangan Lembur (SKL)',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.deepPurple.shade700,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tanggal Lembur
                    _buildSectionLabel('Tanggal Lembur', isRequired: true),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _isSubmitting ? null : _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _tanggalLembur != null
                                ? AppColors.primary.withOpacity(0.3)
                                : Colors.grey.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: _tanggalLembur != null
                                  ? AppColors.primary
                                  : Colors.grey.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _tanggalLembur == null
                                    ? 'Pilih tanggal'
                                    : DateFormat(
                                        'EEEE, dd MMMM yyyy',
                                        'id_ID',
                                      ).format(_tanggalLembur!),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _tanggalLembur == null
                                      ? Colors.grey.shade600
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_tanggalLembur == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          'Tanggal lembur wajib dipilih',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Upload File SKL
                    _buildSectionLabel(
                      'Upload Surat Keterangan Lembur (SKL)',
                      isRequired: true,
                    ),
                    const SizedBox(height: 8),
                    if (_selectedFile == null)
                      InkWell(
                        onTap: _isSubmitting ? null : _pickFile,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 44,
                                color: AppColors.primary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap untuk upload file SKL',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Wajib (PDF/JPG/PNG - Maksimal 10MB)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary),
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.primary.withOpacity(0.05),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedFile!.path.endsWith('.pdf')
                                  ? Icons.picture_as_pdf_outlined
                                  : Icons.image_outlined,
                              color: _selectedFile!.path.endsWith('.pdf')
                                  ? AppColors.error
                                  : AppColors.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedFile!.path.split('/').last,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  FutureBuilder<int>(
                                    future: _selectedFile!.length(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        final sizeInMB =
                                            snapshot.data! / (1024 * 1024);
                                        return Text(
                                          '${sizeInMB.toStringAsFixed(2)} MB',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppColors.error,
                              ),
                              onPressed: _isSubmitting ? null : _removeFile,
                            ),
                          ],
                        ),
                      ),

                    if (_selectedFile == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          'File SKL wajib diupload',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'AJUKAN LEMBUR',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
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
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: screenHeight * 0.015,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: screenWidth * 0.1,
              height: screenWidth * 0.1,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: screenWidth * 0.045,
                color: Colors.black87,
              ),
            ),
          ),
          const Spacer(),
          Text(
            "Pengajuan Lembur",
            style: TextStyle(
              fontSize: screenWidth * 0.048,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          SizedBox(width: screenWidth * 0.1),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, {required bool isRequired}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }
}
