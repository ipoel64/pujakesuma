import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class IndividuFormScreen extends StatefulWidget {
  final String noKk;
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onSave;

  const IndividuFormScreen({
    super.key,
    required this.noKk,
    this.initialData,
    required this.onSave,
  });

  @override
  State<IndividuFormScreen> createState() => _IndividuFormScreenState();
}

class _IndividuFormScreenState extends State<IndividuFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nikController;
  late TextEditingController _namaController;
  late TextEditingController _panggilanController;
  late TextEditingController _pekerjaanController;
  late TextEditingController _tempatLahirController;
  
  DateTime _tanggalLahir = DateTime(1990, 1, 1);
  String _agama = 'Islam';
  String _statusPerkawinan = 'Belum Kawin';
  String _hubunganKeluarga = 'Anak';
  String _jenisKelamin = 'Laki-laki';
  String _suku = 'Jawa';
  bool _anggotaPujakesuma = true;
  File? _ktpFile;

  final ImagePicker _picker = ImagePicker();

  final List<String> _listAgama = ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Budha', 'Konghucu'];
  final List<String> _listStatusKawin = ['Belum Kawin', 'Kawin', 'Cerai Hidup', 'Cerai Mati'];
  final List<String> _listHubungan = ['Kepala Keluarga', 'Suami', 'Isteri', 'Anak', 'Menantu', 'Cucu', 'Orang Tua', 'Mertua', 'Famili Lain'];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _nikController = TextEditingController(text: data?['nik'] ?? '');
    _namaController = TextEditingController(text: data?['nama_lengkap'] ?? '');
    _panggilanController = TextEditingController(text: data?['nama_panggilan'] ?? '');
    _pekerjaanController = TextEditingController(text: data?['pekerjaan'] ?? '');
    _tempatLahirController = TextEditingController(text: data?['tempat_lahir'] ?? '');
    
    if (data?['tanggal_lahir'] != null) {
      _tanggalLahir = DateTime.parse(data!['tanggal_lahir']);
    }
    if (data?['agama'] != null) _agama = data!['agama'];
    if (data?['status_perkawinan'] != null) _statusPerkawinan = data!['status_perkawinan'];
    if (data?['status_hubungan_keluarga'] != null) _hubunganKeluarga = data!['status_hubungan_keluarga'];
    if (data?['jenis_kelamin'] != null) _jenisKelamin = data!['jenis_kelamin'];
    if (data?['suku'] != null) _suku = data!['suku'];
    if (data?['anggota_pujakesuma'] != null) _anggotaPujakesuma = data!['anggota_pujakesuma'];
    if (data?['foto_ktp_path'] != null) {
      _ktpFile = File(data!['foto_ktp_path']);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tanggalLahir,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _tanggalLahir) {
      setState(() {
        _tanggalLahir = picked;
      });
    }
  }

  Future<void> _pickKtpImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _ktpFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto KTP: $e')),
      );
    }
  }

  void _saveIndividu() {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.initialData?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final Map<String, dynamic> individu = {
      'id': id,
      'no_kk': widget.noKk,
      'nik': _nikController.text.trim(),
      'nama_lengkap': _namaController.text.trim(),
      'nama_panggilan': _panggilanController.text.trim(),
      'pekerjaan': _pekerjaanController.text.trim(),
      'tempat_lahir': _tempatLahirController.text.trim(),
      'tanggal_lahir': _tanggalLahir.toIso8601String().substring(0, 10),
      'agama': _agama,
      'status_perkawinan': _statusPerkawinan,
      'status_hubungan_keluarga': _hubunganKeluarga,
      'jenis_kelamin': _jenisKelamin,
      'suku': _suku,
      'anggota_pujakesuma': _anggotaPujakesuma,
      'foto_ktp_path': _ktpFile?.path,
      'created_at': widget.initialData?['created_at'] ?? DateTime.now().toIso8601String(),
    };

    widget.onSave(individu);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialData == null ? 'Tambah Anggota' : 'Edit Anggota'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveIndividu,
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
                controller: _nikController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Induk Kependudukan (NIK)',
                  hintText: '16 digit angka',
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.length != 16) {
                    return 'NIK harus berisi tepat 16 digit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (val) => val == null || val.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _panggilanController,
                      decoration: const InputDecoration(labelText: 'Nama Panggilan'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _pekerjaanController,
                      decoration: const InputDecoration(labelText: 'Pekerjaan'),
                      validator: (val) => val == null || val.isEmpty ? 'Pekerjaan wajib diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Birth Place & Date
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tempatLahirController,
                      decoration: const InputDecoration(labelText: 'Tempat Lahir'),
                      validator: (val) => val == null || val.isEmpty ? 'Tempat lahir wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Tanggal Lahir'),
                        child: Text(
                          '${_tanggalLahir.day}/${_tanggalLahir.month}/${_tanggalLahir.year}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Gender Selector
              const Text('Jenis Kelamin', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Row(
                children: [
                  Radio<String>(
                    value: 'Laki-laki',
                    groupValue: _jenisKelamin,
                    onChanged: (val) {
                      setState(() {
                        _jenisKelamin = val!;
                      });
                    },
                  ),
                  const Text('Laki-laki'),
                  const SizedBox(width: 16),
                  Radio<String>(
                    value: 'Perempuan',
                    groupValue: _jenisKelamin,
                    onChanged: (val) {
                      setState(() {
                        _jenisKelamin = val!;
                      });
                    },
                  ),
                  const Text('Perempuan'),
                ],
              ),
              const SizedBox(height: 8),

              // Dropdowns for Hubungan, Agama, Status Kawin
              DropdownButtonFormField<String>(
                value: _hubunganKeluarga,
                decoration: const InputDecoration(labelText: 'Hubungan Keluarga'),
                items: _listHubungan.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _hubunganKeluarga = val!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _agama,
                decoration: const InputDecoration(labelText: 'Agama'),
                items: _listAgama.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _agama = val!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _statusPerkawinan,
                decoration: const InputDecoration(labelText: 'Status Perkawinan'),
                items: _listStatusKawin.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _statusPerkawinan = val!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Suku & Keanggotaan Pujakesuma
              TextFormField(
                initialValue: _suku,
                decoration: const InputDecoration(labelText: 'Suku / Etnis'),
                onChanged: (val) {
                  _suku = val;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Anggota Pujakesuma?'),
                subtitle: const Text('Apakah terdaftar aktif dalam kepengurusan/anggota'),
                value: _anggotaPujakesuma,
                activeColor: const Color(0xFFD4AF37),
                onChanged: (val) {
                  setState(() {
                    _anggotaPujakesuma = val;
                  });
                },
              ),
              const SizedBox(height: 16),

              // KTP upload
              const Text('Foto KTP (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                              title: const Text('Ambil KTP dari Kamera'),
                              onTap: () {
                                Navigator.pop(ctx);
                                _pickKtpImage(ImageSource.camera);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Pilih KTP dari Galeri'),
                              onTap: () {
                                Navigator.pop(ctx);
                                _pickKtpImage(ImageSource.gallery);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                    ),
                    child: _ktpFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_ktpFile!, fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.credit_card, size: 40, color: Color(0xFFD4AF37)),
                              SizedBox(height: 8),
                              Text('Sentuh untuk Unggah Foto KTP', style: TextStyle(color: Colors.grey)),
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
                  onPressed: _saveIndividu,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF800020),
                    foregroundColor: const Color(0xFFD4AF37),
                  ),
                  child: const Text('Simpan Data Anggota', style: TextStyle(fontWeight: FontWeight.bold)),
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
    _nikController.dispose();
    _namaController.dispose();
    _panggilanController.dispose();
    _pekerjaanController.dispose();
    _tempatLahirController.dispose();
    super.dispose();
  }
}
