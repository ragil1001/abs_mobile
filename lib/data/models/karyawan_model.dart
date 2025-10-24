import 'divisi_model.dart';
import 'jabatan_model.dart';
import 'project_model.dart';

class Karyawan {
  final int id;
  final String nik;
  final String nama;
  final String username;
  final String noTelepon;
  final String jenisKelamin;
  final String tempatLahir;
  final String tanggalLahir;
  final String tanggalBergabung;
  final String status;
  final int sisaCutiTahunan; // NEW: Sisa cuti tahunan
  final Divisi divisi;
  final Jabatan jabatan;
  final Project? project;

  Karyawan({
    required this.id,
    required this.nik,
    required this.nama,
    required this.username,
    required this.noTelepon,
    required this.jenisKelamin,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.tanggalBergabung,
    required this.status,
    required this.sisaCutiTahunan, // NEW
    required this.divisi,
    required this.jabatan,
    this.project,
  });

  factory Karyawan.fromJson(Map<String, dynamic> json) {
    try {
      return Karyawan(
        id: json['id'] ?? 0,
        nik: json['nik'] ?? '',
        nama: json['nama'] ?? '',
        username: json['username'] ?? '',
        noTelepon: json['no_telepon'] ?? '',
        jenisKelamin: json['jenis_kelamin'] ?? '',
        tempatLahir: json['tempat_lahir'] ?? '',
        tanggalLahir: json['tanggal_lahir'] ?? '',
        tanggalBergabung: json['tanggal_bergabung'] ?? '',
        status: json['status'] ?? '',
        sisaCutiTahunan: json['sisa_cuti_tahunan'] ?? 12, // NEW: Default 12
        divisi: json['divisi'] != null
            ? Divisi.fromJson(json['divisi'] as Map<String, dynamic>)
            : Divisi(id: 0, nama: ''),
        jabatan: json['jabatan'] != null
            ? Jabatan.fromJson(json['jabatan'] as Map<String, dynamic>)
            : Jabatan(id: 0, nama: ''),
        project: json['project'] != null && json['project'] is Map
            ? Project.fromJson(json['project'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      // print('Error parsing Karyawan: $e');
      // print('JSON data: $json');
      rethrow;
    }
  }

  String get jenisKelaminText =>
      jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan';

  String get formattedTanggalLahir {
    try {
      final date = DateTime.parse(tanggalLahir);
      final months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return tanggalLahir;
    }
  }

  String get formattedTanggalBergabung {
    try {
      final date = DateTime.parse(tanggalBergabung);
      final months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return tanggalBergabung;
    }
  }

  // NEW: Helper untuk cek apakah cuti cukup
  bool isCutiTahunanCukup(int jumlahHari) {
    return sisaCutiTahunan >= jumlahHari;
  }

  // NEW: Get formatted sisa cuti
  String get formattedSisaCuti {
    return '$sisaCutiTahunan hari';
  }
}
