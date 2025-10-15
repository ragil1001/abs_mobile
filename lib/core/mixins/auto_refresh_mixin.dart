// lib/core/mixins/auto_refresh_mixin.dart
import 'package:flutter/material.dart';

mixin AutoRefreshMixin<T extends StatefulWidget> on State<T> {
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;

  // Override this in your widget
  Future<void> onRefresh();

  // Configurable debounce duration (default 3 seconds)
  Duration get refreshDebounce => const Duration(seconds: 3);

  // Check if should refresh based on debounce
  bool get shouldRefresh {
    if (_lastRefreshTime == null) return true;
    final now = DateTime.now();
    return now.difference(_lastRefreshTime!) > refreshDebounce;
  }

  // Trigger refresh with debouncing
  Future<void> triggerRefresh({bool force = false}) async {
    if (_isRefreshing) return;
    if (!force && !shouldRefresh) return;

    setState(() {
      _isRefreshing = true;
    });

    _lastRefreshTime = DateTime.now();

    try {
      await onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // Auto refresh on widget mount
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        triggerRefresh(force: true);
      }
    });
  }
}
