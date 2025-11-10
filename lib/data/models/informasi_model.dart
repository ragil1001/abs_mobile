// lib/data/models/informasi_model.dart
class InformasiModel {
  final int id;
  final int informasiId;
  final String judul;
  final String konten;
  final String kontenPreview;
  final bool hasFile;
  final String? fileName;
  final String? fileType;
  final String? fileUrl;
  final String? fileSizeFormatted;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? dikirimAt;
  final String timeAgo;
  final String createdBy;
  final DateTime createdAt;

  InformasiModel({
    required this.id,
    required this.informasiId,
    required this.judul,
    required this.konten,
    required this.kontenPreview,
    required this.hasFile,
    this.fileName,
    this.fileType,
    this.fileUrl,
    this.fileSizeFormatted,
    required this.isRead,
    this.readAt,
    this.dikirimAt,
    required this.timeAgo,
    required this.createdBy,
    required this.createdAt,
  });

  factory InformasiModel.fromJson(Map<String, dynamic> json) {
    return InformasiModel(
      id: json['id'],
      informasiId: json['informasi_id'],
      judul: json['judul'] ?? '',
      konten: json['konten'] ?? '',
      kontenPreview: json['konten_preview'] ?? '',
      hasFile: json['has_file'] ?? false,
      fileName: json['file_name'],
      fileType: json['file_type'],
      fileUrl: json['file_url'], // ✅ Now can be null
      fileSizeFormatted: json['file_size_formatted'],
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      dikirimAt: json['dikirim_at'] != null
          ? DateTime.parse(json['dikirim_at'])
          : null,
      timeAgo: json['time_ago'] ?? '',
      createdBy: json['created_by'] ?? 'System',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(), // Fallback to now if null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'informasi_id': informasiId,
      'judul': judul,
      'konten': konten,
      'konten_preview': kontenPreview,
      'has_file': hasFile,
      'file_name': fileName,
      'file_type': fileType,
      'file_url': fileUrl,
      'file_size_formatted': fileSizeFormatted,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'dikirim_at': dikirimAt?.toIso8601String(),
      'time_ago': timeAgo,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  InformasiModel copyWith({
    int? id,
    int? informasiId,
    String? judul,
    String? konten,
    String? kontenPreview,
    bool? hasFile,
    String? fileName,
    String? fileType,
    String? fileUrl,
    String? fileSizeFormatted,
    bool? isRead,
    DateTime? readAt,
    DateTime? dikirimAt,
    String? timeAgo,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return InformasiModel(
      id: id ?? this.id,
      informasiId: informasiId ?? this.informasiId,
      judul: judul ?? this.judul,
      konten: konten ?? this.konten,
      kontenPreview: kontenPreview ?? this.kontenPreview,
      hasFile: hasFile ?? this.hasFile,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSizeFormatted: fileSizeFormatted ?? this.fileSizeFormatted,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      dikirimAt: dikirimAt ?? this.dikirimAt,
      timeAgo: timeAgo ?? this.timeAgo,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get download URL with token authorization
  String? getDownloadUrl(String? token) {
    if (fileUrl == null || token == null) return fileUrl;

    // Add token to URL for authorization
    final uri = Uri.parse(fileUrl!);
    final params = Map<String, String>.from(uri.queryParameters);
    params['token'] = token;

    return uri.replace(queryParameters: params).toString();
  }
}
