import '../models/jadwal_model.dart';
import '../services/dio_service.dart';

class JadwalRepository {
  final DioService _dioService = DioService();

  Future<JadwalBulan> getJadwalBulan(String bulan) async {
    try {
      print('📡 Fetching jadwal for bulan: $bulan');

      final response = await _dioService.get(
        '/mobile/jadwal/bulan?bulan=$bulan',
      );

      print('📦 API Response:');
      print('   success: ${response['success']}');
      print('   data type: ${response['data'].runtimeType}');

      if (response['data'] is List) {
        print('   data count: ${(response['data'] as List).length}');
        if ((response['data'] as List).isNotEmpty) {
          print('   first item: ${(response['data'] as List).first}');
        }
      }

      if (response['success'] == true) {
        final jadwalBulan = JadwalBulan.fromJson(response);

        print('✅ Parsed JadwalBulan:');
        print('   jadwals count: ${jadwalBulan.jadwals.length}');

        if (jadwalBulan.jadwals.isNotEmpty) {
          final firstJadwal = jadwalBulan.jadwals.first;
          print('   first jadwal:');
          print('      shiftCode: ${firstJadwal.shiftCode}');
          print('      waktuMulai: ${firstJadwal.waktuMulai}');
          print('      waktuSelesai: ${firstJadwal.waktuSelesai}');
        }

        return jadwalBulan;
      } else {
        throw ApiException(response['message'] ?? 'Gagal mengambil jadwal');
      }
    } catch (e) {
      print('❌ Error in getJadwalBulan: $e');
      rethrow;
    }
  }
}
