class Jabatan {
  final int id;
  final String nama;

  Jabatan({required this.id, required this.nama});

  factory Jabatan.fromJson(Map<String, dynamic> json) {
    return Jabatan(id: json['id'], nama: json['nama']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nama': nama};
  }
}
