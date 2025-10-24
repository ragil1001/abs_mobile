import '../models/tukar_shift_model.dart';
import '../services/dio_service.dart';

class TukarShiftRepository {
  final DioService _dioService = DioService();

  /// Get daftar permintaan tukar shift
  Future<List<TukarShiftRequest>> getTukarShiftRequests({
    String? status,
    String? jenis,
    String? startDate,
    String? endDate,
  }) async {
    try {
      String endpoint = '/mobile/tukar-shift?';

      if (status != null && status != 'all') {
        endpoint += 'status=$status&';
      }

      if (jenis != null && jenis != 'all') {
        final jenisParam = jenis == 'Permintaan Saya'
            ? 'saya'
            : jenis == 'Permintaan Orang Lain'
            ? 'orang_lain'
            : jenis;
        endpoint += 'jenis=$jenisParam&';
      }

      if (startDate != null && endDate != null) {
        endpoint += 'start_date=$startDate&end_date=$endDate&';
      }

      final response = await _dioService.get(endpoint);

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((item) => TukarShiftRequest.fromJson(item)).toList();
      } else {
        throw ApiException(
          response['message'] ?? 'Gagal mengambil daftar permintaan',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get detail permintaan
  Future<TukarShiftRequest> getDetailTukarShift(int id) async {
    try {
      final response = await _dioService.get('/mobile/tukar-shift/$id');

      if (response['success'] == true) {
        return TukarShiftRequest.fromJson(response['data']);
      } else {
        throw ApiException(response['message'] ?? 'Gagal mengambil detail');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get jadwal shift available untuk ditukar
  Future<List<JadwalShift>> getAvailableShifts({
    String? startDate,
    String? endDate,
  }) async {
    try {
      String endpoint = '/mobile/tukar-shift/jadwal/available?';

      if (startDate != null && endDate != null) {
        endpoint += 'start_date=$startDate&end_date=$endDate';
      }

      final response = await _dioService.get(endpoint);

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((item) => JadwalShift.fromJson(item)).toList();
      } else {
        throw ApiException(response['message'] ?? 'Gagal mengambil jadwal');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get karyawan dengan shift di tanggal tertentu
  Future<List<KaryawanWithShift>> getKaryawanWithShift({
    required String tanggal,
    String? search,
  }) async {
    try {
      String endpoint =
          '/mobile/tukar-shift/karyawan/with-shift?tanggal=$tanggal';

      if (search != null && search.isNotEmpty) {
        endpoint += '&search=$search';
      }

      final response = await _dioService.get(endpoint);

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((item) => KaryawanWithShift.fromJson(item)).toList();
      } else {
        throw ApiException(
          response['message'] ?? 'Gagal mengambil daftar karyawan',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Ajukan tukar shift
  Future<void> submitTukarShift({
    required int jadwalPemintaId,
    required int jadwalTargetId,
    String? catatan,
  }) async {
    try {
      final response = await _dioService.post('/mobile/tukar-shift', {
        'jadwal_peminta_id': jadwalPemintaId,
        'jadwal_target_id': jadwalTargetId,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      });

      if (response['success'] != true) {
        throw ApiException(
          response['message'] ?? 'Gagal mengajukan tukar shift',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Proses tukar shift (setujui/tolak)
  Future<void> prosesTukarShift({
    required int id,
    required String action, // 'setujui' atau 'tolak'
    String? alasanPenolakan,
  }) async {
    try {
      final response = await _dioService
          .post('/mobile/tukar-shift/$id/proses', {
            'action': action,
            if (alasanPenolakan != null && alasanPenolakan.isNotEmpty)
              'alasan_penolakan': alasanPenolakan,
          });

      if (response['success'] != true) {
        throw ApiException(response['message'] ?? 'Gagal memproses permintaan');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Batalkan tukar shift
  Future<void> cancelTukarShift(int id) async {
    try {
      final response = await _dioService.post(
        '/mobile/tukar-shift/$id/cancel',
        {},
      );

      if (response['success'] != true) {
        throw ApiException(
          response['message'] ?? 'Gagal membatalkan permintaan',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
