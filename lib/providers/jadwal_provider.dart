import 'package:flutter/foundation.dart';
import '../data/models/jadwal_model.dart';
import '../data/repositories/jadwal_repository.dart';
import '../data/services/api_service.dart';

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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
