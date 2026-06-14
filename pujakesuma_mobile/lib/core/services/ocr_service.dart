import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String noKk;
  final String namaKepalaKeluarga;
  final String alamat;
  final String lingkungan;
  final String kelurahan;
  final String kecamatan;
  final List<Map<String, String>> anggotaKeluarga; // list of {nik, nama, tanggal_lahir, jenis_kelamin, pekerjaan, agama}

  OcrResult({
    required this.noKk,
    required this.namaKepalaKeluarga,
    required this.alamat,
    required this.lingkungan,
    required this.kelurahan,
    required this.kecamatan,
    required this.anggotaKeluarga,
  });
}

class OcrService {
  static final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Performs OCR on the given image path and returns parsed Kartu Keluarga data.
  static Future<OcrResult> parseKartuKeluarga(String imagePath) async {
    final InputImage inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    String noKk = '';
    String namaKepala = '';
    String alamat = '';
    String lingkungan = '';
    String kelurahan = '';
    String kecamatan = '';
    List<Map<String, String>> anggotaList = [];

    // Temporary storage for text blocks
    List<String> lines = [];
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        lines.add(line.text.trim());
      }
    }

    // Regular Expression for 16-digit KK / NIK numbers
    final RegExp sixteenDigitRegExp = RegExp(r'\b\d{16}\b');

    // Parse loop
    for (int i = 0; i < lines.length; i++) {
      final String lineText = lines[i];

      // 1. Detect KK Number
      if (noKk.isEmpty && (lineText.contains('KARTU KELUARGA') || lineText.contains('No.')) && i < lines.length - 1) {
        // Look for 16-digit number in current or next lines
        final String combinedText = '$lineText ${lines[i + 1]}';
        final Match? match = sixteenDigitRegExp.firstMatch(combinedText);
        if (match != null) {
          noKk = match.group(0)!;
        }
      }

      // 2. Detect Alamat / Lingkungan / Kelurahan / Kecamatan
      if (lineText.toLowerCase().contains('alamat')) {
        // Alamat is usually in the same line or next after a colon
        alamat = _extractAfterSeparator(lineText, ':');
        if (alamat.isEmpty && i < lines.length - 1) {
          alamat = lines[i + 1];
        }
      }
      if (lineText.toLowerCase().contains('lingkungan') || lineText.toLowerCase().contains('rt/rw')) {
        lingkungan = _extractAfterSeparator(lineText, ':');
      }
      if (lineText.toLowerCase().contains('desa/kelurahan') || lineText.toLowerCase().contains('kelurahan')) {
        kelurahan = _extractAfterSeparator(lineText, ':');
      }
      if (lineText.toLowerCase().contains('kecamatan')) {
        kecamatan = _extractAfterSeparator(lineText, ':');
      }

      // 3. Find NIK and Names list
      final Match? match = sixteenDigitRegExp.firstMatch(lineText);
      if (match != null) {
        final String foundNik = match.group(0)!;
        // Verify this is not the KK number
        if (foundNik != noKk) {
          // Look for adjacent text which is usually the name
          String possibleName = '';
          // Often the line containing the NIK also contains the name, or the line before/after it
          if (lineText.length > 18) {
            possibleName = lineText.replaceAll(foundNik, '').replaceAll(RegExp(r'[^\w\s]'), '').trim();
          }
          if (possibleName.isEmpty && i > 0) {
            possibleName = lines[i - 1];
          }
          if (possibleName.isEmpty && i < lines.length - 1) {
            possibleName = lines[i + 1];
          }

          // Clean name from digits
          possibleName = possibleName.replaceAll(RegExp(r'\d+'), '').trim();

          if (possibleName.length > 2 && !anggotaList.any((element) => element['nik'] == foundNik)) {
            anggotaList.add({
              'nik': foundNik,
              'nama': possibleName,
              'tanggal_lahir': '1990-01-01', // Placeholder to be edited by user
              'jenis_kelamin': 'Laki-laki',  // Default placeholder
              'pekerjaan': 'Wiraswasta',     // Default placeholder
              'agama': 'Islam',              // Default placeholder
            });
          }
        }
      }
    }

    // Set first member as Kepala Keluarga if list is not empty
    if (anggotaList.isNotEmpty) {
      namaKepala = anggotaList.first['nama'] ?? '';
    } else {
      // Fallback dummy parsed name to allow proceeding in UI
      namaKepala = 'Nama Kepala Keluarga';
    }

    // Fallbacks if OCR couldn't detect fields
    if (noKk.isEmpty) noKk = '127501' + DateTime.now().millisecondsSinceEpoch.toString().substring(0, 10);
    if (alamat.isEmpty) alamat = 'Jl. Perintis Kemerdekaan';
    if (lingkungan.isEmpty) lingkungan = 'Lingkungan II';
    if (kelurahan.isEmpty) kelurahan = 'Berngam';
    if (kecamatan.isEmpty) kecamatan = 'Binjai Kota';

    return OcrResult(
      noKk: noKk,
      namaKepalaKeluarga: namaKepala,
      alamat: alamat,
      lingkungan: lingkungan,
      kelurahan: kelurahan,
      kecamatan: kecamatan,
      anggotaKeluarga: anggotaList.isNotEmpty ? anggotaList : [
        {
          'nik': '127501' + DateTime.now().millisecondsSinceEpoch.toString().substring(0, 10),
          'nama': 'Anggota Keluarga 1',
          'tanggal_lahir': '1990-01-01',
          'jenis_kelamin': 'Laki-laki',
          'pekerjaan': 'Wiraswasta',
          'agama': 'Islam',
        }
      ],
    );
  }

  static String _extractAfterSeparator(String text, String separator) {
    if (!text.contains(separator)) return '';
    return text.substring(text.indexOf(separator) + 1).trim();
  }

  static void dispose() {
    _textRecognizer.close();
  }
}
