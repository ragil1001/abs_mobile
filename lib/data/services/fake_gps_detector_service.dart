import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_device/safe_device.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

/// Enum untuk jenis deteksi fake GPS
enum FakeGpsDetectionType {
  developerMode,
  mockLocation,
  lowAccuracy,
  unnaturalMovement,
  fakeGpsApp,
  invalidGpsProvider,
  suspiciousSpeed,
}

/// Model hasil deteksi
class FakeGpsDetectionResult {
  final bool isSuspicious;
  final List<FakeGpsDetectionType> detections;
  final String message;
  final bool isDeveloperModeActive;

  FakeGpsDetectionResult({
    required this.isSuspicious,
    required this.detections,
    required this.message,
    required this.isDeveloperModeActive,
  });

  bool get shouldBlockAccess => isDeveloperModeActive || isSuspicious;
}

/// Service untuk mendeteksi fake GPS dengan multiple strategies
class FakeGpsDetectorService {
  static final FakeGpsDetectorService _instance =
      FakeGpsDetectorService._internal();
  factory FakeGpsDetectorService() => _instance;
  FakeGpsDetectorService._internal();

  Position? _previousPosition;
  DateTime? _previousTime;
  List<double> _accuracyHistory = [];
  List<double> _speedHistory = [];

  /// STRATEGY 1: Developer Mode Detection (WAJIB) ⭐⭐⭐
  Future<bool> isDeveloperModeActive() async {
    if (!Platform.isAndroid) return false;

    try {
      return await SafeDevice.isDevelopmentModeEnable;
    } catch (e) {
      debugPrint('Error checking developer mode: $e');
      return false;
    }
  }

  /// STRATEGY 2: Mock Location Detection ⭐⭐⭐
  Future<bool> isMockLocationEnabled() async {
    if (!Platform.isAndroid) return false;

    try {
      return await SafeDevice.isMockLocation;
    } catch (e) {
      debugPrint('Error checking mock location: $e');
      return false;
    }
  }

  /// STRATEGY 3: GPS Provider Validation ⭐⭐⭐
  bool isGpsProviderValid(Position position) {
    // Fake GPS sering memiliki karakteristik tidak wajar:

    // 1. Altitude = 0 dengan akurasi tinggi (mencurigakan)
    if (position.altitude == 0.0 && position.accuracy < 5.0) {
      debugPrint('⚠️ Altitude = 0 dengan akurasi tinggi');
      return false;
    }

    // 2. Speed negatif atau tidak masuk akal
    if (position.speed < 0) {
      debugPrint('⚠️ Speed negatif');
      return false;
    }

    // 3. Heading tidak valid
    if (position.heading < 0 || position.heading > 360) {
      debugPrint('⚠️ Heading tidak valid: ${position.heading}');
      return false;
    }

    // 4. SpeedAccuracy terlalu sempurna (untuk Android SDK >= 26)
    if (position.speedAccuracy == 0.0 && position.speed > 0) {
      debugPrint('⚠️ SpeedAccuracy = 0 (mencurigakan)');
      return false;
    }

    return true;
  }

  /// STRATEGY 4: Suspicious Accuracy Pattern ⭐⭐⭐
  bool isSuspiciousAccuracyPattern(Position position) {
    _accuracyHistory.add(position.accuracy);

    // Simpan hanya 10 data terakhir
    if (_accuracyHistory.length > 10) {
      _accuracyHistory.removeAt(0);
    }

    // Akurasi terlalu sempurna secara konsisten (< 3 meter)
    if (_accuracyHistory.length >= 5) {
      final avgAccuracy =
          _accuracyHistory.reduce((a, b) => a + b) / _accuracyHistory.length;

      if (avgAccuracy < 3.0) {
        // Hitung variance
        final variance =
            _accuracyHistory
                .map((acc) => (acc - avgAccuracy) * (acc - avgAccuracy))
                .reduce((a, b) => a + b) /
            _accuracyHistory.length;

        // Variance sangat kecil = akurasi terlalu konsisten (tidak wajar)
        if (variance < 0.5) {
          debugPrint(
            '⚠️ Akurasi terlalu konsisten: avg=$avgAccuracy, var=$variance',
          );
          return true;
        }
      }
    }

    // Akurasi single point terlalu sempurna atau terlalu buruk
    if (position.accuracy < 2.0 || position.accuracy > 100.0) {
      debugPrint('⚠️ Akurasi mencurigakan: ${position.accuracy}');
      return true;
    }

    return false;
  }

  /// STRATEGY 5: Unnatural Movement Detection ⭐⭐⭐
  bool isUnnaturalMovement(Position currentPosition) {
    if (_previousPosition == null || _previousTime == null) {
      _previousPosition = currentPosition;
      _previousTime = DateTime.now();
      return false;
    }

    final distance = Geolocator.distanceBetween(
      _previousPosition!.latitude,
      _previousPosition!.longitude,
      currentPosition.latitude,
      currentPosition.longitude,
    );

    final timeDiff = DateTime.now().difference(_previousTime!).inSeconds;

    _previousPosition = currentPosition;
    _previousTime = DateTime.now();

    if (timeDiff < 3) return false;

    final speed = distance / timeDiff;

    // 1. Kecepatan sangat tinggi (> 50 m/s ≈ 180 km/jam)
    if (speed > 50) {
      debugPrint('⚠️ Kecepatan tidak wajar: ${speed.toStringAsFixed(2)} m/s');
      return true;
    }

    // 2. Teleportasi: jarak > 100m dalam < 10s
    if (distance > 100 && timeDiff < 10) {
      debugPrint(
        '⚠️ Teleportasi: ${distance.toStringAsFixed(0)}m dalam ${timeDiff}s',
      );
      return true;
    }

    // 3. Lokasi sama persis secara berulang (frozen position)
    if (distance == 0.0 && timeDiff > 30) {
      debugPrint('⚠️ Posisi frozen');
      return true;
    }

    return false;
  }

