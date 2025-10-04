// lib/providers/izin_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/models/pengajuan_izin_model.dart';
import '../data/repositories/izin_repository.dart';
import '../data/services/api_service.dart';

enum IzinState { initial, loading, loaded, error }

class IzinProvider with ChangeNotifier {
  final IzinRepository _repository = IzinRepository();

  IzinState _state = IzinState.initial;
  List<PengajuanIzin> _izinList = [];
  String? _errorMessage;

  IzinState get state => _state;
  List<PengajuanIzin> get izinList => _izinList;
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

  /// Load pengajuan izin
  Future<void> loadPengajuan() async {
    try {
      _state = IzinState.loading;
      _errorMessage = null;
      notifyListeners();

      print('Loading pengajuan izin...');
      _izinList = await _repository.getMyPengajuan();
      print('Loaded ${_izinList.length} pengajuan');

      _state = IzinState.loaded;
      notifyListeners();
    } on ApiException catch (e) {
      print('LoadPengajuan ApiException: ${e.message}');
      _state = IzinState.error;
      _errorMessage = e.message;
      notifyListeners();
    } catch (e, stackTrace) {
      print('LoadPengajuan Error: $e');
      print('StackTrace: $stackTrace');
      _state = IzinState.error;
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Get detail pengajuan
  Future<PengajuanIzin?> getDetail(int id) async {
    try {
      print('Getting detail for izin ID: $id');
      final detail = await _repository.getDetailPengajuan(id);
      print('Detail loaded successfully');
      return detail;
    } on ApiException catch (e) {
      print('GetDetail ApiException: ${e.message}');
      _errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (e, stackTrace) {
      print('GetDetail Error: $e');
      print('StackTrace: $stackTrace');
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Ajukan izin
  Future<bool> ajukanIzin({
    required String jenisIzin,
    required DateTime tanggalMulai,
    required DateTime tanggalSelesai,
    String? keterangan,
    File? fileDokumen,
  }) async {
    try {
      _errorMessage = null;

      print('=== PROVIDER: Ajukan izin ===');
      print('Jenis: $jenisIzin from $tanggalMulai to $tanggalSelesai');

      final newIzin = await _repository.ajukanIzin(
        jenisIzin: jenisIzin,
        tanggalMulai: tanggalMulai,
        tanggalSelesai: tanggalSelesai,
        keterangan: keterangan,
        fileDokumen: fileDokumen,
      );

      print('=== PROVIDER: Izin created successfully ===');
      print('ID: ${newIzin.id}');
      print('Status: ${newIzin.status}');
      print('JenisIzin: ${newIzin.jenisIzin}');

      // Reload data to ensure consistency
      print('Reloading pengajuan list...');
      await loadPengajuan();
      print('List reloaded, total: ${_izinList.length}');

      return true;
    } on ApiException catch (e) {
      print('=== PROVIDER: AjukanIzin ApiException ===');
      print('Error: ${e.message}');
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      print('=== PROVIDER: AjukanIzin Error ===');
      print('Error: $e');
      print('Type: ${e.runtimeType}');
      print('StackTrace: $stackTrace');
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Batalkan pengajuan
  Future<bool> batalkanPengajuan(int id) async {
    try {
      _errorMessage = null;

      print('Membatalkan pengajuan ID: $id');
      await _repository.batalkanPengajuan(id);
      print('Pengajuan berhasil dibatalkan');

      // Update local list - reload data to get updated status
      await loadPengajuan();

      return true;
    } on ApiException catch (e) {
      print('BatalkanPengajuan ApiException: ${e.message}');
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      print('BatalkanPengajuan Error: $e');
      print('StackTrace: $stackTrace');
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Hapus pengajuan
  Future<bool> hapusPengajuan(int id) async {
    try {
      _errorMessage = null;

      print('Menghapus pengajuan ID: $id');
      await _repository.hapusPengajuan(id);
      print('Pengajuan berhasil dihapus');

      // Remove from list
      _izinList.removeWhere((i) => i.id == id);
      notifyListeners();

      return true;
    } on ApiException catch (e) {
      print('HapusPengajuan ApiException: ${e.message}');
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      print('HapusPengajuan Error: $e');
      print('StackTrace: $stackTrace');
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
