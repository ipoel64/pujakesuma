import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class InternetGuard extends StatefulWidget {
  final Widget child;

  const InternetGuard({super.key, required this.child});

  @override
  State<InternetGuard> createState() => _InternetGuardState();
}

class _InternetGuardState extends State<InternetGuard> {
  bool _isOnline = true;
  bool _checking = true;
  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _subscribeToConnectivity();
  }

  Future<void> _checkInitialConnection() async {
    setState(() {
      _checking = true;
    });
    final online = await ConnectivityService.hasInternetConnection();
    if (mounted) {
      setState(() {
        _isOnline = online;
        _checking = false;
      });
    }
  }

  void _subscribeToConnectivity() {
    _connectivitySubscription = ConnectivityService.onConnectivityChanged.listen((results) async {
      // Debounce slightly or perform connection check when connectivity status changes
      final online = await ConnectivityService.hasInternetConnection();
      if (mounted) {
        setState(() {
          _isOnline = online;
        });
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF131324),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFD4AF37)),
              SizedBox(height: 16),
              Text(
                'Memeriksa Koneksi Internet...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isOnline) {
      return Scaffold(
        backgroundColor: const Color(0xFF131324),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF800020).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF800020), width: 3),
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 80,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Koneksi Terputus',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aplikasi PUJAKESUMA Mobile memerlukan koneksi internet aktif. Mode offline tidak lagi didukung untuk menjaga sinkronisasi data real-time langsung ke server.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _checkInitialConnection,
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'Coba Hubungkan Kembali',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF800020),
                      foregroundColor: const Color(0xFFD4AF37),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFD4AF37)),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
