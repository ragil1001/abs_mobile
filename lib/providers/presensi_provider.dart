import 'package:flutter/foundation.dart';
import '../data/models/presensi_model.dart';
import '../data/repositories/presensi_repository.dart';
import '../data/services/api_service.dart';

class PresensiProvider with ChangeNotifier {
  final PresensiRepository _presensiRepository = PresensiRepository();

  PresensiData? _presensiData;
  StatistikPeriode? _statistikPeriode; // TAMBAH INI
  bool _isLoading = false;
  bool _isLoadingStatistik = false; // TAMBAH INI
  String? _errorMessage;
  String? _errorMessageStatistik; // TAMBAH INI

  PresensiData? get presensiData => _presensiData;
  StatistikPeriode? get statistikPeriode => _statistikPeriode; // TAMBAH INI
  bool get isLoading => _isLoading;
  bool get isLoadingStatistik => _isLoadingStatistik; // TAMBAH INI
  String? get errorMessage => _errorMessage;
  String? get errorMessageStatistik => _errorMessageStatistik; // TAMBAH INI

  /// Load data presensi untuk homepage
  Future<void> loadPresensiData() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _presensiData = await _presensiRepository.getPresensiData();
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
