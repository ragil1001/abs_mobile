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

  // Opsi jenis izin dengan detail
  final List<Map<String, dynamic>> _jenisIzinOptions = [
    {
      'value': 'Sakit',
      'label': 'Sakit',
      'icon': Icons.local_hospital,
      'color': Colors.red,
      'description': 'Izin karena kondisi kesehatan',
    },
    {
      'value': 'Cuti',
      'label': 'Cuti',
      'icon': Icons.beach_access,
      'color': Colors.blue,
      'description': 'Cuti tahunan atau keperluan pribadi',
    },
  ];

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
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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

  // Show custom dialog for selecting jenis izin
  Future<void> _showJenisIzinDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.category, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Pilih Jenis Izin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...(_jenisIzinOptions.map((option) {
                  final isSelected = _jenisIzin == option['value'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop(option['value']);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? option['color'].withOpacity(0.1)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? option['color']
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: option['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                option['icon'],
                                color: option['color'],
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option['label'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? option['color']
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    option['description'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: option['color'],
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _jenisIzin = selected;
      });
    }
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

      final success = await izinProvider.ajukanIzin(
        jenisIzin: _jenisIzin!,
        tanggalMulai: _tanggalMulai!,
        tanggalSelesai: _tanggalSelesai!,
        keterangan: _keteranganController.text.trim().isEmpty
            ? null
            : _keteranganController.text.trim(),
        fileDokumen: _selectedFile,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan izin berhasil dikirim'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(izinProvider.errorMessage ?? 'Gagal mengajukan izin'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
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

  // Get selected option details
  Map<String, dynamic>? get _selectedOption {
    if (_jenisIzin == null) return null;
    return _jenisIzinOptions.firstWhere(
      (option) => option['value'] == _jenisIzin,
    );
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

            // Jenis Izin - Custom Display
            const Text(
              'Jenis Izin *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _isSubmitting ? null : _showJenisIzinDialog,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedOption != null
                        ? _selectedOption!['color'].withOpacity(0.5)
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    if (_selectedOption != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _selectedOption!['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _selectedOption!['icon'],
                          color: _selectedOption!['color'],
                          size: 24,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.category,
                          color: Colors.grey.shade600,
                          size: 24,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedOption != null
                                ? _selectedOption!['label']
                                : 'Pilih jenis izin',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _selectedOption != null
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                            ),
                          ),
                          if (_selectedOption != null)
                            Text(
                              _selectedOption!['description'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
            if (_jenisIzin == null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  'Jenis izin wajib dipilih',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
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
