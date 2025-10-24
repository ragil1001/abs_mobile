import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/presensi_provider.dart'; // TAMBAH INI
import '../data/services/dio_service.dart';
import '../core/config/app_config.dart';
import 'dart:convert';
import '../data/services/image_compression_service.dart';

class SelfiePage extends StatefulWidget {
  final String mode; // "masuk" atau "pulang"
  final int jadwalId;
  final double latitude;
  final double longitude;

  const SelfiePage({
    super.key,
    required this.mode,
    required this.jadwalId,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<SelfiePage> createState() => _SelfiePageState();
}

class _SelfiePageState extends State<SelfiePage> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraInitialized = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Current location
  Position? _currentPosition;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      // Cari kamera depan
      CameraDescription? frontCamera;
      for (var camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      // Jika tidak ada kamera depan, gunakan kamera pertama
      final selectedCamera = frontCamera ?? cameras.first;

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _initializeControllerFuture = _controller!.initialize();

      await _initializeControllerFuture;

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal menginisialisasi kamera: ${e.toString()}';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isGettingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendapatkan lokasi: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kamera belum siap'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isSubmitting) return;

    // Pastikan lokasi sudah didapat
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menunggu lokasi GPS...'),
          backgroundColor: Colors.orange,
        ),
      );
      await _getCurrentLocation();
      if (_currentPosition == null) {
        return;
      }
    }

    try {
      HapticFeedback.mediumImpact();

      // Ambil foto
      final image = await _controller!.takePicture();

      if (!mounted) return;

      // Tampilkan preview dan konfirmasi
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    'Preview Foto',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Image.file(File(image.path), fit: BoxFit.cover),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Ulangi'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Gunakan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (confirmed == true && mounted) {
        await _submitPresensi(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitPresensi(File imageFile) async {
    setState(() {
      _isSubmitting = true;
    });

    File? compressedFile;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw ApiException('Token tidak ditemukan');
      }

      // ✅ COMPRESS FOTO SEBELUM UPLOAD
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memproses foto...'),
          duration: Duration(seconds: 1),
        ),
      );

      compressedFile = await ImageCompressionService.compressPresensiPhoto(
        imageFile,
      );

      // Log ukuran file
      final originalSize = await imageFile.length();
      final compressedSize = await compressedFile.length();
      debugPrint(
        '📸 Original: ${(originalSize / 1024).toStringAsFixed(0)}KB → '
        'Compressed: ${(compressedSize / 1024).toStringAsFixed(0)}KB',
      );

      final lat = _currentPosition?.latitude ?? widget.latitude;
      final lon = _currentPosition?.longitude ?? widget.longitude;

      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.mobileApiPrefix}/presensi/submit',
      );

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.headers['X-Requested-With'] = 'FlutterApp';

      request.fields['jadwal_id'] = widget.jadwalId.toString();
      request.fields['tipe'] = widget.mode;
      request.fields['latitude'] = lat.toString();
      request.fields['longitude'] = lon.toString();

      // Upload compressed file
      request.files.add(
        await http.MultipartFile.fromPath('foto', compressedFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = json.decode(response.body);

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseData['success'] == true) {
          HapticFeedback.mediumImpact();

          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text('Berhasil'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      responseData['message'] ?? 'Presensi berhasil dicatat',
                    ),
                    const SizedBox(height: 12),
                    if (responseData['data'] != null) ...[
                      _buildInfoRow(
                        'Status',
                        responseData['data']['status_text'] ?? '',
                      ),
                      if (responseData['data']['keterangan'] != null)
                        _buildInfoRow(
                          'Keterangan',
                          responseData['data']['keterangan'],
                        ),
                      _buildInfoRow(
                        'Waktu',
                        responseData['data']['waktu'] ?? '',
                      ),
                    ],
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleSuccessAndReturn();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          throw ApiException(
            responseData['message'] ?? 'Gagal menyimpan presensi',
          );
        }
      } else {
        throw ApiException(
          responseData['message'] ?? 'Gagal menyimpan presensi',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException
                  ? e.message
                  : 'Terjadi kesalahan: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      // ✅ CLEANUP: Delete compressed file
      if (compressedFile != null) {
        try {
          await compressedFile.delete();
        } catch (_) {}
      }
    }
  }

  // TAMBAH METHOD INI: Handle success dan trigger refresh
  Future<void> _handleSuccessAndReturn() async {
    if (!mounted) return;

    // STEP 1: Trigger refresh di PresensiProvider
    // Ini akan mem-fetch data terbaru dari backend
    try {
      final presensiProvider = Provider.of<PresensiProvider>(
        context,
        listen: false,
      );
      await presensiProvider.loadPresensiData();
    } catch (e) {
      debugPrint('Error refreshing presensi data: $e');
    }

    if (!mounted) return;

    // STEP 2: Pop hingga kembali ke HomePage
    // Navigator.pop() dipanggil 3 kali:
    // 1. Close SelfiePage
    // 2. Close AbsensiPage
    // 3. Kembali ke HomePage (dalam MainApp dengan PageView)

    // Cara yang lebih aman: gunakan named route atau popUntil
    Navigator.of(context).popUntil((route) {
      // Pop sampai ke route MainApp (HomePage)
      // Cek apakah route name adalah home atau tidak ada name (root)
      return route.settings.name == null ||
          route.settings.name == '/home' ||
          route.isFirst;
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _errorMessage != null
          ? _buildErrorState()
          : !_isCameraInitialized
          ? _buildLoadingState()
          : _buildCameraView(),
    );
  }

  Widget _buildErrorState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _initializeCamera();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Kembali',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Menyiapkan kamera...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return CameraPreview(_controller!);
            } else {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
          },
        ),

        // Top bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.mode == 'masuk'
                            ? 'Presensi Masuk'
                            : 'Presensi Pulang',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Column(
                children: [
                  // GPS status
                  if (_isGettingLocation || _currentPosition == null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                          const SizedBox(width: 8),
                          const Text(
                            'Mendapatkan lokasi GPS...',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                  // Capture button
                  GestureDetector(
                    onTap: _isSubmitting ? null : _takePicture,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isSubmitting ? Colors.grey : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: _isSubmitting
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isSubmitting
                        ? 'Mengirim presensi...'
                        : 'Ketuk untuk ambil foto',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
