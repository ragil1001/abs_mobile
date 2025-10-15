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
  suspiciousGpsData,
  unnaturalMovement,
  fakeGpsApp,
  lowAccuracy, // Tetap gunakan nama lama untuk kompatibilitas
  suspiciousSpeed,
}

/// Model hasil deteksi dengan severity level
class FakeGpsDetectionResult {
  final bool isSuspicious;
  final List<FakeGpsDetectionType> detections;
  final String message;
  final bool isDeveloperModeActive;
  final int suspicionScore; // 0-100

  FakeGpsDetectionResult({
    required this.isSuspicious,
    required this.detections,
    required this.message,
    required this.isDeveloperModeActive,
    required this.suspicionScore,
  });

  // Block jika developer mode ATAU suspicion score > 60
  bool get shouldBlockAccess => isDeveloperModeActive || suspicionScore > 60;
}

/// Service untuk mendeteksi fake GPS dengan optimized strategies
class FakeGpsDetectorService {
  static final FakeGpsDetectorService _instance =
      FakeGpsDetectorService._internal();
  factory FakeGpsDetectorService() => _instance;
  FakeGpsDetectorService._internal();

  Position? _previousPosition;
  DateTime? _previousTime;
  final List<double> _accuracyHistory = [];
  final List<double> _speedHistory = [];
  final List<Position> _positionHistory = [];

  // Thresholds yang lebih reasonable
  static const int _minHistorySize = 5;
  static const int _maxHistorySize = 15;
  static const double _suspiciousAccuracyThreshold = 1.5; // Turun dari 2.0
  static const double _excellentAccuracyThreshold = 2.5; // Turun dari 3.0
  static const double _maxReasonableSpeed = 60.0; // Naik dari 50 m/s
  static const double _teleportDistance = 150.0; // Naik dari 100m
  static const int _teleportTimeWindow = 8; // Turun dari 10s
  static const int _frozenPositionTime = 45; // Naik dari 30s

  /// STRATEGY 1: Developer Mode Detection (TETAP WAJIB) ⭐⭐⭐
  Future<bool> isDeveloperModeActive() async {
    if (!Platform.isAndroid) return false;

    try {
      return await SafeDevice.isDevelopmentModeEnable;
    } catch (e) {
      debugPrint('Error checking developer mode: $e');
      return false;
    }
  }

  /// STRATEGY 2: Mock Location Detection ⭐⭐⭐ (STRICT MODE)
  ///
  /// Deteksi mock location dengan policy KETAT:
  /// - Mock location HANYA bisa diaktifkan via Developer Options
  /// - Keberadaan mock location = indikasi kuat fake GPS attempt
  /// - Block SELALU jika terdeteksi, tanpa mempertimbangkan use case legitimate
  ///
  /// Edge case yang di-handle:
  /// 1. Dev mode ON + Mock ON = Standard fake GPS (blocked by dev mode)
  /// 2. Dev mode OFF + Mock ON = Bypass attempt (score +70, instant block)
  Future<bool> isMockLocationEnabled() async {
    if (!Platform.isAndroid) return false;

    try {
      return await SafeDevice.isMockLocation;
    } catch (e) {
      debugPrint('Error checking mock location: $e');
      return false;
    }
  }

  /// STRATEGY 3: GPS Data Validation (OPTIMIZED) ⭐⭐⭐
  int validateGpsData(Position position) {
    int suspicionPoints = 0;

    // 1. Altitude check - lebih lenient
    // Hanya suspicious jika altitude = 0 DAN akurasi SANGAT tinggi DAN ada movement
    if (position.altitude == 0.0 &&
        position.accuracy < 3.0 &&
        position.speed > 1.0) {
      debugPrint(
        '⚠️ Suspicious: Altitude=0 dengan movement dan akurasi tinggi',
      );
      suspicionPoints += 15;
    }

    // 2. Speed validation - lebih reasonable
    if (position.speed < 0) {
      debugPrint('⚠️ Speed negatif (invalid)');
      suspicionPoints += 30;
    }

    // 3. Heading validation
    if (position.heading < 0 || position.heading > 360) {
      debugPrint('⚠️ Heading tidak valid: ${position.heading}');
      suspicionPoints += 20;
    }

    // 4. SpeedAccuracy check - hanya jika ada movement signifikan
    if (position.speedAccuracy == 0.0 && position.speed > 5.0) {
      debugPrint('⚠️ SpeedAccuracy = 0 dengan speed tinggi (mencurigakan)');
      suspicionPoints += 15;
    }

    // 5. Timestamp validation - cek jika timestamp tidak masuk akal
    final now = DateTime.now();
    final posTime = position.timestamp;
    final timeDiff = now.difference(posTime).abs();

    if (timeDiff.inMinutes > 5) {
      debugPrint('⚠️ Timestamp GPS terlalu jauh dari waktu sekarang');
      suspicionPoints += 25;
    }

    return suspicionPoints;
  }

