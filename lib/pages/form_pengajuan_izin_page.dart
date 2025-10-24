import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../providers/izin_provider.dart';
import '../providers/presensi_provider.dart';
import '../data/models/pengajuan_izin_model.dart';
import '../core/constants/app_colors.dart';
import '../components/custom_snackbar.dart';

class FormPengajuanIzinPage extends StatefulWidget {
  const FormPengajuanIzinPage({super.key});

  @override
  State<FormPengajuanIzinPage> createState() => _FormPengajuanIzinPageState();
}

class _FormPengajuanIzinPageState extends State<FormPengajuanIzinPage> {
  final _formKey = GlobalKey<FormState>();

  KategoriIzin? _selectedKategori;
  SubKategoriCutiKhusus? _selectedSubKategori;
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  final TextEditingController _keteranganController = TextEditingController();
  File? _selectedFile;
  bool _isSubmitting = false;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final izinProvider = Provider.of<IzinProvider>(context, listen: false);

    try {
      // ✅ FIX: Await kedua API call
      await izinProvider.loadKategoriIzin();
      await izinProvider.loadSubKategoriCutiKhusus();

      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });

        // ✅ DEBUG: Print untuk verify data loaded
        debugPrint('✅ Categories loaded: ${izinProvider.kategoriList.length}');
        debugPrint(
          '✅ Sub-categories loaded: ${izinProvider.subKategoriList.length}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
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

          if (_selectedKategori?.value == 'cuti_khusus' &&
              _selectedSubKategori != null) {
            _calculateTanggalSelesai();
          } else if (_tanggalSelesai != null &&
              _tanggalSelesai!.isBefore(picked)) {
            _tanggalSelesai = null;
          }
        } else {
          _tanggalSelesai = picked;
        }
      });
    }
  }

  Future<void> _calculateTanggalSelesai() async {
    if (_tanggalMulai == null || _selectedSubKategori == null) return;

    final izinProvider = Provider.of<IzinProvider>(context, listen: false);
    final result = await izinProvider.hitungTanggalSelesai(
      tanggalMulai: _tanggalMulai!,
      subKategoriIzin: _selectedSubKategori!.value,
    );

    if (result != null && mounted) {
      setState(() {
        _tanggalSelesai = DateTime.parse(result['tanggal_selesai']);
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

  Future<void> _showKategoriDialog(double screenWidth) async {
    final izinProvider = Provider.of<IzinProvider>(context, listen: false);

    if (izinProvider.kategoriList.isEmpty) {
      CustomSnackbar.showError(context, 'Kategori izin belum dimuat');
      return;
    }

    // Responsive font sizes
    final titleFontSize = (screenWidth * 0.045).clamp(16.0, 18.0);
    final labelFontSize = (screenWidth * 0.04).clamp(14.0, 16.0);
    final descFontSize = (screenWidth * 0.033).clamp(12.0, 13.0);
    final codeFontSize = (screenWidth * 0.03).clamp(11.0, 12.0);
    final sisaFontSize = (screenWidth * 0.03).clamp(11.0, 12.0);

    final selected = await showDialog<KategoriIzin>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Kategori Izin',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenWidth * 0.04),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: izinProvider.kategoriList.length,
                    itemBuilder: (context, index) {
                      final kategori = izinProvider.kategoriList[index];
                      final isSelected =
                          _selectedKategori?.value == kategori.value;

                      return Padding(
                        padding: EdgeInsets.only(bottom: screenWidth * 0.02),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(kategori),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.035),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.1)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.02,
                                        vertical: screenWidth * 0.01,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getKategoriColor(
                                          kategori.value,
                                        ).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        kategori.kode,
                                        style: TextStyle(
                                          color: _getKategoriColor(
                                            kategori.value,
                                          ),
                                          fontWeight: FontWeight.bold,
                                          fontSize: codeFontSize,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.02),
                                    Expanded(
                                      child: Text(
                                        kategori.label,
                                        style: TextStyle(
                                          fontSize: labelFontSize,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: AppColors.primary,
                                        size: (screenWidth * 0.06).clamp(
                                          20.0,
                                          24.0,
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: screenWidth * 0.02),
                                Text(
                                  kategori.deskripsi,
                                  style: TextStyle(
                                    fontSize: descFontSize,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                if (kategori.sisaCuti != null) ...[
                                  SizedBox(height: screenWidth * 0.01),
                                  Text(
                                    'Sisa: ${kategori.sisaCuti} hari',
                                    style: TextStyle(
                                      fontSize: sisaFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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
        _selectedKategori = selected;
        _selectedSubKategori = null;
        _tanggalSelesai = null;
        _selectedFile = null;
      });
    }
  }

  Future<void> _showSubKategoriDialog(double screenWidth) async {
    final izinProvider = Provider.of<IzinProvider>(context, listen: false);

    if (izinProvider.subKategoriList.isEmpty) {
      CustomSnackbar.showError(context, 'Sub kategori belum dimuat');
      return;
    }

    // Responsive font sizes
    final titleFontSize = (screenWidth * 0.045).clamp(16.0, 18.0);
    final labelFontSize = (screenWidth * 0.038).clamp(14.0, 15.0);
    final durasiLabelFontSize = (screenWidth * 0.03).clamp(11.0, 12.0);
    final durasiNumberFontSize = (screenWidth * 0.045).clamp(16.0, 18.0);

    final selected = await showDialog<SubKategoriCutiKhusus>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Jenis Cuti Khusus',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenWidth * 0.04),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: izinProvider.subKategoriList.length,
                    itemBuilder: (context, index) {
                      final subKategori = izinProvider.subKategoriList[index];
                      final isSelected =
                          _selectedSubKategori?.value == subKategori.value;

                      return Padding(
                        padding: EdgeInsets.only(bottom: screenWidth * 0.02),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(subKategori),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.035),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.1)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(screenWidth * 0.02),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${subKategori.durasiHari}',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: durasiNumberFontSize,
                                    ),
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.03),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        subKategori.label,
                                        style: TextStyle(
                                          fontSize: labelFontSize,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        '${subKategori.durasiHari} Hari',
                                        style: TextStyle(
                                          fontSize: durasiLabelFontSize,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                    size: (screenWidth * 0.06).clamp(
                                      20.0,
                                      24.0,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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
        _selectedSubKategori = selected;
      });

      if (_tanggalMulai != null) {
        await _calculateTanggalSelesai();
      }
    }
  }

  Color _getKategoriColor(String value) {
    switch (value) {
      case 'sakit':
        return AppColors.error;
      case 'izin':
        return Colors.orange;
      case 'cuti_tahunan':
        return Colors.blue;
      case 'cuti_khusus':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  bool get _isDokumenWajib {
    if (_selectedKategori == null) return false;
    return _selectedKategori!.value != 'izin';
  }

  bool get _isTanggalSelesaiEditable {
    return _selectedKategori?.value != 'cuti_khusus';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedKategori == null) {
      CustomSnackbar.showWarning(context, 'Kategori izin wajib dipilih');
      return;
    }

    if (_selectedKategori!.value == 'cuti_khusus' &&
        _selectedSubKategori == null) {
      CustomSnackbar.showWarning(context, 'Jenis cuti khusus wajib dipilih');
      return;
    }

    if (_tanggalMulai == null) {
      CustomSnackbar.showWarning(context, 'Tanggal mulai wajib dipilih');
      return;
    }

    if (_tanggalSelesai == null) {
      CustomSnackbar.showWarning(context, 'Tanggal selesai wajib dipilih');
      return;
    }

    if (_selectedKategori!.value == 'cuti_tahunan') {
      final durasiHari = _tanggalSelesai!.difference(_tanggalMulai!).inDays + 1;
      final sisaCuti = _selectedKategori!.sisaCuti ?? 0;

      if (durasiHari > sisaCuti) {
        CustomSnackbar.showError(
          context,
          'Sisa cuti tahunan Anda tidak mencukupi!\n'
          'Sisa: $sisaCuti hari, Diminta: $durasiHari hari',
        );
        return;
      }
    }

    if (_isDokumenWajib && _selectedFile == null) {
      CustomSnackbar.showWarning(
        context,
        'Dokumen pendukung wajib diupload untuk ${_selectedKategori!.label}',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final izinProvider = Provider.of<IzinProvider>(context, listen: false);

      final success = await izinProvider.ajukanIzin(
        kategoriIzin: _selectedKategori!.value,
        subKategoriIzin: _selectedSubKategori?.value,
        tanggalMulai: _tanggalMulai!,
        tanggalSelesai: _tanggalSelesai,
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
        CustomSnackbar.showSuccess(context, 'Pengajuan izin berhasil dikirim');
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        CustomSnackbar.showError(
          context,
          izinProvider.errorMessage ?? 'Gagal mengajukan izin',
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

    // Responsive sizing - adopsi dari home_page.dart
    final bool isVerySmallScreen = screenWidth < 340;
    final bool isSmallScreen = screenWidth >= 340 && screenWidth < 360;

    final padding = screenWidth * 0.05;
    final titleFontSize = (screenWidth * 0.048).clamp(16.0, 20.0);
    final labelFontSize = (screenWidth * 0.035).clamp(13.0, 14.0);
    final inputFontSize = (screenWidth * 0.037).clamp(14.0, 15.0);
    final hintFontSize = (screenWidth * 0.035).clamp(13.0, 14.0);
    final errorFontSize = (screenWidth * 0.03).clamp(11.0, 12.0);
    final buttonFontSize = (screenWidth * 0.04).clamp(15.0, 16.0);
    final backIconSize = (screenWidth * 0.045).clamp(16.0, 18.0);

    if (_isLoadingCategories) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(
                context,
                screenWidth,
                screenHeight,
                padding,
                titleFontSize,
                backIconSize,
              ),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<IzinProvider>(
      builder: (context, izinProvider, child) {
        if (izinProvider.kategoriList.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(
                    context,
                    screenWidth,
                    screenHeight,
                    padding,
                    titleFontSize,
                    backIconSize,
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.block,
                              size: (screenWidth * 0.16).clamp(56.0, 64.0),
                              color: Colors.grey.shade300,
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              'Tidak Ada Kategori Izin Tersedia',
                              style: TextStyle(
                                fontSize: (screenWidth * 0.045).clamp(
                                  16.0,
                                  18.0,
                                ),
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              'Project Anda belum mengaktifkan kategori izin apapun. Silakan hubungi admin.',
                              style: TextStyle(
                                fontSize: (screenWidth * 0.035).clamp(
                                  13.0,
                                  14.0,
                                ),
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.08,
                                  vertical: screenHeight * 0.015,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Kembali',
                                style: TextStyle(fontSize: buttonFontSize),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(
                  context,
                  screenWidth,
                  screenHeight,
                  padding,
                  titleFontSize,
                  backIconSize,
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: padding,
                        vertical: screenHeight * 0.02,
                      ),
                      children: [
                        // Kategori Izin
                        _buildSectionLabel(
                          'Kategori Izin',
                          isRequired: true,
                          labelFontSize: labelFontSize,
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        InkWell(
                          onTap: _isSubmitting
                              ? null
                              : () => _showKategoriDialog(screenWidth),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: screenHeight * 0.015,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedKategori != null
                                    ? AppColors.primary.withOpacity(0.3)
                                    : Colors.grey.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (_selectedKategori != null) ...[
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.02,
                                      vertical: screenHeight * 0.005,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getKategoriColor(
                                        _selectedKategori!.value,
                                      ).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _selectedKategori!.kode,
                                      style: TextStyle(
                                        color: _getKategoriColor(
                                          _selectedKategori!.value,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        fontSize: (screenWidth * 0.03).clamp(
                                          11.0,
                                          12.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                ],
                                Expanded(
                                  child: Text(
                                    _selectedKategori?.label ??
                                        'Pilih kategori izin',
                                    style: TextStyle(
                                      fontSize: inputFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedKategori != null
                                          ? Colors.black87
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey.shade500,
                                  size: (screenWidth * 0.06).clamp(20.0, 24.0),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_selectedKategori == null)
                          Padding(
                            padding: EdgeInsets.only(
                              top: screenHeight * 0.006,
                              left: screenWidth * 0.01,
                            ),
                            child: Text(
                              'Kategori izin wajib dipilih',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: errorFontSize,
                              ),
                            ),
                          ),

                        // Sub Kategori (only for cuti khusus)
                        if (_selectedKategori?.value == 'cuti_khusus') ...[
                          SizedBox(height: screenHeight * 0.024),
                          _buildSectionLabel(
                            'Jenis Cuti Khusus',
                            isRequired: true,
                            labelFontSize: labelFontSize,
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          InkWell(
                            onTap: _isSubmitting
                                ? null
                                : () => _showSubKategoriDialog(screenWidth),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                                vertical: screenHeight * 0.015,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedSubKategori != null
                                      ? AppColors.primary.withOpacity(0.3)
                                      : Colors.grey.shade200,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (_selectedSubKategori != null) ...[
                                    Container(
                                      padding: EdgeInsets.all(
                                        screenWidth * 0.015,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${_selectedSubKategori!.durasiHari}',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: (screenWidth * 0.035).clamp(
                                            13.0,
                                            14.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.02),
                                  ],
                                  Expanded(
                                    child: Text(
                                      _selectedSubKategori?.label ??
                                          'Pilih jenis cuti khusus',
                                      style: TextStyle(
                                        fontSize: inputFontSize,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedSubKategori != null
                                            ? Colors.black87
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey.shade500,
                                    size: (screenWidth * 0.06).clamp(
                                      20.0,
                                      24.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_selectedKategori?.value == 'cuti_khusus' &&
                              _selectedSubKategori == null)
                            Padding(
                              padding: EdgeInsets.only(
                                top: screenHeight * 0.006,
                                left: screenWidth * 0.01,
                              ),
                              child: Text(
                                'Jenis cuti khusus wajib dipilih',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: errorFontSize,
                                ),
                              ),
                            ),
                        ],

                        SizedBox(height: screenHeight * 0.024),

                        // Tanggal Mulai
                        _buildSectionLabel(
                          'Mulai Dari',
                          isRequired: true,
                          labelFontSize: labelFontSize,
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        InkWell(
                          onTap: _isSubmitting ? null : () => _pickDate(true),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: screenHeight * 0.015,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _tanggalMulai != null
                                    ? AppColors.primary.withOpacity(0.3)
                                    : Colors.grey.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: _tanggalMulai != null
                                      ? AppColors.primary
                                      : Colors.grey.shade600,
                                  size: (screenWidth * 0.05).clamp(18.0, 20.0),
                                ),
                                SizedBox(width: screenWidth * 0.03),
                                Expanded(
                                  child: Text(
                                    _tanggalMulai == null
                                        ? 'Pilih tanggal'
                                        : DateFormat(
                                            'dd MMMM yyyy',
                                            'id_ID',
                                          ).format(_tanggalMulai!),
                                    style: TextStyle(
                                      fontSize: inputFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: _tanggalMulai == null
                                          ? Colors.grey.shade600
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.024),

                        // Tanggal Selesai
                        _buildSectionLabel(
                          'Sampai',
                          isRequired: true,
                          labelFontSize: labelFontSize,
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        InkWell(
                          onTap: (_isSubmitting || !_isTanggalSelesaiEditable)
                              ? null
                              : () => _pickDate(false),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: screenHeight * 0.015,
                            ),
                            decoration: BoxDecoration(
                              color: _isTanggalSelesaiEditable
                                  ? Colors.grey.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _tanggalSelesai != null
                                    ? AppColors.primary.withOpacity(0.3)
                                    : Colors.grey.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.event_outlined,
                                  color: _tanggalSelesai != null
                                      ? AppColors.primary
                                      : Colors.grey.shade600,
                                  size: (screenWidth * 0.05).clamp(18.0, 20.0),
                                ),
                                SizedBox(width: screenWidth * 0.03),
                                Expanded(
                                  child: Text(
                                    _tanggalSelesai == null
                                        ? 'Pilih tanggal'
                                        : DateFormat(
                                            'dd MMMM yyyy',
                                            'id_ID',
                                          ).format(_tanggalSelesai!),
                                    style: TextStyle(
                                      fontSize: inputFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: _tanggalSelesai == null
                                          ? Colors.grey.shade600
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                if (!_isTanggalSelesaiEditable)
                                  Icon(
                                    Icons.lock_outline,
                                    size: (screenWidth * 0.045).clamp(
                                      16.0,
                                      18.0,
                                    ),
                                    color: Colors.grey.shade500,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (!_isTanggalSelesaiEditable)
                          Padding(
                            padding: EdgeInsets.only(
                              top: screenHeight * 0.006,
                              left: screenWidth * 0.01,
                            ),
                            child: Text(
                              'Tanggal selesai otomatis berdasarkan jenis cuti khusus',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: errorFontSize,
                              ),
                            ),
                          ),

                        // Durasi
                        if (_tanggalMulai != null &&
                            _tanggalSelesai != null) ...[
                          SizedBox(height: screenHeight * 0.012),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: screenHeight * 0.012,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: (screenWidth * 0.045).clamp(16.0, 18.0),
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Expanded(
                                  child: Text(
                                    'Durasi: ${_tanggalSelesai!.difference(_tanggalMulai!).inDays + 1} hari',
                                    style: TextStyle(
                                      fontSize: (screenWidth * 0.035).clamp(
                                        13.0,
                                        14.0,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: screenHeight * 0.024),

                        // Keterangan
                        _buildSectionLabel(
                          'Keterangan',
                          isRequired: false,
                          labelFontSize: labelFontSize,
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        TextFormField(
                          controller: _keteranganController,
                          enabled: !_isSubmitting,
                          maxLines: 3,
                          maxLength: 1000,
                          decoration: InputDecoration(
                            hintText: 'Jelaskan alasan pengajuan izin Anda',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: hintFontSize,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.all(screenWidth * 0.035),
                          ),
                          style: TextStyle(fontSize: inputFontSize),
                        ),
                        SizedBox(height: screenHeight * 0.024),

                        // Upload File
                        _buildSectionLabel(
                          'Dokumen Pendukung (PDF/JPG/PNG)',
                          isRequired: _isDokumenWajib,
                          labelFontSize: labelFontSize,
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        if (_selectedFile == null)
                          InkWell(
                            onTap: _isSubmitting ? null : _pickFile,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.03,
                                horizontal: screenWidth * 0.04,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _isDokumenWajib
                                      ? AppColors.primary.withOpacity(0.3)
                                      : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.shade50,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    size: (screenWidth * 0.11).clamp(
                                      38.0,
                                      44.0,
                                    ),
                                    color: AppColors.primary.withOpacity(0.5),
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  Text(
                                    'Tap untuk upload file',
                                    style: TextStyle(
                                      fontSize: (screenWidth * 0.035).clamp(
                                        13.0,
                                        14.0,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.002),
                                  Text(
                                    _isDokumenWajib
                                        ? 'Wajib (Maksimal 10MB)'
                                        : 'Opsional (Maksimal 10MB)',
                                    style: TextStyle(
                                      fontSize: errorFontSize,
                                      color: _isDokumenWajib
                                          ? AppColors.primary
                                          : Colors.grey.shade600,
                                      fontWeight: _isDokumenWajib
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: EdgeInsets.all(screenWidth * 0.03),
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
                                  size: (screenWidth * 0.07).clamp(24.0, 28.0),
                                ),
                                SizedBox(width: screenWidth * 0.03),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedFile!.path.split('/').last,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: (screenWidth * 0.035).clamp(
                                            13.0,
                                            14.0,
                                          ),
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
                                                fontSize: errorFontSize,
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
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: AppColors.error,
                                    size: (screenWidth * 0.06).clamp(
                                      20.0,
                                      24.0,
                                    ),
                                  ),
                                  onPressed: _isSubmitting ? null : _removeFile,
                                  padding: EdgeInsets.all(screenWidth * 0.02),
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),

                        if (_isDokumenWajib && _selectedFile == null)
                          Padding(
                            padding: EdgeInsets.only(
                              top: screenHeight * 0.006,
                              left: screenWidth * 0.01,
                            ),
                            child: Text(
                              'Dokumen pendukung wajib diupload untuk ${_selectedKategori?.label}',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: errorFontSize,
                              ),
                            ),
                          ),

                        SizedBox(height: screenHeight * 0.032),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: Size(
                              double.infinity,
                              screenHeight * 0.06,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  height: (screenWidth * 0.05).clamp(
                                    18.0,
                                    20.0,
                                  ),
                                  width: (screenWidth * 0.05).clamp(18.0, 20.0),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'AJUKAN IZIN',
                                  style: TextStyle(
                                    fontSize: buttonFontSize,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    double padding,
    double titleFontSize,
    double backIconSize,
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
              width: (screenWidth * 0.1).clamp(36.0, 42.0),
              height: (screenWidth * 0.1).clamp(36.0, 42.0),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: backIconSize,
                color: Colors.black87,
              ),
            ),
          ),
          const Spacer(),
          Text(
            "Pengajuan Izin",
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          SizedBox(width: (screenWidth * 0.1).clamp(36.0, 42.0)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(
    String label, {
    required bool isRequired,
    required double labelFontSize,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: labelFontSize,
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
