import 'package:flutter/foundation.dart';
import '../data/models/jadwal_model.dart';
import '../data/repositories/jadwal_repository.dart';
import '../data/services/dio_service.dart';

class JadwalProvider with ChangeNotifier {
  final JadwalRepository _jadwalRepository = JadwalRepository();

  JadwalBulan? _jadwalBulan;
  bool _isLoading = false;
  String? _errorMessage;

  JadwalBulan? get jadwalBulan => _jadwalBulan;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadJadwalBulan(String bulan) async {
    try {
      _isLoading = true;
      _errorMessage = null;

      // âœ… CLEAR OLD DATA FIRST
      _jadwalBulan = null;

      notifyListeners();

      _jadwalBulan = await _jadwalRepository.getJadwalBulan(bulan);
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

  Future<void> refreshJadwalBulan(String bulan) async {
    await loadJadwalBulan(bulan);
  }

  /// âœ… TAMBAHKAN METHOD CLEAR
  void clear() {
    _jadwalBulan = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
