import '../models/presensi_model.dart';
import '../services/api_service.dart';

class PresensiRepository {
  final ApiService _apiService = ApiService();

  /// Get data presensi untuk homepage
  Future<PresensiData> getPresensiData() async {
    try {
      final response = await _apiService.get('/mobile/presensi/data');

      if (response['success'] == true) {
        return PresensiData.fromJson(response['data']);
      } else {
        throw ApiException(response['message'] ?? 'Gagal mengambil data');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get statistik periode untuk data absensi page
  Future<StatistikPeriode> getStatistikPeriode(String bulan) async {
    try {
      final response = await _apiService.get(
        '/mobile/presensi/statistik-periode?bulan=$bulan',
      );

      if (response['success'] == true) {
        return StatistikPeriode.fromJson(response['data']);
      } else {
        throw ApiException(response['message'] ?? 'Gagal mengambil statistik');
      }
    } catch (e) {
      rethrow;
    }
  }
}
