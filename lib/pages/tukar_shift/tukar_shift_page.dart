import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/tukar_shift_provider.dart';
import 'tukar_shift_request_page.dart';
import 'tukar_shift_detail_page.dart';

class TukarShiftPage extends StatefulWidget {
  const TukarShiftPage({super.key});

  @override
  State<TukarShiftPage> createState() => _TukarShiftPageState();
}

class _TukarShiftPageState extends State<TukarShiftPage> {
  String _filterTab = "all";
  String _filterJenis = "all";
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final provider = Provider.of<TukarShiftProvider>(context, listen: false);
    provider.loadTukarShiftRequests(
      status: _filterTab,
      jenis: _filterJenis,
      startDate: _customRange?.start.toString().split(' ')[0],
      endDate: _customRange?.end.toString().split(' ')[0],
    );
  }

  int _getCountByStatus(List requests, String status) {
    if (status == "all") return requests.length;
    return requests.where((req) => req.status == status).length;
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Jenis Permintaan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip('Semua', 'all', setModalState),
                      _buildFilterChip(
                        'Permintaan Saya',
                        'saya',
                        setModalState,
                      ),
                      _buildFilterChip(
                        'Permintaan Orang Lain',
                        'orang_lain',
                        setModalState,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Rentang Tanggal',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final range = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              initialDateRange: _customRange,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: AppColors.primary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (range != null) {
                              setModalState(() => _customRange = range);
                              setState(() => _customRange = range);
                            }
                          },
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            _customRange == null
                                ? 'Pilih Tanggal'
                                : '${DateFormat('dd/MM').format(_customRange!.start)} - ${DateFormat('dd/MM').format(_customRange!.end)}',
                          ),
                        ),
                      ),
                      if (_customRange != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setModalState(() => _customRange = null);
                            setState(() => _customRange = null);
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Terapkan'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    StateSetter setModalState,
  ) {
    final selected = _filterJenis == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (bool selected) {
        setModalState(() => _filterJenis = value);
        setState(() => _filterJenis = value);
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
    );
  }

  void _showActionMenu(request, Offset position) async {
    final jenis = request.jenis;
    final status = request.status;

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
            title: Text("Lihat Detail"),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (jenis == 'saya' && status == 'pending')
          const PopupMenuItem(
            value: "cancel",
            child: ListTile(
              leading: Icon(Icons.cancel, color: AppColors.error),
              title: Text("Batalkan"),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (jenis == 'orang_lain' && status == 'pending') ...[
          const PopupMenuItem(
            value: "approve",
            child: ListTile(
              leading: Icon(Icons.check_circle, color: AppColors.success),
              title: Text("Setujui"),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: "reject",
            child: ListTile(
              leading: Icon(Icons.close, color: AppColors.error),
              title: Text("Tolak"),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ],
    );

    if (!mounted) return;

    switch (result) {
      case "detail":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TukarShiftDetailPage(request: request),
          ),
        );
        break;
      case "cancel":
        _showConfirmDialog(
          title: "Batalkan Permintaan",
          message:
              "Apakah Anda yakin ingin membatalkan permintaan tukar shift ini?",
          confirmText: "Ya, Batalkan",
          onConfirm: () async {
            final provider = Provider.of<TukarShiftProvider>(
              context,
              listen: false,
            );
            final success = await provider.cancelTukarShift(request.id);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Permintaan berhasil dibatalkan'
                        : provider.errorMessage ?? 'Gagal membatalkan',
                  ),
                  backgroundColor: success
                      ? AppColors.success
                      : AppColors.error,
                ),
              );
            }
          },
        );
        break;
      case "approve":
        _showConfirmDialog(
          title: "Setujui Permintaan",
          message:
              "Apakah Anda yakin ingin menyetujui permintaan tukar shift ini?",
          confirmText: "Ya, Setujui",
          onConfirm: () async {
            final provider = Provider.of<TukarShiftProvider>(
              context,
              listen: false,
            );
            final success = await provider.prosesTukarShift(
              id: request.id,
              action: 'setujui',
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Permintaan berhasil disetujui'
                        : provider.errorMessage ?? 'Gagal menyetujui',
                  ),
                  backgroundColor: success
                      ? AppColors.success
                      : AppColors.error,
                ),
              );
            }
          },
        );
        break;
      case "reject":
        _showRejectDialog(request.id);
        break;
    }
  }

  void _showRejectDialog(int requestId) {
    final TextEditingController alasanController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Tolak Permintaan"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Berikan alasan penolakan:"),
              const SizedBox(height: 12),
              TextField(
                controller: alasanController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Alasan penolakan...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (alasanController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alasan penolakan wajib diisi'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                final provider = Provider.of<TukarShiftProvider>(
                  context,
                  listen: false,
                );
                final success = await provider.prosesTukarShift(
                  id: requestId,
                  action: 'tolak',
                  alasanPenolakan: alasanController.text.trim(),
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Permintaan berhasil ditolak'
                            : provider.errorMessage ?? 'Gagal menolak',
                      ),
                      backgroundColor: success
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text("Ya, Tolak"),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    bool isDestructive = false,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDestructive
                    ? AppColors.error
                    : AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Tukar Shift'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Consumer<TukarShiftProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final requests = provider.requests;

          return Column(
            children: [
              // Status tabs
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
                      _buildTab(
                        "Semua",
                        "all",
                        _getCountByStatus(requests, "all"),
                      ),
                      _buildTab(
                        "Pending",
                        "pending",
                        _getCountByStatus(requests, "pending"),
                      ),
                      _buildTab(
                        "Disetujui",
                        "disetujui",
                        _getCountByStatus(requests, "disetujui"),
                      ),
                      _buildTab(
                        "Ditolak",
                        "ditolak",
                        _getCountByStatus(requests, "ditolak"),
                      ),
                      _buildTab(
                        "Dibatalkan",
                        "dibatalkan",
                        _getCountByStatus(requests, "dibatalkan"),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),

              // Filter info
              if (_filterJenis != "all" || _customRange != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: AppColors.primary.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.filter_alt,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          [
                            if (_filterJenis == "saya") "Permintaan Saya",
                            if (_filterJenis == "orang_lain")
                              "Permintaan Orang Lain",
                            if (_customRange != null)
                              '${DateFormat('dd MMM').format(_customRange!.start)} - ${DateFormat('dd MMM').format(_customRange!.end)}',
                          ].join(' • '),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _filterJenis = "all";
                            _customRange = null;
                          });
                          _loadData();
                        },
                      ),
                    ],
                  ),
                ),

              // List
              Expanded(
                child: requests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.swap_horiz,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada permintaan tukar shift',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.refreshRequests(
                          status: _filterTab,
                          jenis: _filterJenis,
                          startDate: _customRange?.start.toString().split(
                            ' ',
                          )[0],
                          endDate: _customRange?.end.toString().split(' ')[0],
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            return _buildRequestCard(requests[index]);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TukarShiftRequestPage()),
          );
          _loadData();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        label: const Text('Ajukan Tukar Shift'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTab(String label, String value, int count) {
    final selected = _filterTab == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: selected,
        onSelected: (_) {
          setState(() => _filterTab = value);
          _loadData();
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

  Widget _buildRequestCard(request) {
    final status = request.status;
    final jenis = request.jenis;
    final shiftSaya = request.shiftSaya;
    final shiftDiminta = request.shiftDiminta;
    final karyawanTujuan = request.karyawanTujuan;

    Color statusColor;
    switch (status) {
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
                    color: jenis == 'saya'
                        ? Colors.blue.shade100
                        : Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    jenis == 'saya'
                        ? 'Permintaan Saya'
                        : 'Dari ${karyawanTujuan.nama}',
                    style: TextStyle(
                      color: jenis == 'saya'
                          ? Colors.blue.shade700
                          : Colors.purple.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status == 'pending'
                        ? 'Menunggu'
                        : status == 'disetujui'
                        ? 'Disetujui'
                        : status == 'ditolak'
                        ? 'Ditolak'
                        : 'Dibatalkan',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                GestureDetector(
                  onTapDown: (details) {
                    _showActionMenu(request, details.globalPosition);
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
                // Shift exchange visualization
                Row(
                  children: [
                    Expanded(
                      child: _buildShiftBox(
                        'Shift Saya',
                        shiftSaya.shiftCode,
                        shiftSaya.tanggal,
                        shiftSaya.waktu ??
                            '${shiftSaya.waktuMulai} - ${shiftSaya.waktuSelesai}',
                        Colors.blue,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: const Icon(
                        Icons.swap_horiz,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                    Expanded(
                      child: _buildShiftBox(
                        'Shift Diminta',
                        shiftDiminta.shiftCode,
                        shiftDiminta.tanggal,
                        shiftDiminta.waktu ??
                            '${shiftDiminta.waktuMulai} - ${shiftDiminta.waktuSelesai}',
                        Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(),

                // Footer info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Diajukan: ${DateFormat('dd MMM yyyy', 'id_ID').format(request.tanggalRequest)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (request.catatan != null && request.catatan!.isNotEmpty)
                      const Icon(
                        Icons.note,
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

  Widget _buildShiftBox(
    String label,
    String shiftCode,
    DateTime tanggal,
    String waktu,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Shift $shiftCode',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('dd MMM yyyy', 'id_ID').format(tanggal),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Text(
            waktu,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