  /// STRATEGY 4: Accuracy Pattern Analysis (OPTIMIZED) ⭐⭐
  int analyzeAccuracyPattern(Position position) {
    _accuracyHistory.add(position.accuracy);

    if (_accuracyHistory.length > _maxHistorySize) {
      _accuracyHistory.removeAt(0);
    }

    if (_accuracyHistory.length < _minHistorySize) {
      return 0; // Belum cukup data
    }

    int suspicionPoints = 0;

    final avgAccuracy =
        _accuracyHistory.reduce((a, b) => a + b) / _accuracyHistory.length;

    // Hitung variance
    final variance =
        _accuracyHistory
            .map((acc) => (acc - avgAccuracy) * (acc - avgAccuracy))
            .reduce((a, b) => a + b) /
        _accuracyHistory.length;

    // Akurasi TERLALU sempurna secara konsisten (red flag besar)
    if (avgAccuracy < _excellentAccuracyThreshold && variance < 0.3) {
      debugPrint(
        '⚠️ Akurasi terlalu konsisten dan sempurna: avg=$avgAccuracy, var=$variance',
      );
      suspicionPoints += 25;
    }

    // Akurasi SANGAT tinggi di single point (bisa false positive, jadi point lebih kecil)
    if (position.accuracy < _suspiciousAccuracyThreshold) {
      debugPrint('⚠️ Akurasi sangat tinggi: ${position.accuracy}');
      suspicionPoints += 10;
    }

    // Akurasi terlalu buruk (> 150m)
    if (position.accuracy > 150.0) {
      debugPrint('⚠️ Akurasi terlalu buruk: ${position.accuracy}');
      suspicionPoints += 15;
    }

    return suspicionPoints;
  }

  /// STRATEGY 5: Movement Pattern Analysis (OPTIMIZED) ⭐⭐⭐
  int analyzeMovementPattern(Position currentPosition) {
    _positionHistory.add(currentPosition);

    if (_positionHistory.length > _maxHistorySize) {
      _positionHistory.removeAt(0);
    }

    if (_previousPosition == null || _previousTime == null) {
      _previousPosition = currentPosition;
      _previousTime = DateTime.now();
      return 0;
    }

    int suspicionPoints = 0;

    final distance = Geolocator.distanceBetween(
      _previousPosition!.latitude,
      _previousPosition!.longitude,
      currentPosition.latitude,
      currentPosition.longitude,
    );

    final timeDiff = DateTime.now().difference(_previousTime!).inSeconds;

    _previousPosition = currentPosition;
    _previousTime = DateTime.now();

    if (timeDiff < 3) return 0; // Terlalu cepat untuk dianalisis

    final calculatedSpeed = distance / timeDiff;

    // 1. Kecepatan sangat tinggi (lebih lenient)
    if (calculatedSpeed > _maxReasonableSpeed) {
      debugPrint(
        '⚠️ Kecepatan tidak wajar: ${calculatedSpeed.toStringAsFixed(2)} m/s',
      );
      suspicionPoints += 30;
    }

    // 2. Teleportasi: jarak besar dalam waktu singkat
    if (distance > _teleportDistance && timeDiff < _teleportTimeWindow) {
      debugPrint(
        '⚠️ Teleportasi: ${distance.toStringAsFixed(0)}m dalam ${timeDiff}s',
      );
      suspicionPoints += 35;
    }

    // 3. Frozen position - HANYA jika ada history movement sebelumnya
    if (distance == 0.0 && timeDiff > _frozenPositionTime) {
      // Cek apakah sebelumnya ada movement
      if (_positionHistory.length >= 3) {
        final hadPreviousMovement = _checkPreviousMovement();
        if (hadPreviousMovement) {
          debugPrint('⚠️ Posisi tiba-tiba frozen setelah movement');
          suspicionPoints += 20;
        }
      }
    }

    // 4. Pattern analysis - perubahan mendadak dalam trajectory
    if (_positionHistory.length >= 5) {
      final trajectoryScore = _analyzeTrajectoryConsistency();
      suspicionPoints += trajectoryScore;
    }

    return suspicionPoints;
  }

