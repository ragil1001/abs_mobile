// lib/pages/form_pengajuan_izin_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../providers/izin_provider.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_colors.dart';

class FormPengajuanIzinPage extends StatefulWidget {
  const FormPengajuanIzinPage({super.key});

  @override
  State<FormPengajuanIzinPage> createState() => _FormPengajuanIzinPageState();
}

class _FormPengajuanIzinPageState extends State<FormPengajuanIzinPage> {
  final _formKey = GlobalKey<FormState>();
  String? _jenisIzin;
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  final TextEditingController _keteranganController = TextEditingController();
  File? _selectedFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isMulai) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isMulai
          ? (_tanggalMulai ?? DateTime.now())
          : (_tanggalSelesai ?? _tanggalMulai ?? DateTime.now()),
      // Tanggal bebas - tidak ada batasan firstDate dan lastDate yang strict
      firstDate: DateTime(2020), // Bisa disesuaikan dengan kebutuhan
      lastDate: DateTime(2030), // Bisa disesuaikan dengan kebutuhan
      helpText: isMulai ? 'Pilih Tanggal Mulai' : 'Pilih Tanggal Selesai',
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
        if (isMulai) {
          _tanggalMulai = picked;
          // Reset tanggal selesai jika kurang dari tanggal mulai
          if (_tanggalSelesai != null && _tanggalSelesai!.isBefore(picked)) {
            _tanggalSelesai = null;
          }
        } else {
          _tanggalSelesai = picked;
        }
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        // Check file size (max 10MB)
        if (fileSize > 10 * 1024 * 1024) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ukuran file maksimal 10MB'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        setState(() {
          _selectedFile = file;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih file: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
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

    if (_tanggalMulai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal mulai wajib dipilih'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_tanggalSelesai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal selesai wajib dipilih'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final izinProvider = Provider.of<IzinProvider>(context, listen: false);

      print('=== FORM SUBMIT ===');
      print('Submitting izin...');
      print('Jenis: $_jenisIzin');
      print('Mulai: $_tanggalMulai');
      print('Selesai: $_tanggalSelesai');
      print('Keterangan: ${_keteranganController.text}');
      print('File: ${_selectedFile?.path}');

      final success = await izinProvider.ajukanIzin(
        jenisIzin: _jenisIzin!,
        tanggalMulai: _tanggalMulai!,
        tanggalSelesai: _tanggalSelesai!,
        keterangan: _keteranganController.text.trim().isEmpty
            ? null
            : _keteranganController.text.trim(),
        fileDokumen: _selectedFile,
      );

      print('Submit result: $success');

      if (!mounted) {
        print('Widget not mounted, returning');
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        print('Success! Showing snackbar and navigating back...');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan izin berhasil dikirim'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );

        // Wait a bit before popping to show the success message
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        // Navigate back with success result
        Navigator.pop(context, true);
      } else {
        print('Failed! Error: ${izinProvider.errorMessage}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(izinProvider.errorMessage ?? 'Gagal mengajukan izin'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('=== SUBMIT ERROR CAUGHT ===');
      print('Submit error: $e');
      print('StackTrace: $stackTrace');

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Izin'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pastikan tanggal yang dipilih ada dalam jadwal kerja Anda',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Jenis Izin
            DropdownButtonFormField<String>(
              value: _jenisIzin,
              decoration: InputDecoration(
                labelText: 'Jenis Izin *',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              items: const [
                DropdownMenuItem(value: 'Izin', child: Text('Izin')),
                DropdownMenuItem(value: 'Sakit', child: Text('Sakit')),
              ],
              onChanged: _isSubmitting
                  ? null
                  : (val) {
                      setState(() => _jenisIzin = val);
                    },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jenis izin wajib dipilih';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Tanggal Mulai
            InkWell(
              onTap: _isSubmitting ? null : () => _pickDate(true),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Mulai Dari *',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                child: Text(
                  _tanggalMulai == null
                      ? 'Pilih tanggal'
                      : DateFormat(
                          'dd MMMM yyyy',
                          'id_ID',
                        ).format(_tanggalMulai!),
                  style: TextStyle(
                    color: _tanggalMulai == null ? Colors.grey : Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tanggal Selesai
            InkWell(
              onTap: _isSubmitting ? null : () => _pickDate(false),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Sampai *',
                  prefixIcon: const Icon(Icons.event),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                child: Text(
                  _tanggalSelesai == null
                      ? 'Pilih tanggal'
                      : DateFormat(
                          'dd MMMM yyyy',
                          'id_ID',
                        ).format(_tanggalSelesai!),
                  style: TextStyle(
                    color: _tanggalSelesai == null
                        ? Colors.grey
                        : Colors.black87,
                  ),
                ),
              ),
            ),

            if (_tanggalMulai != null && _tanggalSelesai != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Durasi: ${_tanggalSelesai!.difference(_tanggalMulai!).inDays + 1} hari',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Keterangan
            TextFormField(
              controller: _keteranganController,
              enabled: !_isSubmitting,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: 'Keterangan',
                hintText: 'Jelaskan alasan pengajuan izin Anda (opsional)',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.description),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),

            // Upload File
            const Text(
              'Upload Dokumen Pendukung (PDF) - Opsional',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),

            if (_selectedFile == null)
              InkWell(
                onTap: _isSubmitting ? null : _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.upload_file,
                        size: 48,
                        color: AppColors.primary.withOpacity(0.6),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap untuk pilih file PDF',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Maksimal 10MB',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
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
                    const Icon(Icons.picture_as_pdf, color: AppColors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFile!.path.split('/').last,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          FutureBuilder<int>(
                            future: _selectedFile!.length(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final sizeInMB = snapshot.data! / (1024 * 1024);
                                return Text(
                                  '${sizeInMB.toStringAsFixed(2)} MB',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                );
                              }
                              return const Text('-');
                            },
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.error),
                      onPressed: _isSubmitting ? null : _removeFile,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'AJUKAN IZIN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
