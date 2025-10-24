import 'package:flutter/foundation.dart';
import '../data/models/tukar_shift_model.dart';
import '../data/repositories/tukar_shift_repository.dart';
import '../data/services/dio_service.dart';

class TukarShiftProvider with ChangeNotifier {
  final TukarShiftRepository _repository = TukarShiftRepository();

  List<TukarShiftRequest> _requests = [];
  List<JadwalShift> _availableShifts = [];
  List<KaryawanWithShift> _karyawanList = [];

  bool _isLoading = false;
  bool _isLoadingShifts = false;
  bool _isLoadingKaryawan = false;
  bool _isSubmitting = false;

  String? _errorMessage;
  String? _errorMessageShifts;
  String? _errorMessageKaryawan;

  // Getters
  List<TukarShiftRequest> get requests => _requests;
  List<JadwalShift> get availableShifts => _availableShifts;
  List<KaryawanWithShift> get karyawanList => _karyawanList;

  bool get isLoading => _isLoading;
  bool get isLoadingShifts => _isLoadingShifts;
  bool get isLoadingKaryawan => _isLoadingKaryawan;
  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;
  String? get errorMessageShifts => _errorMessageShifts;
  String? get errorMessageKaryawan => _errorMessageKaryawan;

  /// Load daftar permintaan tukar shift
  Future<void> loadTukarShiftRequests({
    String? status,
    String? jenis,
    String? startDate,
    String? endDate,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;

      // ✅ CLEAR OLD DATA FIRST
      _requests.clear();

      notifyListeners();

      _requests = await _repository.getTukarShiftRequests(
        status: status,
        jenis: jenis,
        startDate: startDate,
        endDate: endDate,
      );

      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Load jadwal shift available
  Future<void> loadAvailableShifts({String? startDate, String? endDate}) async {
    try {
      _isLoadingShifts = true;
      _errorMessageShifts = null;

      // ✅ CLEAR OLD DATA FIRST
      _availableShifts.clear();

      notifyListeners();

      _availableShifts = await _repository.getAvailableShifts(
        startDate: startDate,
        endDate: endDate,
      );

      _isLoadingShifts = false;
      notifyListeners();
    } on ApiException catch (e) {
      _isLoadingShifts = false;
      _errorMessageShifts = e.message;
      notifyListeners();
    } catch (e) {
      _isLoadingShifts = false;
      _errorMessageShifts = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Load karyawan dengan shift di tanggal tertentu
  Future<void> loadKaryawanWithShift({
    required String tanggal,
    String? search,
  }) async {
    try {
      _isLoadingKaryawan = true;
      _errorMessageKaryawan = null;

      // ✅ CLEAR OLD DATA FIRST
      _karyawanList.clear();

      notifyListeners();

      _karyawanList = await _repository.getKaryawanWithShift(
        tanggal: tanggal,
        search: search,
      );

      _isLoadingKaryawan = false;
      notifyListeners();
    } on ApiException catch (e) {
      _isLoadingKaryawan = false;
      _errorMessageKaryawan = e.message;
      notifyListeners();
    } catch (e) {
      _isLoadingKaryawan = false;
      _errorMessageKaryawan = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
    }
  }

  /// ✅ TAMBAHKAN METHOD CLEAR
  void clear() {
    _requests.clear();
    _availableShifts.clear();
    _karyawanList.clear();
    _errorMessage = null;
    _errorMessageShifts = null;
    _errorMessageKaryawan = null;
    _isLoading = false;
    _isLoadingShifts = false;
    _isLoadingKaryawan = false;
    _isSubmitting = false;
    notifyListeners();
  }

  /// Submit tukar shift
  Future<bool> submitTukarShift({
    required int jadwalPemintaId,
    required int jadwalTargetId,
    String? catatan,
  }) async {
    try {
      _isSubmitting = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.submitTukarShift(
        jadwalPemintaId: jadwalPemintaId,
        jadwalTargetId: jadwalTargetId,
        catatan: catatan,
      );

      _isSubmitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isSubmitting = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Proses tukar shift (setujui/tolak)
  Future<bool> prosesTukarShift({
    required int id,
    required String action,
    String? alasanPenolakan,
  }) async {
    try {
      _errorMessage = null;

      await _repository.prosesTukarShift(
        id: id,
        action: action,
        alasanPenolakan: alasanPenolakan,
      );

      // Reload list after processing
      await loadTukarShiftRequests();
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

  /// Batalkan tukar shift
  Future<bool> cancelTukarShift(int id) async {
    try {
      _errorMessage = null;

      await _repository.cancelTukarShift(id);

      // Reload list after canceling
      await loadTukarShiftRequests();
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

  /// Refresh requests
  Future<void> refreshRequests({
    String? status,
    String? jenis,
    String? startDate,
    String? endDate,
  }) async {
    await loadTukarShiftRequests(
      status: status,
      jenis: jenis,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Clear errors
  void clearError() {
    _errorMessage = null;
    _errorMessageShifts = null;
    _errorMessageKaryawan = null;
    notifyListeners();
  }

  void clearAvailableShifts() {
    _availableShifts.clear();
    notifyListeners();
  }

  /// Clear karyawan list
  void clearKaryawanList() {
    _karyawanList.clear();
    notifyListeners();
  }
}
