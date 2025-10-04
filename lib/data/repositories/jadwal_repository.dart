import '../models/jadwal_model.dart';
import '../services/api_service.dart';

class JadwalRepository {
  final ApiService _apiService = ApiService();

  Future<JadwalBulan> getJadwalBulan(String bulan) async {
    try {
      final response = await _apiService.get(
        '/mobile/jadwal/bulan?bulan=$bulan',
      );

      if (response['success'] == true) {
        return JadwalBulan.fromJson(response);
      } else {
        throw ApiException(response['message'] ?? 'Gagal mengambil jadwal');
      }
    } catch (e) {
      rethrow;
    }
  }
}
