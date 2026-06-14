import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/connectivity_service.dart';
import '../individu/individu_form_screen.dart';

class KeluargaReviewScreen extends StatefulWidget {
  final Map<String, dynamic>? initialKeluargaData;
  final List<Map<String, dynamic>>? initialAnggotaList;

  const KeluargaReviewScreen({
    super.key,
    this.initialKeluargaData,
    this.initialAnggotaList,
  });

  @override
  State<KeluargaReviewScreen> createState() => _KeluargaReviewScreenState();
}

class _KeluargaReviewScreenState extends State<KeluargaReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _kkController;
  late TextEditingController _kepalaController;
  late TextEditingController _alamatController;
  late TextEditingController _lingkunganController;
  late TextEditingController _kelurahanController;
  late TextEditingController _kecamatanController;

  double? _latitude;
  double? _longitude;
  File? _houseImage;
  File? _kkImage; // The scanned KK card image
  
  List<Map<String, dynamic>> _anggotaList = [];
  bool _isLocating = false;
  bool _isSaving = false;
  String _savingStatus = '';

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final family = widget.initialKeluargaData;
    _kkController = TextEditingController(text: family?['no_kk'] ?? '');
    _kepalaController = TextEditingController(text: family?['nama_kepala_keluarga'] ?? '');
    _alamatController = TextEditingController(text: family?['alamat'] ?? '');
    _lingkunganController = TextEditingController(text: family?['lingkungan'] ?? '');
    _kelurahanController = TextEditingController(text: family?['kelurahan'] ?? '');
    _kecamatanController = TextEditingController(text: family?['kecamatan'] ?? '');
    _latitude = family?['latitude'];
    _longitude = family?['longitude'];

    if (family?['foto_path'] != null) {
      // If scanned, the camera picture is the KK document itself
      _kkImage = File(family!['foto_path']);
    }

    if (widget.initialAnggotaList != null) {
      _anggotaList = List<Map<String, dynamic>>.from(
        widget.initialAnggotaList!.map((e) => Map<String, dynamic>.from(e)),
      );
    }
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

  Future<void> _pickHouseImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _houseImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: $e')),
      );
    }
  }

  void _addMember() {
    final String currentKk = _kkController.text.trim();
    if (currentKk.isEmpty || currentKk.length != 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi Nomor KK 16 digit terlebih dahulu sebelum menambah anggota keluarga.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IndividuFormScreen(
          noKk: currentKk,
          onSave: (newIndividu) {
            setState(() {
              _anggotaList.add(newIndividu);
              // Auto-set kepala keluarga name if it is the first or if marked as Kepala Keluarga
              if (_kepalaController.text.isEmpty || newIndividu['status_hubungan_keluarga'] == 'Kepala Keluarga') {
                _kepalaController.text = newIndividu['nama_lengkap'] ?? '';
              }
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _editMember(int index) {
    final String currentKk = _kkController.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IndividuFormScreen(
          noKk: currentKk.isEmpty ? '1234567890123456' : currentKk,
          initialData: _anggotaList[index],
          onSave: (updatedIndividu) {
            setState(() {
              _anggotaList[index] = updatedIndividu;
              if (updatedIndividu['status_hubungan_keluarga'] == 'Kepala Keluarga') {
                _kepalaController.text = updatedIndividu['nama_lengkap'] ?? '';
              }
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _removeMember(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Anggota Keluarga'),
        content: Text('Apakah Anda yakin ingin menghapus ${_anggotaList[index]['nama_lengkap'] ?? 'anggota ini'} dari daftar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _anggotaList.removeAt(index);
              });
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_anggotaList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harus ada minimal 1 anggota keluarga di dalam daftar!')),
      );
      return;
    }

    // Check internet connection
    final bool online = await ConnectivityService.hasInternetConnection();
    if (!online) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Koneksi Diperlukan'),
          content: const Text('Penyimpanan gagal karena perangkat Anda sedang offline. Koneksi internet wajib aktif untuk menyimpan data.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _savingStatus = 'Memeriksa data dan koneksi...';
    });

    try {
      // Find Kepala Keluarga NIK
      String nikKepala = '';
      final kepala = _anggotaList.firstWhere(
        (element) => element['status_hubungan_keluarga'] == 'Kepala Keluarga',
        orElse: () => _anggotaList.first,
      );
      nikKepala = kepala['nik'] ?? '';

      if (nikKepala.isEmpty) {
        throw 'Gagal menemukan NIK Kepala Keluarga. Pastikan data terisi dengan benar.';
      }

      // Step 1: Upload KK Scanned Photo
      String? scanKkUrl;
      if (_kkImage != null) {
        setState(() {
          _savingStatus = 'Mengunggah hasil scan Kartu Keluarga...';
        });
        final fileName = '${SupabaseService.currentUser?.id ?? 'temp'}_${_kkController.text}_kk.webp';
        scanKkUrl = await SupabaseService.uploadFile(
          bucket: 'kk-scans',
          path: fileName,
          file: _kkImage!,
        );
      }

      // Step 2: Upload House Photo
      String? fotoRumahUrl;
      if (_houseImage != null) {
        setState(() {
          _savingStatus = 'Mengunggah foto depan rumah...';
        });
        final fileName = '${SupabaseService.currentUser?.id ?? 'temp'}_${_kkController.text}_house.webp';
        fotoRumahUrl = await SupabaseService.uploadFile(
          bucket: 'house-photos',
          path: fileName,
          file: _houseImage!,
        );
      }

      // Step 3: Insert Keluarga record
      setState(() {
        _savingStatus = 'Menyimpan data keluarga ke database...';
      });

      final Map<String, dynamic> dbKeluarga = {
        'no_kk': _kkController.text.trim(),
        'nama_kepala_keluarga': _kepalaController.text.trim(),
        'nik_kepala_keluarga': nikKepala,
        'alamat': _alamatController.text.trim(),
        'lingkungan': _lingkunganController.text.trim(),
        'kelurahan': _kelurahanController.text.trim(),
        'kecamatan': _kecamatanController.text.trim(),
        'kota': 'Binjai',
        'latitude': _latitude,
        'longitude': _longitude,
        'foto_rumah_url': fotoRumahUrl,
        'scan_kk_url': scanKkUrl,
        'petugas_id': SupabaseService.currentUser?.id,
        'status': 'pending', // Send to supervisor for approval
      };

      final Map<String, dynamic> uploadedKeluarga = await SupabaseService.uploadKeluarga(dbKeluarga);
      final String keluargaUuid = uploadedKeluarga['id'];

      // Step 4: Insert all Individu records
      for (int i = 0; i < _anggotaList.length; i++) {
        final member = _anggotaList[i];
        setState(() {
          _savingStatus = 'Menyimpan data anggota (${i + 1}/${_anggotaList.length}): ${member['nama_lengkap']}...';
        });

        String? fotoKtpUrl;
        if (member['foto_ktp_path'] != null) {
          final ktpFile = File(member['foto_ktp_path']);
          if (await ktpFile.exists()) {
            final fileName = '${SupabaseService.currentUser?.id ?? 'temp'}_${member['nik']}_ktp.webp';
            fotoKtpUrl = await SupabaseService.uploadFile(
              bucket: 'ktp-scans',
              path: fileName,
              file: ktpFile,
            );
          }
        }

        final Map<String, dynamic> dbIndividu = {
          'keluarga_id': keluargaUuid,
          'no_kk': _kkController.text.trim(),
          'nik': member['nik'],
          'nama_lengkap': member['nama_lengkap'],
          'nama_panggilan': member['nama_panggilan'],
          'alamat': _alamatController.text.trim(),
          'lingkungan': _lingkunganController.text.trim(),
          'kelurahan': _kelurahanController.text.trim(),
          'kecamatan': _kecamatanController.text.trim(),
          'kota': 'Binjai',
          'pekerjaan': member['pekerjaan'],
          'tempat_lahir': member['tempat_lahir'],
          'tanggal_lahir': member['tanggal_lahir'],
          'agama': member['agama'],
          'status_perkawinan': member['status_perkawinan'],
          'status_hubungan_keluarga': member['status_hubungan_keluarga'],
          'jenis_kelamin': member['jenis_kelamin'],
          'suku': member['suku'] ?? 'Jawa',
          'anggota_pujakesuma': member['anggota_pujakesuma'] ?? false,
          'foto_ktp_url': fotoKtpUrl,
          'petugas_id': SupabaseService.currentUser?.id,
        };

        await SupabaseService.uploadIndividu(dbIndividu);
      }

      setState(() {
        _isSaving = false;
      });

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Penyimpanan Sukses'),
              ],
            ),
            content: const Text('Data Keluarga dan semua anggota keluarga telah berhasil dikirim langsung ke database Supabase!'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Pop Dialog
                  Navigator.pop(context); // Pop Review Screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF800020),
                  foregroundColor: const Color(0xFFD4AF37),
                ),
                child: const Text('Kembali ke Dashboard'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Terjadi Kesalahan'),
              ],
            ),
            content: Text('Gagal menyimpan data ke database:\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF131324),
          appBar: AppBar(
            title: const Text('Konfirmasi & Edit Pendataan'),
            backgroundColor: const Color(0xFF1A1A2E),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CARD 1: KELUARGA DETAIL
                  Card(
                    color: const Color(0xFF1A1A2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.home, color: Color(0xFFD4AF37)),
                              SizedBox(width: 8),
                              Text(
                                'Data Keluarga',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'serif',
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.grey, height: 24),
                          
                          TextFormField(
                            controller: _kkController,
                            decoration: const InputDecoration(
                              labelText: 'Nomor Kartu Keluarga (KK)',
                              hintText: '16 digit angka',
                            ),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
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
                            decoration: const InputDecoration(
                              labelText: 'Nama Kepala Keluarga',
                              hintText: 'Nama otomatis terisi dari NIK Kepala Keluarga',
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (val) => val == null || val.isEmpty ? 'Nama tidak boleh kosong' : null,
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _alamatController,
                            decoration: const InputDecoration(labelText: 'Alamat Rumah'),
                            maxLines: 2,
                            style: const TextStyle(color: Colors.white),
                            validator: (val) => val == null || val.isEmpty ? 'Alamat tidak boleh kosong' : null,
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _lingkunganController,
                                  decoration: const InputDecoration(labelText: 'Lingkungan'),
                                  style: const TextStyle(color: Colors.white),
                                  validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _kelurahanController,
                                  decoration: const InputDecoration(labelText: 'Kelurahan'),
                                  style: const TextStyle(color: Colors.white),
                                  validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _kecamatanController,
                            decoration: const InputDecoration(labelText: 'Kecamatan'),
                            style: const TextStyle(color: Colors.white),
                            validator: (val) => val == null || val.isEmpty ? 'Kecamatan wajib diisi' : null,
                          ),
                          const SizedBox(height: 24),

                          // GPS Section
                          const Text('Geolokasi (GPS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _latitude != null && _longitude != null
                                      ? 'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}'
                                      : 'Koordinat belum diambil',
                                  style: TextStyle(color: _latitude != null ? Colors.green : Colors.grey),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _isLocating ? null : _fetchGPS,
                                icon: _isLocating
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)),
                                      )
                                    : const Icon(Icons.my_location),
                                label: const Text('Ambil GPS'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF800020).withOpacity(0.4),
                                  foregroundColor: const Color(0xFFD4AF37),
                                  side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 24),

                          // House Photo Section
                          const Text('Foto Rumah (Tampak Depan)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
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
                                            _pickHouseImage(ImageSource.camera);
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.photo_library),
                                          title: const Text('Pilih dari Galeri'),
                                          onTap: () {
                                            Navigator.pop(ctx);
                                            _pickHouseImage(ImageSource.gallery);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                height: 160,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF131324),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                                ),
                                child: _houseImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(_houseImage!, fit: BoxFit.cover),
                                      )
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_a_photo, size: 40, color: Color(0xFFD4AF37)),
                                          SizedBox(height: 8),
                                          Text('Ketuk untuk Unggah Foto Rumah', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          
                          if (_kkImage != null) ...[
                            const SizedBox(height: 24),
                            const Text('Hasil Scan Dokumen KK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              height: 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.withOpacity(0.5)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_kkImage!, fit: BoxFit.cover),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // HEADER CARD 2: LIST ANGGOTA KELUARGA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Anggota Keluarga',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'serif',
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addMember,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Tambah Anggota', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF800020),
                          foregroundColor: const Color(0xFFD4AF37),
                          side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_anggotaList.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.people_outline, color: Colors.grey, size: 40),
                          SizedBox(height: 8),
                          Text(
                            'Belum ada anggota keluarga.\nKetuk "Tambah Anggota" di atas untuk menambahkan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _anggotaList.length,
                      itemBuilder: (context, index) {
                        final member = _anggotaList[index];
                        final isKepala = member['status_hubungan_keluarga'] == 'Kepala Keluarga';
                        
                        return Card(
                          color: const Color(0xFF1A1A2E),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isKepala ? const Color(0xFFD4AF37) : Colors.grey.withOpacity(0.2),
                              width: isKepala ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    member['nama_lengkap'] ?? 'No Name',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isKepala ? const Color(0xFF800020) : Colors.blueGrey.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isKepala ? const Color(0xFFD4AF37) : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    member['status_hubungan_keluarga'] ?? 'Anggota',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isKepala ? const Color(0xFFD4AF37) : Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text('NIK: ${member['nik'] ?? '-'}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                const SizedBox(height: 2),
                                Text(
                                  '${member['jenis_kelamin'] ?? '-'} • ${member['pekerjaan'] ?? '-'} • Suku: ${member['suku'] ?? 'Jawa'}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Color(0xFFD4AF37), size: 20),
                                  onPressed: () => _editMember(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                  onPressed: () => _removeMember(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 32),

                  // SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF800020),
                        foregroundColor: const Color(0xFFD4AF37),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                        ),
                      ),
                      child: const Text(
                        'Simpan ke Database Supabase',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        
        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Card(
                color: const Color(0xFF1A1A2E),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFD4AF37)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFFD4AF37)),
                      const SizedBox(height: 20),
                      const Text(
                        'Sedang Menyimpan Data',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _savingStatus,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
