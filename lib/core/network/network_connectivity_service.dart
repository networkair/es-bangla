import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

class NetworkConnectivityService {
  static final NetworkConnectivityService _instance = NetworkConnectivityService._internal();
  factory NetworkConnectivityService() => _instance;
  NetworkConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(milliseconds: 3000),
    receiveTimeout: const Duration(milliseconds: 3000),
  ));

  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _periodicCheckTimer;
  int _consecutiveFailures = 0;

  void initialize() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isNone = results.contains(ConnectivityResult.none) && results.length == 1;
      if (isNone) {
        isOnlineNotifier.value = false;
        _consecutiveFailures = 2;
      } else {
        checkRealReachability();
      }
    });

    // Check reachability on startup and periodically (every 10 seconds)
    checkRealReachability();
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      checkRealReachability();
    });
  }

  Future<bool> checkRealReachability() async {
    try {
      final response = await _dio.get(ApiConstants.healthEndpoint);
      if (response.statusCode == 200) {
        _consecutiveFailures = 0;
        if (!isOnlineNotifier.value) {
          isOnlineNotifier.value = true;
        }
        return true;
      } else {
        _handleFailure();
        return false;
      }
    } catch (_) {
      _handleFailure();
      return false;
    }
  }

  void _handleFailure() {
    _consecutiveFailures++;
    // Require 2 consecutive failed checks before blocking to avoid flicker on slow requests
    if (_consecutiveFailures >= 2) {
      if (isOnlineNotifier.value) {
        isOnlineNotifier.value = false;
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    _periodicCheckTimer?.cancel();
    isOnlineNotifier.dispose();
  }
}
