import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_device/safe_device.dart';
import 'package:installed_apps/installed_apps.dart';

/// Enum untuk jenis deteksi fake GPS
enum FakeGpsDetectionType {
  developerMode,
  mockLocation,
  suspiciousGpsData,
  unnaturalMovement,
  fakeGpsApp,
  lowAccuracy,
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

  // ✅ CACHE untuk mempercepat repeated checks
  bool? _cachedDeveloperMode;
  DateTime? _cachedDeveloperModeTime;
  List<String>? _cachedFakeGpsApps;
  DateTime? _cachedFakeGpsAppsTime;

  // Thresholds yang lebih reasonable
  static const int _minHistorySize = 5;
  static const int _maxHistorySize = 15;
  static const double _suspiciousAccuracyThreshold = 1.5;
  static const double _excellentAccuracyThreshold = 2.5;
  static const double _maxReasonableSpeed = 60.0;
  static const double _teleportDistance = 150.0;
  static const int _teleportTimeWindow = 8;
  static const int _frozenPositionTime = 45;

  /// ✅ OPTIMIZED: Cache developer mode check (recheck every 30 seconds)
  Future<bool> isDeveloperModeActive() async {
    if (!Platform.isAndroid) return false;

    // Check cache validity
    if (_cachedDeveloperMode != null && _cachedDeveloperModeTime != null) {
      final cacheAge = DateTime.now().difference(_cachedDeveloperModeTime!);
      if (cacheAge.inSeconds < 30) {
        return _cachedDeveloperMode!;
      }
    }

    try {
      final result = await SafeDevice.isDevelopmentModeEnable;
      _cachedDeveloperMode = result;
      _cachedDeveloperModeTime = DateTime.now();
      return result;
    } catch (e) {
      debugPrint('Error checking developer mode: $e');
      return false;
    }
  }

  /// STRATEGY 2: Mock Location Detection (STRICT MODE)
  Future<bool> isMockLocationEnabled() async {
    if (!Platform.isAndroid) return false;

    try {
      return await SafeDevice.isMockLocation;
    } catch (e) {
      debugPrint('Error checking mock location: $e');
      return false;
    }
  }

  /// STRATEGY 3: GPS Data Validation (OPTIMIZED)
  int validateGpsData(Position position) {
    int suspicionPoints = 0;

    // 1. Altitude check - lebih lenient
    if (position.altitude == 0.0 &&
        position.accuracy < 3.0 &&
        position.speed > 1.0) {
      suspicionPoints += 15;
    }

    // 2. Speed validation
    if (position.speed < 0) {
      suspicionPoints += 30;
    }

    // 3. Heading validation
    if (position.heading < 0 || position.heading > 360) {
      suspicionPoints += 20;
    }

    // 4. SpeedAccuracy check
    if (position.speedAccuracy == 0.0 && position.speed > 5.0) {
      suspicionPoints += 15;
    }

    // 5. Timestamp validation
    final now = DateTime.now();
    final posTime = position.timestamp;
    final timeDiff = now.difference(posTime).abs();

    if (timeDiff.inMinutes > 5) {
      suspicionPoints += 25;
    }

    return suspicionPoints;
  }

