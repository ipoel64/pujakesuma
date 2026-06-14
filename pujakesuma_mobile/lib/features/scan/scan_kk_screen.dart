import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import '../../core/services/ocr_service.dart';

class ScanKkScreen extends StatefulWidget {
  const ScanKkScreen({super.key});

  @override
  State<ScanKkScreen> createState() => _ScanKkScreenState();
}

class _ScanKkScreenState extends State<ScanKkScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Force landscape mode for wide KK capture
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0], // Use back camera
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal inisialisasi kamera: $e')),
      );
    }
  }

  Future<void> _captureAndScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Capture Photo
      final XFile photo = await _cameraController!.takePicture();
      
      // Process with OCR
      final ocrResult = await OcrService.parseKartuKeluarga(photo.path);

      // Create Keluarga Initial Data from OCR
      final Map<String, dynamic> keluargaData = {
        'no_kk': ocrResult.noKk,
        'nama_kepala_keluarga': ocrResult.namaKepalaKeluarga,
        'alamat': ocrResult.alamat,
        'lingkungan': ocrResult.lingkungan,
        'kelurahan': ocrResult.kelurahan,
        'kecamatan': ocrResult.kecamatan,
        'foto_path': photo.path,
      };

      // Create List of Individual Members from OCR
      final List<Map<String, dynamic>> anggotaList = ocrResult.anggotaKeluarga;

      if (mounted) {
        // Restore default portrait mode when exiting camera screen
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        Navigator.pop(context, {
          'keluarga': keluargaData,
          'anggotaList': anggotaList,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memproses KK: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFD4AF37)),
                  SizedBox(height: 16),
                  Text(
                    'Mengekstrak data teks Kartu Keluarga...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Mohon tunggu sebentar',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            )
          : _isCameraInitialized
              ? Stack(
                  children: [
                    // Full screen camera preview
                    Positioned.fill(
                      child: CameraPreview(_cameraController!),
                    ),
                    
                    // Guided Frame Overlay for Kartu Keluarga
                    Positioned.fill(
                      child: Container(
                        decoration: ShapeDecoration(
                          shape: _KkOverlayShape(),
                        ),
                      ),
                    ),
                    
                    // Custom Floating Back Button (placed on top left)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            // Restore default portrait mode when exiting camera manually
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.portraitUp,
                              DeviceOrientation.portraitDown,
                            ]);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                    
                    // Help Text
                    Positioned(
                      top: 20,
                      left: 80,
                      right: 80,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Posisikan Kartu Keluarga di dalam bingkai (Landscape)',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    
                    // Capture Button (placed on right side for easier landscape access, or centered bottom)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: FloatingActionButton(
                          onPressed: _captureAndScan,
                          backgroundColor: const Color(0xFF800020),
                          foregroundColor: const Color(0xFFD4AF37),
                          shape: const CircleBorder(
                            side: BorderSide(color: Color(0xFFD4AF37), width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, size: 30),
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                ),
    );
  }

  @override
  void dispose() {
    // Restore default portrait mode when exiting camera screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _cameraController?.dispose();
    super.dispose();
  }
}

class _KkOverlayShape extends ShapeBorder {
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    
    // Calculate guided box size: 85% of screen height, keeping 1.5 landscape aspect ratio
    double cardHeight = height * 0.85;
    double cardWidth = cardHeight * 1.5;
    
    // Cap width to 92% of screen width if it overflows
    if (cardWidth > width * 0.92) {
      cardWidth = width * 0.92;
      cardHeight = cardWidth / 1.5;
    }
    
    final double left = (width - cardWidth) / 2;
    final double top = (height - cardHeight) / 2;

    final Paint paint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    // Draw background overlay
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left, top, cardWidth, cardHeight), const Radius.circular(12))),
      ),
      paint,
    );

    // Draw red/gold border for guideline
    final Paint linePaint = Paint()
      ..color = const Color(0xFF800020)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final Paint cornerPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    final RRect rrect = RRect.fromRectAndRadius(Rect.fromLTWH(left, top, cardWidth, cardHeight), const Radius.circular(12));
    canvas.drawRRect(rrect, linePaint);

    // Draw 4 golden corner indicators
    const double cornerLength = 30;
    
    // Top-left
    canvas.drawPath(Path()..moveTo(left, top + cornerLength)..lineTo(left, top)..lineTo(left + cornerLength, top), cornerPaint);
    // Top-right
    canvas.drawPath(Path()..moveTo(left + cardWidth - cornerLength, top)..lineTo(left + cardWidth, top)..lineTo(left + cardWidth, top + cornerLength), cornerPaint);
    // Bottom-left
    canvas.drawPath(Path()..moveTo(left, top + cardHeight - cornerLength)..lineTo(left, top + cardHeight)..lineTo(left + cornerLength, top + cardHeight), cornerPaint);
    // Bottom-right
    canvas.drawPath(Path()..moveTo(left + cardWidth - cornerLength, top + cardHeight)..lineTo(left + cardWidth, top + cardHeight)..lineTo(left + cardWidth, top + cardHeight - cornerLength), cornerPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}