  /// Helper: Check if there was movement in previous positions
  bool _checkPreviousMovement() {
    if (_positionHistory.length < 3) return false;

    for (
      int i = _positionHistory.length - 3;
      i < _positionHistory.length - 1;
      i++
    ) {
      final dist = Geolocator.distanceBetween(
        _positionHistory[i].latitude,
        _positionHistory[i].longitude,
        _positionHistory[i + 1].latitude,
        _positionHistory[i + 1].longitude,
      );
      if (dist > 5.0) return true; // Ada movement > 5m
    }
    return false;
  }

  /// Helper: Analyze trajectory consistency
  int _analyzeTrajectoryConsistency() {
    final recentPositions = _positionHistory.sublist(
      _positionHistory.length - 5,
    );

    final speeds = <double>[];
    for (int i = 0; i < recentPositions.length - 1; i++) {
      final dist = Geolocator.distanceBetween(
        recentPositions[i].latitude,
        recentPositions[i].longitude,
        recentPositions[i + 1].latitude,
        recentPositions[i + 1].longitude,
      );
      final time = recentPositions[i + 1].timestamp
          .difference(recentPositions[i].timestamp)
          .inSeconds;
      if (time > 0) {
        speeds.add(dist / time);
      }
    }

    if (speeds.length < 3) return 0;

    // Cek perubahan speed yang sangat drastis
    for (int i = 0; i < speeds.length - 1; i++) {
      final speedChange = (speeds[i + 1] - speeds[i]).abs();
      // Perubahan speed > 20 m/s dalam 1 update (accelerasi tidak natural)
      if (speedChange > 20.0) {
        debugPrint('⚠️ Perubahan kecepatan sangat drastis');
        return 15;
      }
    }

    return 0;
  }

