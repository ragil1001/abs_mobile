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

  // ✅ OPTIMIZED CACHE - lebih agresif
  bool? _cachedDeveloperMode;
  DateTime? _cachedDeveloperModeTime;
  bool? _cachedMockLocation;
  DateTime? _cachedMockLocationTime;
  List<String>? _cachedFakeGpsApps;
  DateTime? _cachedFakeGpsAppsTime;

  // Cache duration - lebih lama untuk performa
  static const int _developerModeCacheDuration = 60; // 60 detik
  static const int _mockLocationCacheDuration = 30; // 30 detik
  static const int _fakeGpsAppsCacheDuration = 120; // 2 menit

  // Thresholds
  static const int _minHistorySize = 5;
  static const int _maxHistorySize = 15;
  static const double _suspiciousAccuracyThreshold = 1.5;
  static const double _excellentAccuracyThreshold = 2.5;
  static const double _maxReasonableSpeed = 60.0;
  static const double _teleportDistance = 150.0;
  static const int _teleportTimeWindow = 8;
  static const int _frozenPositionTime = 45;

  /// ✅ SUPER OPTIMIZED: Developer mode check dengan cache agresif
  Future<bool> isDeveloperModeActive() async {
    if (!Platform.isAndroid) return false;

    // Check cache validity (60 detik)
    if (_cachedDeveloperMode != null && _cachedDeveloperModeTime != null) {
      final cacheAge = DateTime.now().difference(_cachedDeveloperModeTime!);
      if (cacheAge.inSeconds < _developerModeCacheDuration) {
        debugPrint('✅ Using cached developer mode: $_cachedDeveloperMode');
        return _cachedDeveloperMode!;
      }
    }

    try {
      final stopwatch = Stopwatch()..start();
      final result = await SafeDevice.isDevelopmentModeEnable;
      stopwatch.stop();

      _cachedDeveloperMode = result;
      _cachedDeveloperModeTime = DateTime.now();

      debugPrint(
        '✅ Developer mode check: $result (${stopwatch.elapsedMilliseconds}ms)',
      );
      return result;
    } catch (e) {
      debugPrint('❌ Error checking developer mode: $e');
      // Return cached value if available, otherwise false
      return _cachedDeveloperMode ?? false;
    }
  }

  /// ✅ OPTIMIZED: Mock Location dengan cache
  Future<bool> isMockLocationEnabled() async {
    if (!Platform.isAndroid) return false;

    // Check cache validity (30 detik)
    if (_cachedMockLocation != null && _cachedMockLocationTime != null) {
      final cacheAge = DateTime.now().difference(_cachedMockLocationTime!);
      if (cacheAge.inSeconds < _mockLocationCacheDuration) {
        debugPrint('✅ Using cached mock location: $_cachedMockLocation');
        return _cachedMockLocation!;
      }
    }

    try {
      final stopwatch = Stopwatch()..start();
      final result = await SafeDevice.isMockLocation;
      stopwatch.stop();

      _cachedMockLocation = result;
      _cachedMockLocationTime = DateTime.now();

      debugPrint(
        '✅ Mock location check: $result (${stopwatch.elapsedMilliseconds}ms)',
      );
      return result;
    } catch (e) {
      debugPrint('❌ Error checking mock location: $e');
      // Return cached value if available, otherwise false
      return _cachedMockLocation ?? false;
    }
  }

  /// STRATEGY 3: GPS Data Validation (FAST - no async)
  int validateGpsData(Position position) {
    int suspicionPoints = 0;

    // 1. Altitude check
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

  /// STRATEGY 4: Accuracy Pattern Analysis (FAST - no async)
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

    final variance =
        _accuracyHistory
            .map((acc) => (acc - avgAccuracy) * (acc - avgAccuracy))
            .reduce((a, b) => a + b) /
        _accuracyHistory.length;

    if (avgAccuracy < _excellentAccuracyThreshold && variance < 0.3) {
      suspicionPoints += 25;
    }

    if (position.accuracy < _suspiciousAccuracyThreshold) {
      suspicionPoints += 10;
    }

    if (position.accuracy > 150.0) {
      suspicionPoints += 15;
    }

    return suspicionPoints;
  }

  /// STRATEGY 5: Movement Pattern Analysis (FAST - no async)
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

    if (calculatedSpeed > _maxReasonableSpeed) {
      suspicionPoints += 30;
    }

    if (distance > _teleportDistance && timeDiff < _teleportTimeWindow) {
      suspicionPoints += 35;
    }

    if (distance == 0.0 && timeDiff > _frozenPositionTime) {
      if (_positionHistory.length >= 3) {
        final hadPreviousMovement = _checkPreviousMovement();
        if (hadPreviousMovement) {
          suspicionPoints += 20;
        }
      }
    }

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

  /// STRATEGY 6: Speed Pattern Analysis (FAST - no async)
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

  /// ✅ SUPER OPTIMIZED: Fake GPS apps check - run in background
  Future<List<String>> getInstalledFakeGpsApps() async {
    if (!Platform.isAndroid) return [];

    // Check cache validity (120 detik)
    if (_cachedFakeGpsApps != null && _cachedFakeGpsAppsTime != null) {
      final cacheAge = DateTime.now().difference(_cachedFakeGpsAppsTime!);
      if (cacheAge.inSeconds < _fakeGpsAppsCacheDuration) {
        debugPrint(
          '✅ Using cached fake GPS apps: ${_cachedFakeGpsApps!.length} found',
        );
        return _cachedFakeGpsApps!;
      }
    }

    // Run in background - don't block main detection
    _checkFakeGpsAppsBackground();

    // Return cached result immediately if available
    return _cachedFakeGpsApps ?? [];
  }

  /// ✅ NEW: Background check untuk fake GPS apps (non-blocking)
  void _checkFakeGpsAppsBackground() {
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

    InstalledApps.getInstalledApps(false, true)
        .then((installedApps) {
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
            debugPrint(
              '⚠️ Fake GPS apps detected: ${fakeAppsFound.join(", ")}',
            );
          } else {
            debugPrint('✅ No fake GPS apps detected');
          }
        })
        .catchError((e) {
          debugPrint('❌ Error checking installed apps: $e');
          // Keep old cache on error
        });
  }

  /// ✅ SUPER OPTIMIZED: Main detection dengan fast-first strategy
  Future<FakeGpsDetectionResult> detectFakeGps(Position position) async {
    final stopwatch = Stopwatch()..start();

    final detections = <FakeGpsDetectionType>[];
    final messages = <String>[];
    int totalScore = 0;

    // ✅ STRATEGY: Critical checks first (with cache), non-critical after

    // STEP 1: Fast synchronous checks (no await)
    final gpsDataScore = validateGpsData(position);
    if (gpsDataScore > 0) {
      detections.add(FakeGpsDetectionType.suspiciousGpsData);
      totalScore += gpsDataScore;
    }

    final accuracyScore = analyzeAccuracyPattern(position);
    if (accuracyScore > 0) {
      detections.add(FakeGpsDetectionType.lowAccuracy);
      messages.add('Pola akurasi GPS mencurigakan');
      totalScore += accuracyScore;
    }

    final movementScore = analyzeMovementPattern(position);
    if (movementScore > 0) {
      detections.add(FakeGpsDetectionType.unnaturalMovement);
      messages.add('Pola perpindahan tidak natural');
      totalScore += movementScore;
    }

    final speedScore = analyzeSpeedPattern(position);
    if (speedScore > 0) {
      detections.add(FakeGpsDetectionType.suspiciousSpeed);
      messages.add('Pola kecepatan mencurigakan');
      totalScore += speedScore;
    }

    // STEP 2: Critical async checks (with cache - should be fast)
    final criticalChecks = await Future.wait([
      isDeveloperModeActive(),
      isMockLocationEnabled(),
    ]);

    final developerMode = criticalChecks[0];
    final mockLocation = criticalChecks[1];

    // Developer Mode (INSTANT BLOCK)
    if (developerMode) {
      detections.add(FakeGpsDetectionType.developerMode);
      messages.add('Opsi Developer aktif');
      totalScore = 100; // Auto max score
    }

    // Mock Location (STRICT)
    if (mockLocation) {
      detections.add(FakeGpsDetectionType.mockLocation);

      if (developerMode) {
        messages.add('Mock Location terdeteksi');
      } else {
        messages.add('Mock Location terdeteksi (bypass attempt)');
        totalScore += 70;
      }
    }

    // STEP 3: Non-critical async checks (from cache or background)
    final fakeApps =
        await getInstalledFakeGpsApps(); // Returns cached immediately
    if (fakeApps.isNotEmpty) {
      detections.add(FakeGpsDetectionType.fakeGpsApp);
      messages.add('Aplikasi fake GPS: ${fakeApps.first}');
      totalScore += 40;
    }

    // Cap score at 100
    totalScore = totalScore > 100 ? 100 : totalScore;

    final isSuspicious = totalScore > 30;
    final message = messages.isEmpty
        ? 'Lokasi GPS valid (Score: $totalScore)'
        : '${messages.join('\n')} (Score: $totalScore)';

    stopwatch.stop();

    debugPrint(
      '🔍 FAKE GPS DETECTION COMPLETED in ${stopwatch.elapsedMilliseconds}ms',
    );
    debugPrint('   Total Score: $totalScore/100');
    debugPrint('   Block Access: ${totalScore > 60 || developerMode}');
    debugPrint('   Detections: ${detections.length}');

    return FakeGpsDetectionResult(
      isSuspicious: isSuspicious,
      detections: detections,
      message: message,
      isDeveloperModeActive: developerMode,
      suspicionScore: totalScore,
    );
  }

  /// Quick check untuk developer mode (cached)
  Future<bool> quickDeveloperModeCheck() async {
    return await isDeveloperModeActive();
  }

  /// Reset service state (tapi keep cache!)
  void reset() {
    _previousPosition = null;
    _previousTime = null;
    _accuracyHistory.clear();
    _speedHistory.clear();
    _positionHistory.clear();

    // ✅ KEEP CACHE - masih valid!
    debugPrint('✅ FakeGpsDetector reset (cache preserved)');
  }

  /// Clear all caches (hanya saat logout atau force refresh)
  void clearCache() {
    _cachedDeveloperMode = null;
    _cachedDeveloperModeTime = null;
    _cachedMockLocation = null;
    _cachedMockLocationTime = null;
    _cachedFakeGpsApps = null;
    _cachedFakeGpsAppsTime = null;

    debugPrint('🗑️ FakeGpsDetector cache cleared');
  }

  /// ✅ NEW: Pre-warm cache (panggil saat app start)
  Future<void> prewarmCache() async {
    debugPrint('🔥 Prewarming FakeGpsDetector cache...');
    await Future.wait([isDeveloperModeActive(), isMockLocationEnabled()]);
    _checkFakeGpsAppsBackground();
    debugPrint('✅ Cache prewarmed');
  }
}
