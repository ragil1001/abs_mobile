import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/tukar_shift_provider.dart';
import '../../components/custom_snackbar.dart';
import '../../components/shimmer_loading.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final titleFontSize = (screenWidth * 0.050).clamp(16.0, 20.0);
    final bodyFontSize = (screenWidth * 0.036).clamp(12.0, 14.0);
    final buttonFontSize = (screenWidth * 0.038).clamp(13.0, 15.0);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.05),
                  Text(
                    'Filter',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.04),
                  Text(
                    'Jenis Permintaan',
                    style: TextStyle(
                      fontSize: bodyFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.025),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip(
                        'Semua',
                        'all',
                        setModalState,
                        screenWidth,
                      ),
                      _buildFilterChip(
                        'Permintaan Saya',
                        'saya',
                        setModalState,
                        screenWidth,
                      ),
                      _buildFilterChip(
                        'Permintaan Orang Lain',
                        'orang_lain',
                        setModalState,
                        screenWidth,
                      ),
                    ],
                  ),
                  SizedBox(height: screenWidth * 0.04),
                  Text(
                    'Rentang Tanggal',
                    style: TextStyle(
                      fontSize: bodyFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.025),
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
                          icon: Icon(
                            Icons.date_range,
                            size: (screenWidth * 0.045).clamp(16.0, 18.0),
                          ),
                          label: Text(
                            _customRange == null
                                ? 'Pilih Tanggal'
                                : '${DateFormat('dd/MM').format(_customRange!.start)} - ${DateFormat('dd/MM').format(_customRange!.end)}',
                            style: TextStyle(fontSize: bodyFontSize),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: screenWidth * 0.03,
                            ),
                          ),
                        ),
                      ),
                      if (_customRange != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: (screenWidth * 0.05).clamp(18.0, 20.0),
                          ),
                          onPressed: () {
                            setModalState(() => _customRange = null);
                            setState(() => _customRange = null);
                          },
                          color: AppColors.error,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: screenWidth * 0.04),
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
                        padding: EdgeInsets.symmetric(
                          vertical: screenWidth * 0.035,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Terapkan',
                        style: TextStyle(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
    double screenWidth,
  ) {
    final selected = _filterJenis == value;
    final chipFontSize = (screenWidth * 0.034).clamp(11.0, 13.0);

    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: chipFontSize)),
      selected: selected,
      onSelected: (bool selected) {
        setModalState(() => _filterJenis = value);
        setState(() => _filterJenis = value);
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              if (success) {
                CustomSnackbar.showSuccess(
                  context,
                  'Permintaan berhasil dibatalkan',
                );
              } else {
                CustomSnackbar.showError(
                  context,
                  provider.errorMessage ?? 'Gagal membatalkan',
                );
              }
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
              if (success) {
                CustomSnackbar.showSuccess(
                  context,
                  'Permintaan berhasil disetujui',
                );
              } else {
                CustomSnackbar.showError(
                  context,
                  provider.errorMessage ?? 'Gagal menyetujui',
                );
              }
            }
          },
        );
        break;
      case "reject":
        _showRejectDialog(request.id);
        break;
    }
  }

  // Ubah method _showRejectDialog
  void _showRejectDialog(int requestId) {
    final TextEditingController alasanController = TextEditingController();
    final screenWidth = MediaQuery.of(context).size.width;
    final titleFontSize = (screenWidth * 0.045).clamp(15.0, 18.0);
    final bodyFontSize = (screenWidth * 0.036).clamp(12.0, 14.0);

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Gunakan dialogContext untuk dialog
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Tolak Permintaan",
            style: TextStyle(fontSize: titleFontSize),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Berikan alasan penolakan:",
                style: TextStyle(fontSize: bodyFontSize),
              ),
              SizedBox(height: screenWidth * 0.03),
              TextField(
                controller: alasanController,
                maxLines: 3,
                style: TextStyle(fontSize: bodyFontSize),
                decoration: InputDecoration(
                  hintText: 'Alasan penolakan...',
                  hintStyle: TextStyle(fontSize: bodyFontSize),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Batal", style: TextStyle(fontSize: bodyFontSize)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (alasanController.text.trim().isEmpty) {
                  // Gunakan dialogContext untuk snackbar saat validasi
                  CustomSnackbar.showWarning(
                    dialogContext,
                    'Alasan penolakan wajib diisi',
                  );
                  return;
                }

                // Tutup dialog terlebih dahulu
                Navigator.pop(dialogContext);

                // Gunakan context dari widget (bukan dialogContext) untuk operasi setelah dialog ditutup
                final provider = Provider.of<TukarShiftProvider>(
                  context,
                  listen: false,
                );
                final success = await provider.prosesTukarShift(
                  id: requestId,
                  action: 'tolak',
                  alasanPenolakan: alasanController.text.trim(),
                );

                // Gunakan context dari widget untuk snackbar setelah dialog ditutup
                if (mounted) {
                  if (success) {
                    CustomSnackbar.showSuccess(
                      context,
                      'Permintaan berhasil ditolak',
                    );
                  } else {
                    CustomSnackbar.showError(
                      context,
                      provider.errorMessage ?? 'Gagal menolak',
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Ya, Tolak",
                style: TextStyle(fontSize: bodyFontSize),
              ),
            ),
          ],
        );
      },
    );
  }

  // Ubah juga method _showConfirmDialog untuk konsistensi
  void _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    bool isDestructive = false,
    required Future<void> Function() onConfirm,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleFontSize = (screenWidth * 0.045).clamp(15.0, 18.0);
    final bodyFontSize = (screenWidth * 0.036).clamp(12.0, 14.0);

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Gunakan dialogContext
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(title, style: TextStyle(fontSize: titleFontSize)),
          content: Text(message, style: TextStyle(fontSize: bodyFontSize)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Batal", style: TextStyle(fontSize: bodyFontSize)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Tutup dialog dulu
                onConfirm(); // Kemudian jalankan callback
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDestructive
                    ? AppColors.error
                    : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                confirmText,
                style: TextStyle(fontSize: bodyFontSize),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmerLayout(double screenWidth, double padding) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: padding),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: screenWidth * 0.03),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      ShimmerBox(
                        width: screenWidth * 0.25,
                        height: 20,
                        borderRadius: 6,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ShimmerBox(
                          width: double.infinity,
                          height: 16,
                          borderRadius: 4,
                        ),
                      ),
                      ShimmerBox(width: 24, height: 24, borderRadius: 8),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(
                              width: screenWidth * 0.2,
                              height: 12,
                              borderRadius: 4,
                            ),
                            const SizedBox(height: 8),
                            ShimmerBox(
                              width: double.infinity,
                              height: 60,
                              borderRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ShimmerBox(width: 32, height: 32, borderRadius: 16),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(
                              width: screenWidth * 0.2,
                              height: 12,
                              borderRadius: 4,
                            ),
                            const SizedBox(height: 8),
                            ShimmerBox(
                              width: double.infinity,
                              height: 60,
                              borderRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.05;
    final titleFontSize = (screenWidth * 0.048).clamp(16.0, 20.0);
    final bodyFontSize = (screenWidth * 0.036).clamp(12.0, 14.0);
    final smallFontSize = (screenWidth * 0.032).clamp(10.0, 12.0);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 253, 253),
      body: SafeArea(
        child: Consumer<TukarShiftProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return Column(
                children: [
                  _buildHeader(
                    context,
                    screenWidth,
                    screenHeight,
                    padding,
                    titleFontSize,
                  ),
                  Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: screenHeight * 0.01,
                      ),
                      child: Row(
                        children: [
                          _buildTab(
                            "Semua",
                            "all",
                            0,
                            screenWidth,
                            smallFontSize,
                          ),
                          _buildTab(
                            "Pending",
                            "pending",
                            0,
                            screenWidth,
                            smallFontSize,
                          ),
                          _buildTab(
                            "Disetujui",
                            "disetujui",
                            0,
                            screenWidth,
                            smallFontSize,
                          ),
                          _buildTab(
                            "Ditolak",
                            "ditolak",
                            0,
                            screenWidth,
                            smallFontSize,
                          ),
                          _buildTab(
                            "Dibatalkan",
                            "dibatalkan",
                            0,
                            screenWidth,
                            smallFontSize,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(child: _buildShimmerLayout(screenWidth, padding)),
                ],
              );
            }

            if (provider.errorMessage != null) {
              return Column(
                children: [
                  _buildHeader(
                    context,
                    screenWidth,
                    screenHeight,
                    padding,
                    titleFontSize,
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: (screenWidth * 0.16).clamp(48.0, 64.0),
                              color: AppColors.error.withOpacity(0.5),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              provider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: bodyFontSize,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            ElevatedButton(
                              onPressed: _loadData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.08,
                                  vertical: screenHeight * 0.015,
                                ),
                              ),
                              child: Text(
                                'Coba Lagi',
                                style: TextStyle(fontSize: bodyFontSize),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final requests = provider.requests;
            final filteredRequests = _getFilteredList(requests);

            return Column(
              children: [
                _buildHeader(
                  context,
                  screenWidth,
                  screenHeight,
                  padding,
                  titleFontSize,
                ),
                Container(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: screenHeight * 0.01,
                    ),
                    child: Row(
                      children: [
                        _buildTab(
                          "Semua",
                          "all",
                          requests.length,
                          screenWidth,
                          smallFontSize,
                        ),
                        _buildTab(
                          "Pending",
                          "pending",
                          _getCountByStatus(requests, "pending"),
                          screenWidth,
                          smallFontSize,
                        ),
                        _buildTab(
                          "Disetujui",
                          "disetujui",
                          _getCountByStatus(requests, "disetujui"),
                          screenWidth,
                          smallFontSize,
                        ),
                        _buildTab(
                          "Ditolak",
                          "ditolak",
                          _getCountByStatus(requests, "ditolak"),
                          screenWidth,
                          smallFontSize,
                        ),
                        _buildTab(
                          "Dibatalkan",
                          "dibatalkan",
                          _getCountByStatus(requests, "dibatalkan"),
                          screenWidth,
                          smallFontSize,
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                if (_filterJenis != "all" || _customRange != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: padding,
                      vertical: screenHeight * 0.015,
                    ),
                    color: AppColors.primary.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_alt,
                          size: (screenWidth * 0.05).clamp(18.0, 20.0),
                          color: AppColors.primary,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Expanded(
                          child: Text(
                            [
                              if (_filterJenis == "saya") "Permintaan Saya",
                              if (_filterJenis == "orang_lain")
                                "Permintaan Orang Lain",
                              if (_customRange != null)
                                '${DateFormat('dd MMM').format(_customRange!.start)} - ${DateFormat('dd MMM').format(_customRange!.end)}',
                            ].join(' • '),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: bodyFontSize,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: (screenWidth * 0.05).clamp(18.0, 20.0),
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
                Expanded(
                  child: filteredRequests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.swap_horiz,
                                size: (screenWidth * 0.16).clamp(48.0, 64.0),
                                color: Colors.grey.shade300,
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Text(
                                'Belum ada permintaan tukar shift',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: bodyFontSize,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => provider.refreshRequests(
                            jenis: _filterJenis,
                            startDate: _customRange?.start.toString().split(
                              ' ',
                            )[0],
                            endDate: _customRange?.end.toString().split(' ')[0],
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.all(padding),
                            itemCount: filteredRequests.length,
                            itemBuilder: (context, index) {
                              return _buildRequestCard(
                                filteredRequests[index],
                                screenWidth,
                                bodyFontSize,
                                smallFontSize,
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
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
        elevation: 4,
        label: Text(
          'Ajukan Tukar Shift',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: (screenWidth * 0.036).clamp(12.0, 14.0),
          ),
        ),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    double padding,
    double titleFontSize,
  ) {
    final iconSize = (screenWidth * 0.1).clamp(36.0, 42.0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: screenHeight * 0.02,
      ),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: (screenWidth * 0.045).clamp(16.0, 18.0),
                color: Colors.black87,
              ),
            ),
          ),
          const Spacer(),
          Text(
            "Tukar Shift",
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showFilterDialog,
            child: Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.filter_alt,
                size: (screenWidth * 0.05).clamp(18.0, 20.0),
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    String label,
    String value,
    int count,
    double screenWidth,
    double fontSize,
  ) {
    final selected = _filterTab == value;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: selected,
        onSelected: (_) {
          if (_filterTab != value) {
            setState(() => _filterTab = value);
          }
        },
        selectedColor: AppColors.primary,
        backgroundColor: Colors.grey.shade200,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: fontSize,
        ),
      ),
    );
  }

  List _getFilteredList(List requests) {
    if (_filterTab == "all") return requests;
    return requests.where((req) => req.status == _filterTab).toList();
  }

  Widget _buildRequestCard(
    request,
    double screenWidth,
    double bodyFontSize,
    double smallFontSize,
  ) {
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
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.03),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.02,
                    vertical: screenWidth * 0.01,
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
                      fontSize: smallFontSize,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
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
                      fontSize: bodyFontSize,
                    ),
                  ),
                ),
                GestureDetector(
                  onTapDown: (details) {
                    _showActionMenu(request, details.globalPosition);
                  },
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.015),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.more_vert,
                      color: Colors.grey.shade700,
                      size: (screenWidth * 0.05).clamp(18.0, 20.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.03),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        screenWidth,
                        smallFontSize,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.02,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.swap_horiz,
                          color: AppColors.primary,
                          size: (screenWidth * 0.06).clamp(20.0, 24.0),
                        ),
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
                        screenWidth,
                        smallFontSize,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenWidth * 0.03),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Diajukan: ${DateFormat('dd MMM yyyy', 'id_ID').format(request.tanggalRequest)}',
                      style: TextStyle(
                        fontSize: smallFontSize,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (request.catatan != null && request.catatan!.isNotEmpty)
                      Icon(
                        Icons.note,
                        size: (screenWidth * 0.04).clamp(14.0, 16.0),
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
    double screenWidth,
    double fontSize,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.025),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: (screenWidth * 0.026).clamp(9.0, 10.0),
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: screenWidth * 0.01),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.02,
              vertical: screenWidth * 0.005,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Shift $shiftCode',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: (screenWidth * 0.029).clamp(10.0, 11.0),
              ),
            ),
          ),
          SizedBox(height: screenWidth * 0.015),
          Text(
            DateFormat('dd MMM yyyy', 'id_ID').format(tanggal),
            style: TextStyle(
              fontSize: (screenWidth * 0.029).clamp(10.0, 11.0),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            waktu,
            style: TextStyle(
              fontSize: (screenWidth * 0.026).clamp(9.0, 10.0),
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
