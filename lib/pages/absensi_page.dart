// File: lib/pages/absensi_page.dart
// FIXED: Validasi radius tetap ditampilkan di hari libur (kecuali jabatan excluded)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../data/services/dio_service.dart';
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

  // Jabatan excluded state
  bool _isJabatanExcluded = false;

  // Data presensi dari API
  Map<String, dynamic>? _presensiData;
  String? _errorMessage;
  bool _dalamRadius = false;
  double? _jarakKeProject;

  // Track validation progress
  String _validationStatus = 'Memuat...';
  bool _isInitialCheckComplete = false;
  bool _hasGpsPosition = false;

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

    _determinePositionAndListen();
    await _cekPresensi();
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

      final dioService = DioService();
      final response = await dioService
          .get('${AppConfig.mobileApiPrefix}/presensi/cek')
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw ApiException('Timeout mengecek presensi'),
          );

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _presensiData = response['data'];

          final karyawanData = response['data']['karyawan'];
          _isJabatanExcluded =
              karyawanData != null &&
              karyawanData['is_jabatan_excluded'] == true;

          _isLoadingPresensi = false;

          debugPrint('📋 Presensi Data Loaded');
          debugPrint('   Jabatan Excluded: $_isJabatanExcluded');

          final isHariLibur = response['data']['is_hari_libur'] ?? false;
          debugPrint('   Is Hari Libur: $isHariLibur');

          if (_hasGpsPosition && _currentLatLng != null) {
            _runValidations();
          }
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

      if (mounted) {
        setState(() {
          _validationStatus = 'Mendapatkan GPS...';
        });
      }

      try {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null && mounted && !_isDisposed) {
          debugPrint('⚡ Using last known GPS position');
          await _applyNewPosition(lastPosition, initial: true, fromCache: true);
        }
      } catch (e) {
        debugPrint('⚠️ No last known position: $e');
      }

      if (!_hasGpsPosition) {
        try {
          Position pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 2),
          );
          if (mounted && !_isDisposed) {
            await _applyNewPosition(pos, initial: true);
          }
        } catch (timeoutError) {
          debugPrint('⚡ Initial GPS timeout - waiting for stream');
        }
      }

      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen(
            (pos) => _applyNewPosition(pos),
            onError: (error) {
              debugPrint('⚠️ GPS stream error: $error');
            },
          );
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mendapatkan lokasi: ${e.toString()}';
      });
    }
  }

  Future<void> _applyNewPosition(
    Position pos, {
    bool initial = false,
    bool fromCache = false,
  }) async {
    if (!mounted || _isDisposed) return;

    final bool isFirstGps = !_hasGpsPosition;

    setState(() {
      _currentPosition = pos;
      _currentLatLng = LatLng(pos.latitude, pos.longitude);
      _akurasi = pos.accuracy;
      _hasGpsPosition = true;

      if (initial && !fromCache) {
        _validationStatus = 'Validating...';
      }
    });

    if (_currentLatLng != null && initial) {
      _mapController.move(_currentLatLng!, 16.0);
    }

    if (_presensiData != null && isFirstGps) {
      await _runValidations();
    }
  }

  Future<void> _runValidations() async {
    if (_currentPosition == null || _currentLatLng == null) return;
    if (_isInitialCheckComplete) return;

    setState(() {
      _validationStatus = 'Memeriksa keamanan...';
    });

    try {
      await Future.wait([
        _detectFakeGps(_currentPosition!),
        _validasiLokasi(),
      ], eagerError: false).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('⚡ Validation timeout - using defaults');
          return <Future<void>>[];
        },
      );

      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialCheckComplete = true;

          // ✅ FIXED: Set final status - TIDAK bypass radius check untuk hari libur
          if (_isFakeGpsDetected) {
            _validationStatus = 'Fake GPS Detected';
          } else if (_isJabatanExcluded) {
            // ✅ Hanya jabatan excluded yang bypass
            _validationStatus = 'Ready';
            _dalamRadius = true;
          } else if (_dalamRadius) {
            _validationStatus = 'Ready';
          } else {
            _validationStatus = 'Out of Range';
          }
        });
      }
    } catch (e) {
      debugPrint('⚠️ Validation error: $e');

      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialCheckComplete = true;
          _validationStatus = 'Ready';

          // ✅ FIXED: Hanya bypass untuk jabatan excluded
          if (_isJabatanExcluded) {
            _dalamRadius = true;
          }
        });
      }
    }
  }

  Future<void> _detectFakeGps(Position position) async {
    if (_isDisposed || !mounted) return;

    try {
      final result = await _fakeGpsDetector
          .detectFakeGps(position)
          .timeout(
            const Duration(milliseconds: 800),
            onTimeout: () {
              debugPrint('⚡ Fake GPS check timeout');
              return FakeGpsDetectionResult(
                isSuspicious: false,
                detections: [],
                message: 'GPS valid (timeout)',
                isDeveloperModeActive: false,
                suspicionScore: 0,
              );
            },
          );

      if (mounted && !_isDisposed) {
        setState(() {
          _isFakeGpsDetected = result.shouldBlockAccess;
          _fakeGpsMessage = result.message;
          _detectionTypes = result.detections;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Fake GPS error: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _isFakeGpsDetected = false;
          _fakeGpsMessage = null;
          _detectionTypes = [];
        });
      }
    }
  }

  Future<void> _validasiLokasi() async {
    if (_isDisposed || !mounted || _currentLatLng == null) return;
    if (_isValidatingLocation) return;

    setState(() {
      _isValidatingLocation = true;
    });

    try {
      final dioService = DioService();

      final response = await dioService
          .post('${AppConfig.mobileApiPrefix}/presensi/validasi-lokasi', {
            'latitude': _currentLatLng!.latitude,
            'longitude': _currentLatLng!.longitude,
          })
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('⚡ Location validation timeout');
              throw ApiException('Timeout');
            },
          );

      if (response['success'] == true && response['data'] != null) {
        if (mounted && !_isDisposed) {
          setState(() {
            _dalamRadius = response['data']['dalam_radius'] ?? false;
            _jarakKeProject = response['data']['jarak']?.toDouble();
            _isJabatanExcluded =
                response['data']['is_jabatan_excluded'] ?? _isJabatanExcluded;

            debugPrint('📍 Location: ${_dalamRadius ? "In" : "Out"} radius');
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ Location validation error: $e');
      // ✅ FIXED: Fail open HANYA untuk jabatan excluded
      if (mounted && !_isDisposed) {
        if (_isJabatanExcluded) {
          setState(() {
            _dalamRadius = true;
          });
        }
      }
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
      _isInitialCheckComplete = false;
      _validationStatus = 'Refreshing...';
    });

    _fakeGpsDetector.clearCache();
    _fakeGpsDetector.prewarmCache();

    await _cekPresensi();

    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 2),
      );
      if (mounted && !_isDisposed) {
        await _applyNewPosition(pos, initial: true);
        await _runValidations();
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update location: ${e.toString()}'),
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
    final isHariLibur = _presensiData?['is_hari_libur'] ?? false;

    // ✅ FIXED: Bypass radius check HANYA untuk jabatan excluded
    if (_isJabatanExcluded) {
      debugPrint('🔓 Bypass radius check - Jabatan Excluded');
      _navigateToSelfie();
      return;
    }

    // ✅ CRITICAL: Untuk hari libur, tetap cek radius
    if (isHariLibur) {
      debugPrint('🏖️ Hari Libur - tetap cek radius');
    }

    if (_isFakeGpsDetected) {
      _showFakeGpsBlockDialog();
      return;
    }

    if (_currentLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Posisi GPS belum tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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

    // ✅ CRITICAL: Cek radius untuk semua (kecuali jabatan excluded)
    if (!_dalamRadius) {
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

    _navigateToSelfie();
  }

  void _navigateToSelfie() {
    final bisaMasuk = _presensiData?['bisa_presensi_masuk'] ?? false;
    final bisaPulang = _presensiData?['bisa_presensi_pulang'] ?? false;
    final isHariLibur = _presensiData?['is_hari_libur'] ?? false;
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

    String mode;

    if (isHariLibur) {
      final sudahMasuk = _presensiData?['sudah_presensi_masuk'] ?? false;
      mode = sudahMasuk ? 'pulang' : 'masuk';
      debugPrint('🏖️ Holiday mode: $mode');
    } else {
      if (bisaMasuk) {
        mode = 'masuk';
      } else if (bisaPulang) {
        mode = 'pulang';
      } else {
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
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelfiePage(
          mode: mode,
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
      return const Scaffold(body: Center(child: Text('Halaman ditutup')));
    }

    if (_isLoadingPresensi && _presensiData == null) {
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

    final defaultLocation = LatLng(-6.9667, 110.4167);
    final displayLocation = _currentLatLng ?? defaultLocation;

    final project = _presensiData?['project'];
    final shift = _presensiData?['shift'];
    final isHariLibur = _presensiData?['is_hari_libur'] ?? false;
    final bisaMasuk = _presensiData?['bisa_presensi_masuk'] ?? false;
    final bisaPulang = _presensiData?['bisa_presensi_pulang'] ?? false;
    final sudahMasuk = _presensiData?['sudah_presensi_masuk'] ?? false;
    final sudahPulang = _presensiData?['sudah_presensi_pulang'] ?? false;

    final projectLocation = project?['lokasi'];
    final projectLatLng = projectLocation != null
        ? LatLng(
            projectLocation['latitude'].toDouble(),
            projectLocation['longitude'].toDouble(),
          )
        : null;
    final projectRadius = project?['radius']?.toDouble() ?? 0.0;

    // ✅ FIXED: canPresensiByLocation - HANYA bypass untuk jabatan excluded
    final canPresensiByLocation = _dalamRadius || _isJabatanExcluded;

    final canPresensiByTime = isHariLibur
        ? !(sudahMasuk && sudahPulang)
        : (bisaMasuk || bisaPulang);

    final isButtonEnabled =
        _hasGpsPosition &&
        _isInitialCheckComplete &&
        !_isFakeGpsDetected &&
        !_isValidatingLocation &&
        canPresensiByLocation &&
        canPresensiByTime;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Map
          Positioned.fill(
            child: Center(
              child:
                  // AspectRatio(
                  //   aspectRatio: 0.6,
                  //   child:
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: displayLocation,
                      initialZoom: 16.0,
                      minZoom: 8.0,
                      maxZoom: 18.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.qms.presensi',
                        maxZoom: 18,
                      ),
                      if (projectLatLng != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: projectLatLng,
                              radius: projectRadius,
                              useRadiusInMeter: true,
                              color: canPresensiByLocation
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderColor: canPresensiByLocation
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
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
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
                      if (_hasGpsPosition)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: displayLocation,
                              width: 40,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _isFakeGpsDetected
                                      ? Colors.orange
                                      : Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isFakeGpsDetected
                                      ? Icons.warning
                                      : Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
              // ),
            ),
          ),

          // Top controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
          ),

          // ✅ FIXED: Holiday banner - tetap tampil tapi tidak bypass radius
          if (isHariLibur && !_isFakeGpsDetected && _isInitialCheckComplete)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 70, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple,
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
                          Icons.beach_access,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'HARI LIBUR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isJabatanExcluded
                                    ? 'Presensi di hari libur. Jangan lupa ajukan lembur dengan upload SKL.'
                                    : 'Presensi di hari libur. Anda tetap harus berada di dalam radius lokasi project.',
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
            ),

          // Fake GPS Warning
          if (_isFakeGpsDetected)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
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
                        const Icon(
                          Icons.security,
                          color: Colors.white,
                          size: 24,
                        ),
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
            ),

          // Jabatan excluded info
          if (_isJabatanExcluded && !_isFakeGpsDetected && !isHariLibur)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
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
                    child: const Row(
                      children: [
                        Icon(Icons.shield, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'PENGECUALIAN RADIUS AKTIF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Jabatan Anda dikecualikan dari pengecekan radius.',
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
            ),

          // ✅ FIXED: Out of radius warning - TETAP TAMPIL untuk hari libur (kecuali jabatan excluded)
          if (!_isJabatanExcluded &&
              !_isFakeGpsDetected &&
              !_dalamRadius &&
              _jarakKeProject != null &&
              _isInitialCheckComplete)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    isHariLibur ? 160 : 70,
                    16,
                    0,
                  ),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'DI LUAR RADIUS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Anda berada ${_jarakKeProject!.toStringAsFixed(0)} meter dari lokasi project (radius: ${projectRadius.toStringAsFixed(0)}m)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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
            ),

          // Bottom card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
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
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Shift info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isHariLibur
                            ? Colors.purple[50]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isHariLibur
                                      ? 'Hari Libur'
                                      : 'Shift ${shift?['kode'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  isHariLibur
                                      ? 'Presensi Khusus'
                                      : '${shift?['waktu_mulai'] ?? ''} - ${shift?['waktu_selesai'] ?? ''}',
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

                    // Validation Status
                    if (!_isInitialCheckComplete && _hasGpsPosition)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue[700]!,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _validationStatus,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // GPS Status
                    if (!_hasGpsPosition)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.orange[700]!,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Mendapatkan posisi GPS...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange[900],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_isInitialCheckComplete) ...[
                      // Attendance status
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
                    ],

                    const SizedBox(height: 12),

                    // Attendance button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isButtonEnabled
                            ? _handlePresensiButton
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_hasGpsPosition
                              ? Colors.grey[400]
                              : !_isInitialCheckComplete
                              ? Colors.grey[400]
                              : _isFakeGpsDetected
                              ? Colors.red
                              : isHariLibur
                              ? Colors.purple
                              : isButtonEnabled
                              ? Colors.blue
                              : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: isButtonEnabled ? 2 : 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!_hasGpsPosition ||
                                !_isInitialCheckComplete) ...[
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Text(
                              !_hasGpsPosition
                                  ? 'Mendapatkan GPS...'
                                  : !_isInitialCheckComplete
                                  ? _validationStatus
                                  : _isFakeGpsDetected
                                  ? 'Fake GPS Terdeteksi'
                                  : _isValidatingLocation
                                  ? 'Memvalidasi...'
                                  : isHariLibur
                                  ? (sudahMasuk
                                        ? 'Presensi Pulang (Libur)'
                                        : 'Presensi Masuk (Libur)')
                                  : bisaMasuk
                                  ? 'Presensi Masuk'
                                  : bisaPulang
                                  ? 'Presensi Pulang'
                                  : 'Tidak Dapat Presensi',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Info texts
                    if (isHariLibur &&
                        _isInitialCheckComplete &&
                        canPresensiByTime)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Colors.purple,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _isJabatanExcluded
                                    ? 'Jangan lupa ajukan lembur dengan upload SKL setelah presensi'
                                    : 'Anda harus berada di dalam radius. Jangan lupa ajukan lembur dengan upload SKL.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.purple,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_isJabatanExcluded &&
                        _isInitialCheckComplete &&
                        canPresensiByTime &&
                        !isHariLibur)
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
          ),
        ],
      ),
    );
  }
}
