// lib/providers/izin_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/models/pengajuan_izin_model.dart';
import '../data/repositories/izin_repository.dart';
import '../data/services/dio_service.dart';

enum IzinState { initial, loading, loaded, error }

class IzinProvider with ChangeNotifier {
  final IzinRepository _repository = IzinRepository();

  IzinState _state = IzinState.initial;
  List<PengajuanIzin> _izinList = [];
  List<KategoriIzin> _kategoriList = [];
  List<SubKategoriCutiKhusus> _subKategoriList = [];
  String? _errorMessage;

  IzinState get state => _state;
  List<PengajuanIzin> get izinList => _izinList;
  List<KategoriIzin> get kategoriList => _kategoriList;
  List<SubKategoriCutiKhusus> get subKategoriList => _subKategoriList;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == IzinState.loading;

  // Filtered lists
  List<PengajuanIzin> get pengajuanList =>
      _izinList.where((i) => i.isPending).toList();

  List<PengajuanIzin> get disetujuiList =>
      _izinList.where((i) => i.isDisetujui).toList();

  List<PengajuanIzin> get ditolakList =>
      _izinList.where((i) => i.isDitolak).toList();

  List<PengajuanIzin> get dibatalkanList =>
      _izinList.where((i) => i.isDibatalkan).toList();

  Future<void> loadKategoriIzin() async {
    try {
      _kategoriList.clear();

      // ✅ Tidak perlu parameter, backend sudah filter by project
      _kategoriList = await _repository.getKategoriIzinList();
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> loadSubKategoriCutiKhusus() async {
    try {
      _subKategoriList.clear();

      // ✅ Tidak perlu parameter, backend sudah filter by project
      _subKategoriList = await _repository.getSubKategoriCutiKhususList();
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Hitung tanggal selesai otomatis
  Future<Map<String, dynamic>?> hitungTanggalSelesai({
    required DateTime tanggalMulai,
    required String subKategoriIzin,
  }) async {
    try {
      return await _repository.hitungTanggalSelesai(
        tanggalMulai: tanggalMulai,
        subKategoriIzin: subKategoriIzin,
      );
    } catch (e) {
      return null;
    }
  }

  void clear() {
    _izinList.clear();
    _kategoriList.clear();
    _subKategoriList.clear();
    _errorMessage = null;
    _state = IzinState.initial;
    notifyListeners();
  }

  /// Load pengajuan izin
  Future<void> loadPengajuan() async {
    try {
      _state = IzinState.loading;
      _errorMessage = null;

      // Clear old data first
      _izinList.clear();

      notifyListeners();

      _izinList = await _repository.getMyPengajuan();

      _state = IzinState.loaded;
      notifyListeners();
    } on ApiException catch (e) {
      _state = IzinState.error;
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _state = IzinState.error;
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Get detail pengajuan
  Future<PengajuanIzin?> getDetail(int id) async {
    try {
      final detail = await _repository.getDetailPengajuan(id);
      return detail;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Ajukan izin dengan kategori lengkap
  Future<bool> ajukanIzin({
    required String kategoriIzin,
    String? subKategoriIzin,
    String? deskripsiIzin,
    required DateTime tanggalMulai,
    DateTime? tanggalSelesai,
    String? keterangan,
    File? fileDokumen,
  }) async {
    try {
      _errorMessage = null;

      final newIzin = await _repository.ajukanIzin(
        kategoriIzin: kategoriIzin,
        subKategoriIzin: subKategoriIzin,
        deskripsiIzin: deskripsiIzin,
        tanggalMulai: tanggalMulai,
        tanggalSelesai: tanggalSelesai,
        keterangan: keterangan,
        fileDokumen: fileDokumen,
      );

      // Reload data to ensure consistency
      await loadPengajuan();

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Batalkan pengajuan
  Future<bool> batalkanPengajuan(int id) async {
    try {
      _errorMessage = null;

      await _repository.batalkanPengajuan(id);

      await loadPengajuan();

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Hapus pengajuan
  Future<bool> hapusPengajuan(int id) async {
    try {
      _errorMessage = null;

      await _repository.hapusPengajuan(id);

      _izinList.removeWhere((i) => i.id == id);
      notifyListeners();

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
