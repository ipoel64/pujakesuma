import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/location_service.dart';

class KeluargaFormScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onSave;

  const KeluargaFormScreen({super.key, this.initialData, required this.onSave});

  @override
  State<KeluargaFormScreen> createState() => _KeluargaFormScreenState();
}

class _KeluargaFormScreenState extends State<KeluargaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _kkController;
  late TextEditingController _kepalaController;
  late TextEditingController _alamatController;
  late TextEditingController _lingkunganController;
  late TextEditingController _kelurahanController;
  late TextEditingController _kecamatanController;

  double? _latitude;
  double? _longitude;
  File? _imageFile;
  bool _isLocating = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _kkController = TextEditingController(text: data?['no_kk'] ?? '');
    _kepalaController = TextEditingController(text: data?['nama_kepala_keluarga'] ?? '');
    _alamatController = TextEditingController(text: data?['alamat'] ?? '');
    _lingkunganController = TextEditingController(text: data?['lingkungan'] ?? '');
    _kelurahanController = TextEditingController(text: data?['kelurahan'] ?? '');
    _kecamatanController = TextEditingController(text: data?['kecamatan'] ?? '');
    _latitude = data?['latitude'];
    _longitude = data?['longitude'];
    if (data?['foto_path'] != null) {
      _imageFile = File(data!['foto_path']);
    }
  }

  Future<void> _fetchGPS() async {
    setState(() {
      _isLocating = true;
    });

    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });

        // Try reverse geocode
        final addressDetails = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (addressDetails != null) {
          setState(() {
            if (_alamatController.text.isEmpty) {
              _alamatController.text = addressDetails['alamat'] ?? '';
            }
            if (_kelurahanController.text.isEmpty) {
              _kelurahanController.text = addressDetails['kelurahan'] ?? '';
            }
            if (_kecamatanController.text.isEmpty) {
              _kecamatanController.text = addressDetails['kecamatan'] ?? '';
            }
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lokasi GPS berhasil ditangkap!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendapatkan GPS: $e')),
      );
    } finally {
      setState(() {
        _isLocating = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Compress image size
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: $e')),
      );
    }
  }

  void _saveForm() {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.initialData?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final Map<String, dynamic> keluarga = {
      'id': id,
      'no_kk': _kkController.text.trim(),
      'nama_kepala_keluarga': _kepalaController.text.trim(),
      'alamat': _alamatController.text.trim(),
      'lingkungan': _lingkunganController.text.trim(),
      'kelurahan': _kelurahanController.text.trim(),
      'kecamatan': _kecamatanController.text.trim(),
      'latitude': _latitude,
      'longitude': _longitude,
      'foto_path': _imageFile?.path,
      'status': 'draft',
      'created_at': widget.initialData?['created_at'] ?? DateTime.now().toIso8601String(),
    };

    widget.onSave(keluarga);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialData == null ? 'Tambah Keluarga' : 'Edit Keluarga'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveForm,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _kkController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Kartu Keluarga (KK)',
                  hintText: '16 digit angka',
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.length != 16) {
                    return 'KK harus berisi tepat 16 digit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kepalaController,
                decoration: const InputDecoration(labelText: 'Nama Kepala Keluarga'),
                validator: (val) => val == null || val.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _alamatController,
                decoration: const InputDecoration(labelText: 'Alamat Rumah'),
                maxLines: 2,
                validator: (val) => val == null || val.isEmpty ? 'Alamat tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _lingkunganController,
                      decoration: const InputDecoration(labelText: 'Lingkungan'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _kelurahanController,
                      decoration: const InputDecoration(labelText: 'Kelurahan'),
                      validator: (val) => val == null || val.isEmpty ? 'Kelurahan wajib diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kecamatanController,
                decoration: const InputDecoration(labelText: 'Kecamatan'),
                validator: (val) => val == null || val.isEmpty ? 'Kecamatan wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              
              // GPS Section
              const Text('Geolokasi (GPS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _latitude != null && _longitude != null
                          ? 'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}'
                          : 'Koordinat belum ditangkap',
                      style: TextStyle(color: _latitude != null ? Colors.green : Colors.grey),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLocating ? null : _fetchGPS,
                    icon: _isLocating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: const Text('Ambil GPS'),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // House Photo Section
              const Text('Foto Tampak Depan Rumah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.photo_camera),
                              title: const Text('Ambil dari Kamera'),
                              onTap: () {
                                Navigator.pop(ctx);
                                _pickImage(ImageSource.camera);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Pilih dari Galeri'),
                              onTap: () {
                                Navigator.pop(ctx);
                                _pickImage(ImageSource.gallery);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 50, color: Color(0xFFD4AF37)),
                              SizedBox(height: 8),
                              Text('Sentuh untuk Unggah/Capture Foto Rumah', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF800020),
                    foregroundColor: const Color(0xFFD4AF37),
                  ),
                  child: const Text('Simpan Data Keluarga', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _kkController.dispose();
    _kepalaController.dispose();
    _alamatController.dispose();
    _lingkunganController.dispose();
    _kelurahanController.dispose();
    _kecamatanController.dispose();
    super.dispose();
  }
}
