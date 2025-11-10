// lib/pages/form_pengajuan_lembur_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../providers/lembur_provider.dart';
import '../providers/jadwal_provider.dart';
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
  final _jamMulaiController = TextEditingController();
  final _jamSelesaiController = TextEditingController();
  final _keteranganController = TextEditingController();

  DateTime? _tanggalLembur;
  File? _selectedFile;
  bool _isSubmitting = false;
  bool _isHariLibur = false;
  bool _isCheckingJadwal = false;

  @override
  void dispose() {
    _jamMulaiController.dispose();
    _jamSelesaiController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  // Check apakah tanggal yang dipilih adalah hari libur
  Future<void> _checkIfHariLibur(DateTime tanggal) async {
    setState(() {
      _isCheckingJadwal = true;
      _isHariLibur = false;
    });

    try {
      final jadwalProvider = Provider.of<JadwalProvider>(
        context,
        listen: false,
      );

      final bulan = DateFormat('yyyy-MM').format(tanggal);

      if (jadwalProvider.jadwalBulan == null ||
          jadwalProvider.jadwalBulan!.periodInfo.bulan != bulan) {
        await jadwalProvider.loadJadwalBulan(bulan);
      }

      if (jadwalProvider.jadwalBulan != null) {
        final tanggalStr = DateFormat('yyyy-MM-dd').format(tanggal);
        final jadwal = jadwalProvider.jadwalBulan!.jadwals.firstWhere(
          (j) => j.tanggal == tanggalStr,
          orElse: () => throw Exception('Jadwal tidak ditemukan'),
        );

        setState(() {
          _isHariLibur = jadwal.isLibur;
          _isCheckingJadwal = false;
        });

        // ✅ REMOVED: Tidak lagi clear jam fields karena jam tetap diminta untuk semua hari
      } else {
        setState(() {
          _isCheckingJadwal = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCheckingJadwal = false;
      });

      CustomSnackbar.showError(
        context,
        'Gagal memeriksa jadwal: ${e.toString()}',
      );
    }
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

      await _checkIfHariLibur(picked);
    }
  }

  // Pick time menggunakan bottom sheet spinner
  Future<void> _pickTime(TextEditingController controller) async {
    int currentHour = 8;
    int currentMinute = 0;

    if (controller.text.isNotEmpty) {
      final parts = controller.text.split(':');
      currentHour = int.parse(parts[0]);
      currentMinute = int.parse(parts[1]);
    }

    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        int selectedHour = currentHour;
        int selectedMinute = currentMinute;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 320,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pilih Waktu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          child: ListWheelScrollView.useDelegate(
                            itemExtent: 50,
                            perspective: 0.005,
                            diameterRatio: 1.2,
                            physics: const FixedExtentScrollPhysics(),
                            controller: FixedExtentScrollController(
                              initialItem: selectedHour,
                            ),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                selectedHour = index;
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 24,
                              builder: (context, index) {
                                final isSelected = index == selectedHour;
                                return Center(
                                  child: Text(
                                    index.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: isSelected ? 32 : 20,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            ':',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: ListWheelScrollView.useDelegate(
                            itemExtent: 50,
                            perspective: 0.005,
                            diameterRatio: 1.2,
                            physics: const FixedExtentScrollPhysics(),
                            controller: FixedExtentScrollController(
                              initialItem: selectedMinute,
                            ),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                selectedMinute = index;
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 60,
                              builder: (context, index) {
                                final isSelected = index == selectedMinute;
                                return Center(
                                  child: Text(
                                    index.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: isSelected ? 32 : 20,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, {
                              'hour': selectedHour,
                              'minute': selectedMinute,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'OK',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        final formattedTime =
            '${result['hour'].toString().padLeft(2, '0')}:${result['minute'].toString().padLeft(2, '0')}';
        controller.text = formattedTime;
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

    if (_jamMulaiController.text.isEmpty) {
      CustomSnackbar.showWarning(context, 'Jam mulai wajib diisi');
      return;
    }

    if (_jamSelesaiController.text.isEmpty) {
      CustomSnackbar.showWarning(context, 'Jam selesai wajib diisi');
      return;
    }

    final jamMulai = TimeOfDay(
      hour: int.parse(_jamMulaiController.text.split(':')[0]),
      minute: int.parse(_jamMulaiController.text.split(':')[1]),
    );
    final jamSelesai = TimeOfDay(
      hour: int.parse(_jamSelesaiController.text.split(':')[0]),
      minute: int.parse(_jamSelesaiController.text.split(':')[1]),
    );

    final mulaiMinutes = jamMulai.hour * 60 + jamMulai.minute;
    final selesaiMinutes = jamSelesai.hour * 60 + jamSelesai.minute;

    if (selesaiMinutes <= mulaiMinutes) {
      CustomSnackbar.showWarning(
        context,
        'Jam selesai harus lebih besar dari jam mulai',
      );
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
        jamMulai: _jamMulaiController.text,
        jamSelesai: _jamSelesaiController.text,
        keterangan: _keteranganController.text.isNotEmpty
            ? _keteranganController.text
            : null,
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
                    _buildInfoCard(),
                    const SizedBox(height: 24),
                    _buildTanggalSection(),
                    const SizedBox(height: 24),

                    _buildJamSection(),
                    const SizedBox(height: 24),

                    _buildFileSection(),
                    const SizedBox(height: 24),
                    _buildKeteranganSection(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
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

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.deepPurple, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ajukan lembur dengan melampirkan Surat Keterangan Lembur (SKL) dan mengisi jam kerja lembur',
              style: TextStyle(
                fontSize: 13,
                color: Colors.deepPurple.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTanggalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Tanggal Lembur', isRequired: true),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isSubmitting || _isCheckingJadwal ? null : _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  child: _isCheckingJadwal
                      ? Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Memeriksa jadwal...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        )
                      : Text(
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
                if (_tanggalLembur != null &&
                    _isHariLibur &&
                    !_isCheckingJadwal)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Text(
                      'HARI LIBUR',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
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
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
      ],
    );
  }

  // ✅ UPDATED: Section untuk jam (TANPA kondisi hari libur)
  Widget _buildJamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ UPDATED: Info card yang berlaku untuk semua hari
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Jam kerja lembur wajib diisi untuk keperluan perhitungan',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Jam Mulai', isRequired: true),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _isSubmitting
                        ? null
                        : () => _pickTime(_jamMulaiController),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _jamMulaiController.text.isNotEmpty
                              ? AppColors.primary.withOpacity(0.3)
                              : Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 20,
                            color: _jamMulaiController.text.isNotEmpty
                                ? AppColors.primary
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _jamMulaiController.text.isEmpty
                                  ? 'HH:MM'
                                  : _jamMulaiController.text,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _jamMulaiController.text.isEmpty
                                    ? Colors.grey.shade600
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Jam Selesai', isRequired: true),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _isSubmitting
                        ? null
                        : () => _pickTime(_jamSelesaiController),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _jamSelesaiController.text.isNotEmpty
                              ? AppColors.primary.withOpacity(0.3)
                              : Colors.grey.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 20,
                            color: _jamSelesaiController.text.isNotEmpty
                                ? AppColors.primary
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _jamSelesaiController.text.isEmpty
                                  ? 'HH:MM'
                                  : _jamSelesaiController.text,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _jamSelesaiController.text.isEmpty
                                    ? Colors.grey.shade600
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeteranganSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Keterangan', isRequired: false),
        const SizedBox(height: 8),
        TextFormField(
          controller: _keteranganController,
          enabled: !_isSubmitting,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Tambahkan keterangan (opsional)',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
          'Upload Surat Keterangan Lembur (SKL)',
          isRequired: true,
        ),
        const SizedBox(height: 8),
        if (_selectedFile == null)
          InkWell(
            onTap: _isSubmitting ? null : _pickFile,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                            final sizeInMB = snapshot.data! / (1024 * 1024);
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
                  icon: const Icon(Icons.close_rounded, color: AppColors.error),
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
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting || _isCheckingJadwal ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              'AJUKAN LEMBUR',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
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
