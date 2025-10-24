// lib/providers/lembur_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/models/pengajuan_lembur_model.dart';
import '../data/repositories/lembur_repository.dart';
import '../data/services/dio_service.dart';

enum LemburState { initial, loading, loaded, error }

class LemburProvider with ChangeNotifier {
  final LemburRepository _repository = LemburRepository();

  LemburState _state = LemburState.initial;
  List<PengajuanLembur> _lemburList = [];
  String? _errorMessage;

  LemburState get state => _state;
  List<PengajuanLembur> get lemburList => _lemburList;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == LemburState.loading;

  // Filtered lists
  List<PengajuanLembur> get pengajuanList =>
      _lemburList.where((l) => l.isPending).toList();

  List<PengajuanLembur> get disetujuiList =>
      _lemburList.where((l) => l.isDisetujui).toList();

  List<PengajuanLembur> get ditolakList =>
      _lemburList.where((l) => l.isDitolak).toList();

  List<PengajuanLembur> get dibatalkanList =>
      _lemburList.where((l) => l.isDibatalkan).toList();

  /// Load pengajuan lembur
  Future<void> loadPengajuan() async {
    try {
      _state = LemburState.loading;
      _errorMessage = null;

      // ✅ CLEAR OLD DATA FIRST
      _lemburList.clear();

      notifyListeners();

      _lemburList = await _repository.getMyPengajuan();

      _state = LemburState.loaded;
      notifyListeners();
    } on ApiException catch (e) {
      _state = LemburState.error;
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _state = LemburState.error;
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
    }
  }

  void clear() {
    _lemburList.clear();
    _errorMessage = null;
    _state = LemburState.initial;
    notifyListeners();
  }

  /// Get detail pengajuan
  Future<PengajuanLembur?> getDetail(int id) async {
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

  /// Ajukan lembur
  Future<bool> ajukanLembur({
    required DateTime tanggal,
    required File fileSkl,
  }) async {
    try {
      _errorMessage = null;

      final newLembur = await _repository.ajukanLembur(
        tanggal: tanggal,
        fileSkl: fileSkl,
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

      _lemburList.removeWhere((l) => l.id == id);
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
