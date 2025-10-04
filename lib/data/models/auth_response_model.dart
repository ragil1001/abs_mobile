import 'karyawan_model.dart';

class AuthResponse {
  final String token;
  final Karyawan karyawan;

  AuthResponse({required this.token, required this.karyawan});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      karyawan: Karyawan.fromJson(json['karyawan']),
    );
  }
}