  /// STRATEGY 4: Accuracy Pattern Analysis (OPTIMIZED)
  int analyzeAccuracyPattern(Position position) {
    _accuracyHistory.add(position.accuracy);

    if (_accuracyHistory.length > _maxHistorySize) {
      _accuracyHistory.removeAt(0);
    }

    if (_accuracyHistory.length < _minHistorySize) {
      return 0;
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

    // Akurasi TERLALU sempurna
    if (avgAccuracy < _excellentAccuracyThreshold && variance < 0.3) {
      suspicionPoints += 25;
    }

    // Akurasi SANGAT tinggi di single point
    if (position.accuracy < _suspiciousAccuracyThreshold) {
      suspicionPoints += 10;
    }

    // Akurasi terlalu buruk
    if (position.accuracy > 150.0) {
      suspicionPoints += 15;
    }

    return suspicionPoints;
  }

  /// STRATEGY 5: Movement Pattern Analysis (OPTIMIZED)
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

    if (timeDiff < 3) return 0;

    final calculatedSpeed = distance / timeDiff;

    // 1. Kecepatan sangat tinggi
    if (calculatedSpeed > _maxReasonableSpeed) {
      suspicionPoints += 30;
    }

    // 2. Teleportasi
    if (distance > _teleportDistance && timeDiff < _teleportTimeWindow) {
      suspicionPoints += 35;
    }

    // 3. Frozen position
    if (distance == 0.0 && timeDiff > _frozenPositionTime) {
      if (_positionHistory.length >= 3) {
        final hadPreviousMovement = _checkPreviousMovement();
        if (hadPreviousMovement) {
          suspicionPoints += 20;
        }
      }
    }

    // 4. Pattern analysis
    if (_positionHistory.length >= 5) {
      final trajectoryScore = _analyzeTrajectoryConsistency();
      suspicionPoints += trajectoryScore;
    }

    return suspicionPoints;
  }

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
      if (dist > 5.0) return true;
    }
    return false;
  }

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

    for (int i = 0; i < speeds.length - 1; i++) {
      final speedChange = (speeds[i + 1] - speeds[i]).abs();
      if (speedChange > 20.0) {
        return 15;
      }
    }

    return 0;
  }

  /// STRATEGY 6: Speed Pattern Analysis (OPTIMIZED)
  int analyzeSpeedPattern(Position position) {
    _speedHistory.add(position.speed);

    if (_speedHistory.length > _maxHistorySize) {
      _speedHistory.removeAt(0);
    }

    if (_speedHistory.length < _minHistorySize) {
      return 0;
    }

    int suspicionPoints = 0;

    final allIdentical = _speedHistory.every((s) => s == _speedHistory.first);

    if (allIdentical && position.speed > 0.5) {
      suspicionPoints += 20;
    }

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

        if (speedDiff > 10.0) {
          suspicionPoints += 15;
        }
      }
    }

    return suspicionPoints;
  }

  /// ✅ OPTIMIZED: Cache fake GPS apps check (recheck every 60 seconds)
  Future<List<String>> getInstalledFakeGpsApps() async {
    if (!Platform.isAndroid) return [];

    // Check cache validity
    if (_cachedFakeGpsApps != null && _cachedFakeGpsAppsTime != null) {
      final cacheAge = DateTime.now().difference(_cachedFakeGpsAppsTime!);
      if (cacheAge.inSeconds < 60) {
        return _cachedFakeGpsApps!;
      }
    }

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

      // Cache result
      _cachedFakeGpsApps = fakeAppsFound;
      _cachedFakeGpsAppsTime = DateTime.now();

      if (fakeAppsFound.isNotEmpty) {
        debugPrint('⚠️ Fake GPS apps: ${fakeAppsFound.join(", ")}');
      }

      return fakeAppsFound;
    } catch (e) {
      debugPrint('Error checking installed apps: $e');
      return [];
    }
  }

  /// ✅ OPTIMIZED: Main detection dengan parallel execution
  Future<FakeGpsDetectionResult> detectFakeGps(Position position) async {
    final detections = <FakeGpsDetectionType>[];
    final messages = <String>[];
    int totalScore = 0;

    // ✅ CRITICAL: Run critical checks in parallel
    final criticalChecks = await Future.wait([
      isDeveloperModeActive(),
      isMockLocationEnabled(),
    ]);

    final developerMode = criticalChecks[0];
    final mockLocation = criticalChecks[1];

    // STRATEGY 1: Developer Mode (INSTANT BLOCK)
    if (developerMode) {
      detections.add(FakeGpsDetectionType.developerMode);
      messages.add('Opsi Developer aktif');
      totalScore = 100; // Auto max score
    }

    // STRATEGY 2: Mock Location (KETAT)
    if (mockLocation) {
      detections.add(FakeGpsDetectionType.mockLocation);

      if (developerMode) {
        messages.add('Mock Location terdeteksi');
      } else {
        messages.add('Mock Location terdeteksi (bypass attempt)');
        totalScore += 70;
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

    // STRATEGY 7: Fake GPS Apps (run in background, don't block)
    getInstalledFakeGpsApps().then((fakeApps) {
      if (fakeApps.isNotEmpty) {
        // This will be caught on next detection cycle
        debugPrint('⚠️ Fake GPS apps detected: ${fakeApps.join(", ")}');
      }
    });

    // Use cached result if available
    if (_cachedFakeGpsApps != null && _cachedFakeGpsApps!.isNotEmpty) {
      detections.add(FakeGpsDetectionType.fakeGpsApp);
      messages.add('Aplikasi fake GPS: ${_cachedFakeGpsApps!.first}');
      totalScore += 40;
    }

    // Cap score at 100
    totalScore = totalScore > 100 ? 100 : totalScore;

    final isSuspicious = totalScore > 30;
    final message = messages.isEmpty
        ? 'Lokasi GPS valid (Score: $totalScore)'
        : '${messages.join('\n')} (Score: $totalScore)';

    if (kDebugMode && totalScore > 0) {
      debugPrint('=== FAKE GPS DETECTION ===');
      debugPrint('Total Suspicion Score: $totalScore/100');
      debugPrint('Block Access: ${totalScore > 60 || developerMode}');
      debugPrint('Detections: ${detections.join(", ")}');
      debugPrint('========================');
    }

    return FakeGpsDetectionResult(
      isSuspicious: isSuspicious,
      detections: detections,
      message: message,
      isDeveloperModeActive: developerMode,
      suspicionScore: totalScore,
    );
  }

  /// Quick check untuk developer mode (with cache)
  Future<bool> quickDeveloperModeCheck() async {
    return await isDeveloperModeActive();
  }

  /// Reset service state
  void reset() {
    _previousPosition = null;
    _previousTime = null;
    _accuracyHistory.clear();
    _speedHistory.clear();
    _positionHistory.clear();

    // Don't clear cache on reset - it's still valid
    // Only clear if explicitly needed
  }

  /// Clear all caches (call when needed, e.g., on logout)
  void clearCache() {
    _cachedDeveloperMode = null;
    _cachedDeveloperModeTime = null;
    _cachedFakeGpsApps = null;
    _cachedFakeGpsAppsTime = null;
  }
}
