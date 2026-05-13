import 'dart:convert';
import 'package:http/http.dart' as http;

class ObesityService {
  static const String baseUrl = 'http://127.0.0.1:8000/api'; // ✅ ganti

  static Future<Map<String, dynamic>> predictObesity({
    required double usia,
    required double tinggi,
    required double berat,
    required String jenisKelamin,
    required String alkohol,
    required String kaloriTinggi,
    required String monitoring,
    required String merokok,
    required String riwayat,
    required String ngamil,
    required String transport,
    required double sayur,
    required int makanHarian,
    required double konsumsiAir,
    required double aktivitas,
    required double waktuLayar,
  }) async {
    final payload = {
      'usia':             usia,
      'tinggi':           tinggi,
      'berat':            berat,
      'jenis_kelamin':    jenisKelamin,
      'alkohol':          alkohol,
      'kalori_tinggi':    kaloriTinggi,
      'monitoring':       monitoring,
      'merokok':          merokok,
      'riwayat_keluarga': riwayat,      // ✅ fix
      'ngemil':           ngamil,       // ✅ fix
      'transportasi':     transport,    // ✅ fix
      'konsumsi_sayur':   sayur,        // ✅ fix
      'makan_harian':     makanHarian,
      'konsumsi_air':     konsumsiAir,
      'aktivitas_fisik':  aktivitas,    // ✅ fix
      'waktu_layar':      waktuLayar,
    };

    print('=== PAYLOAD ===');
    print(jsonEncode(payload));

    final response = await http.post(
      Uri.parse('$baseUrl/predict-obesity'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    print('=== RESPONSE ${response.statusCode} ===');
    print(response.body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Gagal prediksi: ${response.statusCode} ${response.body}');
    }
  }
}