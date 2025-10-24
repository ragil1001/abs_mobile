import 'package:flutter/foundation.dart';
import '../data/models/presensi_model.dart';
import '../data/repositories/presensi_repository.dart';
import '../data/services/dio_service.dart';

class PresensiProvider with ChangeNotifier {
  final PresensiRepository _presensiRepository = PresensiRepository();

  PresensiData? _presensiData;
  StatistikPeriode? _statistikPeriode;
  bool _isLoading = false;
  bool _isLoadingStatistik = false;
  String? _errorMessage;
  String? _errorMessageStatistik;

  PresensiData? get presensiData => _presensiData;
  StatistikPeriode? get statistikPeriode => _statistikPeriode;
  bool get isLoading => _isLoading;
  bool get isLoadingStatistik => _isLoadingStatistik;
  String? get errorMessage => _errorMessage;
  String? get errorMessageStatistik => _errorMessageStatistik;

  // ✅ NEW: Get enabled categories from presensi data
  List<String> get enabledIzinCategories {
    return _presensiData?.enabledIzinCategories ?? [];
  }

  List<String> get enabledSubKategoriIzin {
    return _presensiData?.enabledSubKategoriIzin ?? [];
  }

  /// Load data presensi untuk homepage
  Future<void> loadPresensiData() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Clear old data before loading new
      _presensiData = null;

      _presensiData = await _presensiRepository.getPresensiData();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e is ApiException
          ? e.message
          : 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Load statistik periode untuk data absensi page
  Future<void> loadStatistikPeriode(String bulan) async {
    try {
      _isLoadingStatistik = true;
      _errorMessageStatistik = null;
      notifyListeners();

      _statistikPeriode = await _presensiRepository.getStatistikPeriode(bulan);
      _isLoadingStatistik = false;
      notifyListeners();
    } on ApiException catch (e) {
      _isLoadingStatistik = false;
      _errorMessageStatistik = e.message;
      notifyListeners();
    } catch (e) {
      _isLoadingStatistik = false;
      _errorMessageStatistik = 'Terjadi kesalahan: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Refresh data presensi
  Future<void> refreshPresensiData() async {
    await loadPresensiData();
  }

  /// Refresh statistik periode
  Future<void> refreshStatistikPeriode(String bulan) async {
    await loadStatistikPeriode(bulan);
  }

  void clearError() {
    _errorMessage = null;
    _errorMessageStatistik = null;
    notifyListeners();
  }
}