  /// STRATEGY 6: Suspicious Speed Pattern ⭐⭐
  bool isSuspiciousSpeedPattern(Position position) {
    _speedHistory.add(position.speed);

    if (_speedHistory.length > 10) {
      _speedHistory.removeAt(0);
    }

    // Speed selalu 0 atau selalu sama persis
    if (_speedHistory.length >= 5) {
      final allSame = _speedHistory.every((s) => s == _speedHistory.first);

      if (allSame && position.speed > 0) {
        debugPrint('⚠️ Speed selalu sama: ${position.speed}');
        return true;
      }
    }

    return false;
  }

  /// STRATEGY 7: Installed Fake GPS Apps ⭐⭐
  Future<List<String>> getInstalledFakeGpsApps() async {
    if (!Platform.isAndroid) return [];

    final fakeGpsPackages = [
      'com.lexa.fakegps',
      'com.incorporateapps.fakegps.fre',
      'com.blogspot.newapphorizons.fakegps',
      'com.gsmartstudio.fakegps',
      'com.fakegps.mock',
      'com.mock.location',
      'com.lexa.fakegps.new',
      'com.magentagps.location',
      'com.teslacoilsw.launcherfake',
      'ru.gavrikov.mocklocations',
      'com.theappninas.fakegpsjoystick',
      'com.fly.gps',
    ];

    try {
      final installedApps = await InstalledApps.getInstalledApps(false, true);
      final fakeAppsFound = <String>[];

      for (final app in installedApps) {
        final packageName = app.packageName.toLowerCase();

        if (packageName.contains('fake') || packageName.contains('mock')) {
          fakeAppsFound.add(app.name);
        }

        for (final fakePackage in fakeGpsPackages) {
          if (packageName == fakePackage.toLowerCase()) {
            fakeAppsFound.add(app.name);
            break;
          }
        }
      }

      if (fakeAppsFound.isNotEmpty) {
        debugPrint('⚠️ Fake GPS apps: ${fakeAppsFound.join(", ")}');
      }

      return fakeAppsFound;
    } catch (e) {
      debugPrint('Error checking installed apps: $e');
      return [];
    }
  }

  /// Main detection - Gabungan 7 strategi
  Future<FakeGpsDetectionResult> detectFakeGps(Position position) async {
    final detections = <FakeGpsDetectionType>[];
    final messages = <String>[];

    // STRATEGY 1: Developer Mode (PRIORITY TERTINGGI)
    final developerMode = await isDeveloperModeActive();
    if (developerMode) {
      detections.add(FakeGpsDetectionType.developerMode);
      messages.add('Opsi Developer aktif');
    }

    // STRATEGY 2: Mock Location
    final mockLocation = await isMockLocationEnabled();
    if (mockLocation) {
      detections.add(FakeGpsDetectionType.mockLocation);
      messages.add('Mock Location terdeteksi');
    }

    // STRATEGY 3: GPS Provider Validation
    if (!isGpsProviderValid(position)) {
      detections.add(FakeGpsDetectionType.invalidGpsProvider);
      messages.add('GPS provider tidak valid');
    }

    // STRATEGY 4: Suspicious Accuracy Pattern
    if (isSuspiciousAccuracyPattern(position)) {
      detections.add(FakeGpsDetectionType.lowAccuracy);
      messages.add('Pola akurasi GPS mencurigakan');
    }

    // STRATEGY 5: Unnatural Movement
    if (isUnnaturalMovement(position)) {
      detections.add(FakeGpsDetectionType.unnaturalMovement);
      messages.add('Perpindahan lokasi tidak wajar');
    }

    // STRATEGY 6: Suspicious Speed Pattern
    if (isSuspiciousSpeedPattern(position)) {
      detections.add(FakeGpsDetectionType.suspiciousSpeed);
      messages.add('Pola kecepatan mencurigakan');
    }

    // STRATEGY 7: Fake GPS Apps
    final fakeApps = await getInstalledFakeGpsApps();
    if (fakeApps.isNotEmpty) {
      detections.add(FakeGpsDetectionType.fakeGpsApp);
      messages.add('Aplikasi fake GPS: ${fakeApps.first}');
    }

    final isSuspicious = detections.isNotEmpty;
    final message = messages.isEmpty ? 'Lokasi GPS valid' : messages.join('\n');

    return FakeGpsDetectionResult(
      isSuspicious: isSuspicious,
      detections: detections,
      message: message,
      isDeveloperModeActive: developerMode,
    );
  }

  Future<bool> quickDeveloperModeCheck() async {
    return await isDeveloperModeActive();
  }

  void reset() {
    _previousPosition = null;
    _previousTime = null;
    _accuracyHistory.clear();
    _speedHistory.clear();
  }
}
