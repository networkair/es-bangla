import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import '../constants/api_constants.dart';

class NetworkConnectivityService with WidgetsBindingObserver {
  static final NetworkConnectivityService _instance = NetworkConnectivityService._internal();
  factory NetworkConnectivityService() => _instance;
  NetworkConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
  ));

  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void initialize() {
    WidgetsBinding.instance.addObserver(this);

    // Initial check on startup
    _checkHardwareAndSync();

    // Listen to network interface changes (User turns Wi-Fi / Mobile Data ON or OFF)
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (!hasConnection) {
        // User turned off internet (Offline / Airplane mode)
        isOnlineNotifier.value = false;
      } else {
        // User turned on internet
        isOnlineNotifier.value = true;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User returned to the app from background/lockscreen.
      // Immediately sync with the current hardware connectivity state
      // so user NEVER falsely sees an offline screen if their internet is on.
      _checkHardwareAndSync();
    }
  }

  Future<void> _checkHardwareAndSync() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (!hasConnection) {
        isOnlineNotifier.value = false;
      } else {
        isOnlineNotifier.value = true;
      }
    } catch (_) {
      // Never block the user if check fails unexpectedly
      isOnlineNotifier.value = true;
    }
  }

  Future<bool> checkRealReachability() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (!hasConnection) {
        isOnlineNotifier.value = false;
        return false;
      }

      // Quick check against health endpoint
      try {
        final response = await _dio.get(
          ApiConstants.healthEndpoint,
          options: Options(validateStatus: (status) => status != null && status < 500),
        );
        if (response.statusCode != null && response.statusCode! < 500) {
          isOnlineNotifier.value = true;
          return true;
        }
      } catch (_) {
        // Fallback DNS check
        try {
          final lookup = await InternetAddress.lookup('google.com')
              .timeout(const Duration(seconds: 4));
          if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
            isOnlineNotifier.value = true;
            return true;
          }
        } catch (_) {}
      }

      // As long as hardware connection is active, keep user unblocked
      isOnlineNotifier.value = hasConnection;
      return hasConnection;
    } catch (_) {
      isOnlineNotifier.value = true;
      return true;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    isOnlineNotifier.dispose();
  }
}
