import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../data/services/api_service.dart';
import '../data/services/fake_gps_detector_service.dart';
import '../core/config/app_config.dart';
import 'selfie_page.dart';

class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  final _fakeGpsDetector = FakeGpsDetectorService();
  StreamSubscription<Position>? _positionStreamSubscription;

  LatLng? _currentLatLng;
  Position? _currentPosition;
  double _akurasi = 0;
  bool _isDisposed = false;
  bool _isLoadingPresensi = true;
  bool _isValidatingLocation = false;

  // Fake GPS Detection State
  bool _isFakeGpsDetected = false;
  String? _fakeGpsMessage;
  List<FakeGpsDetectionType> _detectionTypes = [];

  // NEW: Jabatan excluded state
  bool _isJabatanExcluded = false;

  // Data presensi dari API
  Map<String, dynamic>? _presensiData;
  String? _errorMessage;
  bool _dalamRadius = false;
  double? _jarakKeProject;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Intl.defaultLocale = 'id_ID';

    Future.microtask(() {
      if (mounted && !_isDisposed) {
        _initializePresensi();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
        _positionStreamSubscription?.pause();
        break;
      case AppLifecycleState.resumed:
        _positionStreamSubscription?.resume();
        if (_currentPosition != null) {
          _detectFakeGps(_currentPosition!);
        }
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _positionStreamSubscription?.cancel();
    _fakeGpsDetector.reset();
    super.dispose();
  }

  Future<void> _initializePresensi() async {
    if (_isDisposed || !mounted) return;

    await _cekPresensi();
    await _determinePositionAndListen();
  }

  Future<void> _cekPresensi() async {
    if (_isDisposed || !mounted) return;

    setState(() {
      _isLoadingPresensi = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw ApiException('Token tidak ditemukan');
      }

      final apiService = ApiService();
      final response = await apiService.get(
        '${AppConfig.mobileApiPrefix}/presensi/cek',
      );

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _presensiData = response['data'];

          // NEW: Check if jabatan excluded
          final karyawanData = response['data']['karyawan'];
          _isJabatanExcluded =
              karyawanData != null &&
              karyawanData['is_jabatan_excluded'] == true;

          _isLoadingPresensi = false;
        });
      } else {
        throw ApiException(response['message'] ?? 'Gagal mengecek presensi');
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoadingPresensi = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        _isLoadingPresensi = false;
      });
    }
  }

  Future<void> _determinePositionAndListen() async {
    if (_isDisposed || !mounted) return;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'GPS tidak aktif. Silakan aktifkan GPS Anda.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Izin lokasi ditolak';
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Izin lokasi ditolak permanen';
        });
        return;
      }

      try {
        Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        if (mounted && !_isDisposed) {
          await _applyNewPosition(pos, initial: true);
        }
      } catch (_) {}

      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) => _applyNewPosition(pos));
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mendapatkan lokasi: ${e.toString()}';
      });
    }
  }

  Future<void> _applyNewPosition(Position pos, {bool initial = false}) async {
    if (!mounted || _isDisposed) return;

    setState(() {
      _currentPosition = pos;
      _currentLatLng = LatLng(pos.latitude, pos.longitude);
      _akurasi = pos.accuracy;
    });

    if (_currentLatLng != null && initial) {
      _mapController.move(_currentLatLng!, 16.0);
    }

    await _detectFakeGps(pos);

    // Validate location only if no fake GPS detected
    if (!_isFakeGpsDetected &&
        _presensiData != null &&
        _currentLatLng != null) {
      await _validasiLokasi();
    }
  }

  Future<void> _detectFakeGps(Position position) async {
    if (_isDisposed || !mounted) return;

    try {
      final result = await _fakeGpsDetector.detectFakeGps(position);

      if (mounted && !_isDisposed) {
        setState(() {
          _isFakeGpsDetected = result.shouldBlockAccess;
          _fakeGpsMessage = result.message;
          _detectionTypes = result.detections;
        });
      }
    } catch (e) {
      debugPrint('Error detecting fake GPS: $e');
    }
  }

  Future<void> _validasiLokasi() async {
    if (_isDisposed || !mounted || _currentLatLng == null) return;
    if (_isValidatingLocation) return;

    setState(() {
      _isValidatingLocation = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService
          .post('${AppConfig.mobileApiPrefix}/presensi/validasi-lokasi', {
            'latitude': _currentLatLng!.latitude,
            'longitude': _currentLatLng!.longitude,
          });

      if (response['success'] == true && response['data'] != null) {
        if (mounted && !_isDisposed) {
          setState(() {
            _dalamRadius = response['data']['dalam_radius'] ?? false;
            _jarakKeProject = response['data']['jarak']?.toDouble();

            // UPDATE: Extract jabatan excluded dari response
            _isJabatanExcluded =
                response['data']['is_jabatan_excluded'] ?? false;

            // DEBUG LOG
            debugPrint(
              'Validasi Lokasi Result: dalam_radius=$_dalamRadius, '
              'is_jabatan_excluded=$_isJabatanExcluded, jarak=$_jarakKeProject',
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Validasi lokasi error: $e');
    } finally {
      if (mounted && !_isDisposed) {
        setState(() {
          _isValidatingLocation = false;
        });
      }
    }
  }

  void _onRefreshPressed() async {
    if (_isDisposed || !mounted) return;

    HapticFeedback.lightImpact();

    setState(() {
      _isLoadingPresensi = true;
      _isFakeGpsDetected = false;
      _fakeGpsMessage = null;
      _detectionTypes = [];
    });

    await _cekPresensi();

    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      if (mounted && !_isDisposed) {
        await _applyNewPosition(pos);
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui lokasi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _todayString() {
    final now = DateTime.now();
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
  }

  void _handlePresensiButton() {
    // ========== STEP 1: Check fake GPS (PRIORITY TERTINGGI) ==========
    if (_isFakeGpsDetected) {
      _showFakeGpsBlockDialog();
      return;
    }

    // ========== STEP 2: Check GPS tersedia ==========
    if (_currentLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi GPS belum tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ========== STEP 3: Tunggu validasi lokasi selesai ==========
    if (_isValidatingLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sedang memvalidasi lokasi, tunggu sebentar...'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // ========== STEP 4: Validasi radius (kecuali jabatan excluded) ==========
    final canPresensiByLocation = _dalamRadius || _isJabatanExcluded;

    if (!canPresensiByLocation) {
      if (_jarakKeProject != null) {
        final radius = _presensiData?['project']?['radius']?.toDouble() ?? 0.0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Anda berada ${_jarakKeProject!.toStringAsFixed(0)} meter dari lokasi '
              '(radius: ${radius.toStringAsFixed(0)}m). Presensi tidak dapat dilakukan.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda berada di luar radius lokasi presensi'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // ========== STEP 5: Check jadwal dan waktu presensi ==========
    final bisaMasuk = _presensiData?['bisa_presensi_masuk'] ?? false;
    final bisaPulang = _presensiData?['bisa_presensi_pulang'] ?? false;
    final jadwalId = _presensiData?['jadwal_id'];

    if (jadwalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data jadwal tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ FIX: Determine mode - NON-NULLABLE
    String mode;

    if (bisaMasuk) {
      mode = 'masuk';
    } else if (bisaPulang) {
      mode = 'pulang';
    } else {
      // Tidak bisa masuk dan tidak bisa pulang
      final pesanWaktu =
          _presensiData?['waktu_info']?['pesan'] ??
          'Tidak dapat melakukan presensi saat ini';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pesanWaktu),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return; // Early return - mode tidak akan digunakan
    }

    // ✅ DEBUG LOG
    debugPrint('=== PRESENSI BUTTON DEBUG ===');
    debugPrint('bisaMasuk: $bisaMasuk');
    debugPrint('bisaPulang: $bisaPulang');
    debugPrint('mode: $mode'); // Mode pasti non-null di sini
    debugPrint('canPresensiByLocation: $canPresensiByLocation');
    debugPrint('============================');

    // ========== All checks passed, go to selfie page ==========
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelfiePage(
          mode: mode, // ✅ Type safe - String (non-nullable)
          jadwalId: jadwalId,
          latitude: _currentLatLng!.latitude,
          longitude: _currentLatLng!.longitude,
        ),
        settings: const RouteSettings(name: '/selfie'),
      ),
    );
  }

  void _showFakeGpsBlockDialog() {
    final messages = <String>[];

    if (_detectionTypes.contains(FakeGpsDetectionType.developerMode)) {
      messages.add('• Opsi Developer aktif di perangkat Anda');
    }
    if (_detectionTypes.contains(FakeGpsDetectionType.mockLocation)) {
      messages.add('• Mock Location terdeteksi aktif');
    }
    if (_detectionTypes.contains(FakeGpsDetectionType.lowAccuracy)) {
      messages.add('• Akurasi GPS mencurigakan');
    }
    if (_detectionTypes.contains(FakeGpsDetectionType.unnaturalMovement)) {
      messages.add('• Perpindahan lokasi tidak wajar terdeteksi');
    }
    if (_detectionTypes.contains(FakeGpsDetectionType.fakeGpsApp)) {
      messages.add('• Aplikasi fake GPS terdeteksi di perangkat');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Column(
          children: [
            Icon(Icons.security, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Fake GPS Terdeteksi',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sistem mendeteksi indikasi penggunaan fake GPS:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...messages.map(
                (msg) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(msg, style: const TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Untuk keamanan presensi, silakan:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Matikan Opsi Developer\n'
                '2. Matikan Mock Location\n'
                '3. Uninstall aplikasi fake GPS\n'
                '4. Restart perangkat Anda',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _onRefreshPressed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const Scaffold(body: Center(child: Text('Page disposed')));
    }

    if (_isLoadingPresensi) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat data presensi...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Presensi', style: TextStyle(color: Colors.black)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 64, color: Colors.orange[700]),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _onRefreshPressed,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_currentLatLng == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final project = _presensiData?['project'];
    final shift = _presensiData?['shift'];
    final bisaMasuk = _presensiData?['bisa_presensi_masuk'] ?? false;
    final bisaPulang = _presensiData?['bisa_presensi_pulang'] ?? false;
    final sudahMasuk = _presensiData?['sudah_presensi_masuk'] ?? false;

    final projectLocation = project?['lokasi'];
    final projectLatLng = projectLocation != null
        ? LatLng(
            projectLocation['latitude'].toDouble(),
            projectLocation['longitude'].toDouble(),
          )
        : null;
    final projectRadius = project?['radius']?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLatLng!,
              initialZoom: 16.0,
              minZoom: 8.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.abs',
                maxZoom: 18,
              ),
              if (projectLatLng != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: projectLatLng,
                      radius: projectRadius,
                      useRadiusInMeter: true,
                      color: (_dalamRadius || _isJabatanExcluded)
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderColor: (_dalamRadius || _isJabatanExcluded)
                          ? Colors.green
                          : Colors.red,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              if (projectLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: projectLatLng,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.business,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLatLng!,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isFakeGpsDetected ? Colors.orange : Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isFakeGpsDetected ? Icons.warning : Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Top controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FloatingActionButton(
                    heroTag: "back",
                    mini: true,
                    backgroundColor: Colors.white,
                    elevation: 2,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                  Row(
                    children: [
                      FloatingActionButton(
                        heroTag: "my_location",
                        mini: true,
                        backgroundColor: Colors.white,
                        elevation: 2,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          if (_currentLatLng != null) {
                            _mapController.move(_currentLatLng!, 16.0);
                          }
                        },
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        heroTag: "refresh",
                        mini: true,
                        backgroundColor: Colors.white,
                        elevation: 2,
                        onPressed: _onRefreshPressed,
                        child: const Icon(Icons.refresh, color: Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Fake GPS Warning (PRIORITY HIGHEST)
          if (_isFakeGpsDetected)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 70, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'FAKE GPS TERDETEKSI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _fakeGpsMessage ?? 'Sistem mendeteksi fake GPS',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // NEW: Jabatan excluded info (PRIORITY HIGH)
          if (_isJabatanExcluded && !_isFakeGpsDetected)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 70, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'PENGECUALIAN RADIUS AKTIF',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Jabatan Anda dikecualikan dari pengecekan radius. Anda dapat presensi dari lokasi manapun.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Out of radius warning (only if NOT excluded and NO fake GPS)
          if (!_isJabatanExcluded &&
              !_isFakeGpsDetected &&
              !_dalamRadius &&
              _jarakKeProject != null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 70, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Anda berada ${_jarakKeProject!.toStringAsFixed(0)} meter dari lokasi project (radius: ${projectRadius.toStringAsFixed(0)}m)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom presensi container
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project name
                  Text(
                    project?['nama'] ?? 'Project',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project?['bagian'] ?? '',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),

                  // Shift info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shift ${shift?['kode'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${shift?['waktu_mulai'] ?? ''} - ${shift?['waktu_selesai'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _todayString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Presensi status
                  Row(
                    children: [
                      Icon(
                        sudahMasuk ? Icons.check_circle : Icons.access_time,
                        color: sudahMasuk ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sudahMasuk
                            ? 'Sudah presensi masuk'
                            : 'Belum presensi masuk',
                        style: TextStyle(
                          fontSize: 14,
                          color: sudahMasuk ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Presensi button
                  // Presensi button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // ✅ FIX: Kondisi yang lebih simple dan jelas

                        // Check 1: Fake GPS
                        if (_isFakeGpsDetected) return null;

                        // Check 2: Masih validating location
                        if (_isValidatingLocation) return null;

                        // Check 3: GPS tidak tersedia
                        if (_currentLatLng == null) return null;

                        // Check 4: Harus dalam radius ATAU jabatan excluded
                        final canByLocation =
                            _dalamRadius || _isJabatanExcluded;
                        if (!canByLocation) return null;

                        // Check 5: Harus bisa presensi masuk ATAU pulang
                        final bisaMasuk =
                            _presensiData?['bisa_presensi_masuk'] ?? false;
                        final bisaPulang =
                            _presensiData?['bisa_presensi_pulang'] ?? false;

                        if (!bisaMasuk && !bisaPulang) return null;

                        // ✅ All checks passed - button ENABLED
                        return _handlePresensiButton;
                      }(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFakeGpsDetected
                            ? Colors.red
                            : (_dalamRadius || _isJabatanExcluded)
                            ? Colors.blue
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation:
                            ((_dalamRadius || _isJabatanExcluded) &&
                                !_isFakeGpsDetected)
                            ? 2
                            : 0,
                      ),
                      child: Text(
                        _isFakeGpsDetected
                            ? 'Fake GPS Terdeteksi'
                            : _isValidatingLocation
                            ? 'Memvalidasi Lokasi...'
                            : (_presensiData?['bisa_presensi_masuk'] ?? false)
                            ? 'Presensi Masuk'
                            : (_presensiData?['bisa_presensi_pulang'] ?? false)
                            ? 'Presensi Pulang'
                            : 'Tidak Dapat Presensi',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // NEW: Info text below button if jabatan excluded
                  if (_isJabatanExcluded && (bisaMasuk || bisaPulang))
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Jabatan Anda tidak perlu dalam radius untuk presensi',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
