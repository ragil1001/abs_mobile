// lib/pages/pengajuan_izin_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/izin_provider.dart';
import '../core/constants/app_colors.dart';
import 'form_pengajuan_izin_page.dart';
import 'detail_izin_page.dart';

class PengajuanIzinPage extends StatefulWidget {
  const PengajuanIzinPage({super.key});

  @override
  State<PengajuanIzinPage> createState() => _PengajuanIzinPageState();
}

class _PengajuanIzinPageState extends State<PengajuanIzinPage> {
  String _filterTab = "Semua";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final izinProvider = Provider.of<IzinProvider>(context, listen: false);
    await izinProvider.loadPengajuan();
  }

  Future<void> _navigateToForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FormPengajuanIzinPage()),
    );

    if (result == true && mounted) {
      _loadData();
    }
  }

  void _showMenu(BuildContext context, izin, Offset position) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        const PopupMenuItem(
          value: "detail",
          child: ListTile(
            leading: Icon(Icons.info, color: AppColors.primary),
            title: Text("Detail"),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (izin.canCancel)
          const PopupMenuItem(
            value: "cancel",
            child: ListTile(
              leading: Icon(Icons.cancel, color: AppColors.error),
              title: Text("Batalkan"),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (izin.canDelete)
          const PopupMenuItem(
            value: "delete",
            child: ListTile(
              leading: Icon(Icons.delete, color: AppColors.error),
              title: Text("Hapus"),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );

    if (!mounted) return;

    if (result == "detail") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailIzinPage(izinId: izin.id)),
      );
    } else if (result == "cancel") {
      _confirmCancel(izin.id);
    } else if (result == "delete") {
      _confirmDelete(izin.id);
    }
  }

  void _confirmCancel(int id) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Konfirmasi"),
          content: const Text(
            "Apakah Anda yakin ingin membatalkan pengajuan izin ini?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Tidak"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                // Use the parent context, not dialog context
                if (!mounted) return;

                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final izinProvider = Provider.of<IzinProvider>(
                  context,
                  listen: false,
                );

                final success = await izinProvider.batalkanPengajuan(id);

                // Check mounted again before showing snackbar
                if (!mounted) return;

                if (success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Pengajuan berhasil dibatalkan'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        izinProvider.errorMessage ??
                            'Gagal membatalkan pengajuan',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text("Ya, Batalkan"),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Konfirmasi"),
          content: const Text(
            "Apakah Anda yakin ingin menghapus pengajuan izin ini?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Tidak"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                // Use the parent context, not dialog context
                if (!mounted) return;

                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final izinProvider = Provider.of<IzinProvider>(
                  context,
                  listen: false,
                );

                final success = await izinProvider.hapusPengajuan(id);

                // Check mounted again before showing snackbar
                if (!mounted) return;

                if (success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Pengajuan berhasil dihapus'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        izinProvider.errorMessage ??
                            'Gagal menghapus pengajuan',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text("Ya, Hapus"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Izin'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _navigateToForm),
        ],
      ),
      body: Consumer<IzinProvider>(
        builder: (context, izinProvider, child) {
          if (izinProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          if (izinProvider.state == IzinState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    izinProvider.errorMessage ?? 'Terjadi kesalahan',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          // Get filtered list based on tab
          final filteredList = _getFilteredList(izinProvider);

          return Column(
            children: [
              // Tabs
              Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _buildTab("Semua", izinProvider.izinList.length),
                      _buildTab("Pengajuan", izinProvider.pengajuanList.length),
                      _buildTab("Disetujui", izinProvider.disetujuiList.length),
                      _buildTab("Ditolak", izinProvider.ditolakList.length),
                      _buildTab(
                        "Dibatalkan",
                        izinProvider.dibatalkanList.length,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),

              // List izin
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada pengajuan izin',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _navigateToForm,
                              icon: const Icon(Icons.add),
                              label: const Text('Ajukan Izin'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final izin = filteredList[index];
                            return _buildIzinCard(izin);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List _getFilteredList(IzinProvider provider) {
    switch (_filterTab) {
      case "Pengajuan":
        return provider.pengajuanList;
      case "Disetujui":
        return provider.disetujuiList;
      case "Ditolak":
        return provider.ditolakList;
      case "Dibatalkan":
        return provider.dibatalkanList;
      default:
        return provider.izinList;
    }
  }

  Widget _buildTab(String label, int count) {
    final selected = _filterTab == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: selected,
        onSelected: (_) {
          setState(() => _filterTab = label);
        },
        selectedColor: AppColors.primary,
        backgroundColor: Colors.grey.shade200,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildIzinCard(izin) {
    Color statusColor;
    switch (izin.status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'disetujui':
        statusColor = AppColors.success;
        break;
      case 'ditolak':
        statusColor = AppColors.error;
        break;
      case 'dibatalkan':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: izin.jenisIzin == "Sakit"
                        ? AppColors.error.withOpacity(0.2)
                        : AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    izin.jenisIzin,
                    style: TextStyle(
                      color: izin.jenisIzin == "Sakit"
                          ? AppColors.error
                          : AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    izin.statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                GestureDetector(
                  onTapDown: (details) {
                    _showMenu(context, izin, details.globalPosition);
                  },
                  child: Icon(Icons.more_vert, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${izin.durasiHari}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const Text(
                            'Hari',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                  'id_ID',
                                ).format(izin.tanggalMulai),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.event,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat(
                                  'dd MMM yyyy',
                                  'id_ID',
                                ).format(izin.tanggalSelesai),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (izin.keterangan != null && izin.keterangan!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    izin.keterangan!,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 8),
                const Divider(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Diajukan: ${DateFormat('dd MMM yyyy', 'id_ID').format(izin.createdAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (izin.fileUrl != null)
                      const Icon(
                        Icons.attach_file,
                        size: 16,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