  /// STRATEGY 6: Speed Pattern Analysis (OPTIMIZED) ⭐⭐
  int analyzeSpeedPattern(Position position) {
    _speedHistory.add(position.speed);

    if (_speedHistory.length > _maxHistorySize) {
      _speedHistory.removeAt(0);
    }

    if (_speedHistory.length < _minHistorySize) {
      return 0;
    }

    int suspicionPoints = 0;

    // Speed selalu PERSIS sama (bukan hanya 0) - ini sangat mencurigakan
    final allIdentical = _speedHistory.every((s) => s == _speedHistory.first);

    if (allIdentical && position.speed > 0.5) {
      debugPrint('⚠️ Speed selalu identik: ${position.speed}');
      suspicionPoints += 20;
    }

    // Cek jika speed reported vs calculated speed sangat berbeda
    if (_previousPosition != null && _previousTime != null) {
      final distance = Geolocator.distanceBetween(
        _previousPosition!.latitude,
        _previousPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      final timeDiff = DateTime.now().difference(_previousTime!).inSeconds;

      if (timeDiff >= 3) {
        final calculatedSpeed = distance / timeDiff;
        final speedDiff = (position.speed - calculatedSpeed).abs();

        // Perbedaan > 10 m/s antara reported dan calculated
        if (speedDiff > 10.0) {
          debugPrint(
            '⚠️ Speed mismatch: reported=${position.speed}, '
            'calculated=$calculatedSpeed',
          );
          suspicionPoints += 15;
        }
      }
    }

    return suspicionPoints;
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
      'com.blogspot.newapphorizons.fakelocation',
    ];

    try {
      final installedApps = await InstalledApps.getInstalledApps(false, true);
      final fakeAppsFound = <String>[];

      for (final app in installedApps) {
        final packageName = app.packageName.toLowerCase();

        // Lebih spesifik dalam deteksi
        if ((packageName.contains('fake') && packageName.contains('gps')) ||
            (packageName.contains('fake') &&
                packageName.contains('location')) ||
            (packageName.contains('mock') &&
                packageName.contains('location'))) {
          fakeAppsFound.add(app.name);
        }

        for (final fakePackage in fakeGpsPackages) {
          if (packageName == fakePackage.toLowerCase()) {
            if (!fakeAppsFound.contains(app.name)) {
              fakeAppsFound.add(app.name);
            }
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

  /// Main detection - Score-based system
  Future<FakeGpsDetectionResult> detectFakeGps(Position position) async {
    final detections = <FakeGpsDetectionType>[];
    final messages = <String>[];
    int totalScore = 0;

    // STRATEGY 1: Developer Mode (INSTANT BLOCK)
    final developerMode = await isDeveloperModeActive();
    if (developerMode) {
      detections.add(FakeGpsDetectionType.developerMode);
      messages.add('Opsi Developer aktif');
      totalScore = 100; // Auto max score
    }

    // STRATEGY 2: Mock Location (KETAT - Always block if detected)
    // Mock location HANYA bisa aktif jika dev mode pernah ON
    // Jadi deteksi mock = indikasi kuat fake GPS attempt
    final mockLocation = await isMockLocationEnabled();
    if (mockLocation) {
      detections.add(FakeGpsDetectionType.mockLocation);

      if (developerMode) {
        // Dev mode ON + Mock ON = standard fake GPS
        messages.add('Mock Location terdeteksi');
      } else {
        // Dev mode OFF tapi Mock ON = bypass attempt (lebih berbahaya)
        messages.add('Mock Location terdeteksi (bypass attempt)');
        totalScore += 70; // Score lebih tinggi untuk bypass attempt
      }
    }

    // STRATEGY 3: GPS Data Validation
    final gpsDataScore = validateGpsData(position);
    if (gpsDataScore > 0) {
      detections.add(FakeGpsDetectionType.suspiciousGpsData);
      totalScore += gpsDataScore;
    }

    // STRATEGY 4: Accuracy Pattern
    final accuracyScore = analyzeAccuracyPattern(position);
    if (accuracyScore > 0) {
      detections.add(FakeGpsDetectionType.lowAccuracy);
      messages.add('Pola akurasi GPS mencurigakan');
      totalScore += accuracyScore;
    }

    // STRATEGY 5: Movement Pattern
    final movementScore = analyzeMovementPattern(position);
    if (movementScore > 0) {
      detections.add(FakeGpsDetectionType.unnaturalMovement);
      messages.add('Pola perpindahan tidak natural');
      totalScore += movementScore;
    }

    // STRATEGY 6: Speed Pattern
    final speedScore = analyzeSpeedPattern(position);
    if (speedScore > 0) {
      detections.add(FakeGpsDetectionType.suspiciousSpeed);
      messages.add('Pola kecepatan mencurigakan');
      totalScore += speedScore;
    }

    // STRATEGY 7: Fake GPS Apps
    final fakeApps = await getInstalledFakeGpsApps();
    if (fakeApps.isNotEmpty) {
      detections.add(FakeGpsDetectionType.fakeGpsApp);
      messages.add('Aplikasi fake GPS: ${fakeApps.first}');
      totalScore += 40;
    }

    // Cap score at 100
    totalScore = totalScore > 100 ? 100 : totalScore;

    final isSuspicious = totalScore > 30; // Threshold untuk menampilkan warning
    final message = messages.isEmpty
        ? 'Lokasi GPS valid (Score: $totalScore)'
        : '${messages.join('\n')} (Score: $totalScore)';

    debugPrint('=== FAKE GPS DETECTION ===');
    debugPrint('Total Suspicion Score: $totalScore/100');
    debugPrint('Block Access: ${totalScore > 60 || developerMode}');
    debugPrint('Detections: ${detections.join(", ")}');
    debugPrint('========================');

    return FakeGpsDetectionResult(
      isSuspicious: isSuspicious,
      detections: detections,
      message: message,
      isDeveloperModeActive: developerMode,
      suspicionScore: totalScore,
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
    _positionHistory.clear();
  }
}
