import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ObesityPredictPage extends StatefulWidget {
  final bool embedded;
  const ObesityPredictPage({super.key, this.embedded = false});

  @override
  State<ObesityPredictPage> createState() => _ObesityPredictPageState();
}

class _ObesityPredictPageState extends State<ObesityPredictPage> {

  // ── Palette ──
  static const Color _teal700   = Color(0xFF00796B);
  static const Color _teal500   = Color(0xFF009688);
  static const Color _teal50    = Color(0xFFE0F2F1);
  static const Color _neutral50  = Color(0xFFF5F7FA);
  static const Color _neutral100 = Color(0xFFEEEEEE);
  static const Color _neutral200 = Color(0xFFE0E0E0);
  static const Color _neutral400 = Color(0xFF9E9E9E);
  static const Color _neutral600 = Color(0xFF616161);
  static const Color _neutral900 = Color(0xFF212121);

  // ── Wizard state ──
  final _pageCtrl   = PageController();
  int  _currentStep = 0;
  static const int _totalSteps = 4;

  bool _isLoading = false;
  bool _isSaving  = false;
  bool _isSaved   = false;
  Map<String, dynamic>? _result;

  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());

  // ── Controllers ──
  final _usiaCtrl      = TextEditingController();
  final _tinggiCtrl    = TextEditingController();
  final _beratCtrl     = TextEditingController();
  final _sayurCtrl     = TextEditingController();
  final _makanCtrl     = TextEditingController();
  final _airCtrl       = TextEditingController();
  final _aktivitasCtrl = TextEditingController();
  final _layarCtrl     = TextEditingController();

  // ── Dropdowns ──
  String _jenisKelamin = 'Laki-laki';
  String _alkohol      = 'Tidak';
  String _kaloriTinggi = 'Tidak';
  String _monitoring   = 'Tidak';
  String _merokok      = 'Tidak';
  String _riwayat      = 'Ya';
  String _ngamil       = 'Kadang';
  String _transport    = 'Motor';

  // ✅ DIHAPUS: static const String _baseUrl = 'http://127.0.0.1:8000/api';
  // Sekarang pakai ApiService.baseUrl yang sudah otomatis sesuai platform

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final c in [_usiaCtrl, _tinggiCtrl, _beratCtrl, _sayurCtrl,
        _makanCtrl, _airCtrl, _aktivitasCtrl, _layarCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  // ════════════════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════════════════
  Color _kategoriColor(String k) {
    switch (k) {
      case 'Kurus':                return const Color(0xFF2196F3);
      case 'Normal':               return const Color(0xFF4CAF50);
      case 'Overweight_Tingkat_1': return const Color(0xFFFFC107);
      case 'Overweight_Tingkat_2': return const Color(0xFFFF9800);
      case 'Obesitas_Tipe_1':      return const Color(0xFFFF5722);
      case 'Obesitas_Tipe_2':      return const Color(0xFFF44336);
      case 'Obesitas_Tipe_3':      return const Color(0xFFB71C1C);
      default:                     return _neutral400;
    }
  }

  String _rekomendasi(String k) {
    switch (k) {
      case 'Kurus':
        return 'Tingkatkan asupan kalori bergizi. Konsultasi dengan ahli gizi untuk program penambahan berat badan yang sehat.';
      case 'Normal':
        return 'Pertahankan pola makan sehat dan aktivitas fisik rutin. Anda berada di kondisi ideal!';
      case 'Overweight_Tingkat_1':
        return 'Kurangi makanan tinggi kalori, tingkatkan aktivitas fisik minimal 30 menit/hari.';
      case 'Overweight_Tingkat_2':
        return 'Konsultasi dokter. Perlu diet ketat, hindari makanan berlemak, dan olahraga teratur.';
      case 'Obesitas_Tipe_1':
        return 'Segera konsultasi dokter. Diet rendah kalori dan olahraga rutin sangat dianjurkan.';
      case 'Obesitas_Tipe_2':
        return 'Konsultasi dokter spesialis. Mungkin perlu penanganan medis dan perubahan gaya hidup drastis.';
      case 'Obesitas_Tipe_3':
        return 'Segera tangani dengan dokter spesialis. Risiko kesehatan sangat tinggi.';
      default:
        return 'Konsultasikan dengan tenaga medis.';
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFF43A047),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
  }

  // ════════════════════════════════════════════════════════
  //  NAVIGASI WIZARD
  // ════════════════════════════════════════════════════════
  void _nextStep() {
    if (!_formKeys[_currentStep].currentState!.validate()) return;
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageCtrl.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _predict();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageCtrl.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  void _resetWizard() {
    for (final c in [_usiaCtrl, _tinggiCtrl, _beratCtrl, _sayurCtrl,
        _makanCtrl, _airCtrl, _aktivitasCtrl, _layarCtrl]) {
      c.clear();
    }
    setState(() {
      _currentStep = 0; _result = null; _isSaved = false;
      _jenisKelamin = 'Laki-laki'; _alkohol = 'Tidak';
      _kaloriTinggi = 'Tidak'; _monitoring = 'Tidak';
      _merokok = 'Tidak'; _riwayat = 'Ya';
      _ngamil = 'Kadang'; _transport = 'Motor';
    });
    _pageCtrl.animateToPage(0,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  // ════════════════════════════════════════════════════════
  //  PREDIKSI
  // ════════════════════════════════════════════════════════
  Future<void> _predict() async {
    setState(() { _isLoading = true; _result = null; });
    try {
      final result = await ApiService.predictObesity(
        usia:         double.parse(_usiaCtrl.text),
        tinggi:       double.parse(_tinggiCtrl.text),
        berat:        double.parse(_beratCtrl.text),
        jenisKelamin: _jenisKelamin,
        alkohol:      _alkohol,
        kaloriTinggi: _kaloriTinggi,
        monitoring:   _monitoring,
        merokok:      _merokok,
        riwayat:      _riwayat,
        ngamil:       _ngamil,
        transport:    _transport,
        sayur:        double.parse(_sayurCtrl.text),
        makanHarian:  int.parse(_makanCtrl.text),
        konsumsiAir:  double.parse(_airCtrl.text),
        aktivitas:    double.parse(_aktivitasCtrl.text),
        waktuLayar:   double.parse(_layarCtrl.text),
      );
      setState(() => _result = result);
    } catch (e) {
      _showSnack('Gagal prediksi: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ════════════════════════════════════════════════════════
  //  SIMPAN KE MONGODB via Laravel POST /api/obesity/save
  // ════════════════════════════════════════════════════════
  Future<void> _simpan() async {
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ??
                    prefs.getString('auth_token') ?? '';

      print('=== TOKEN: $token ===');

      if (token.isEmpty) {
        _showSnack('Anda belum login!', isError: true);
        return;
      }

      final payload = {
        'prediksi': {
          'input': {
            'usia'            : double.parse(_usiaCtrl.text),
            'tinggi'          : double.parse(_tinggiCtrl.text),
            'berat'           : double.parse(_beratCtrl.text),
            'jenis_kelamin'   : _jenisKelamin,
            'kalori_tinggi'   : _kaloriTinggi,
            'konsumsi_sayur'  : double.parse(_sayurCtrl.text),
            'makan_harian'    : int.parse(_makanCtrl.text),
            'ngemil'          : _ngamil,
            'konsumsi_air'    : double.parse(_airCtrl.text),
            'alkohol'         : _alkohol,
            'monitoring'      : _monitoring,
            'merokok'         : _merokok,
            'riwayat_keluarga': _riwayat,
            'aktivitas_fisik' : double.parse(_aktivitasCtrl.text),
            'waktu_layar'     : double.parse(_layarCtrl.text),
            'transportasi'    : _transport,
          },
          'hasil': {
            'kategori'  : _result!['kategori'],
            'bmi'       : _result!['bmi'],
            'confidence': _result!['confidence'],
          },
          'prediksi_at': DateTime.now().toIso8601String(),
        },
      };

      print('=== SIMPAN PAYLOAD ===');
      print(jsonEncode(payload));
      print('=== SIMPAN URL: ${ApiService.baseUrl}/obesity/save ==='); // ✅ debug URL

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/obesity/save'), // ✅ pakai ApiService.baseUrl
        headers: {
          'Content-Type' : 'application/json',
          'Accept'       : 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      print('SIMPAN STATUS: ${response.statusCode}');
      print('SIMPAN BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _isSaved = true);
        _showSnack('Hasil prediksi berhasil disimpan ke akun Anda!', isError: false);
      } else {
        final body = jsonDecode(response.body);
        _showSnack(body['message'] ?? 'Gagal menyimpan data.', isError: true);
      }

    } on http.ClientException catch (e) {
      _showSnack('Tidak dapat terhubung ke server: ${e.message}', isError: true);
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _neutral50,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        backgroundColor: _teal700,
        elevation: 0,
        title: const Text('Prediksi Obesitas',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
              color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildProgressHeader(),
          Expanded(
            child: _result != null
                ? _buildHasilPage()
                : PageView(
                    controller: _pageCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep0DataFisik(),
                      _buildStep1PolaMakan(),
                      _buildStep2GayaHidup(),
                      _buildStep3Aktivitas(),
                    ],
                  ),
          ),
          if (_result == null) _buildNavBar(),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  PROGRESS HEADER
  // ════════════════════════════════════════════════════════
  Widget _buildProgressHeader() {
    final labels = ['Data Fisik', 'Pola Makan', 'Gaya Hidup', 'Aktivitas'];
    final icons  = [
      Icons.person_outline_rounded,
      Icons.restaurant_menu_rounded,
      Icons.spa_outlined,
      Icons.directions_run_rounded,
    ];

    return Container(
      color: _teal700,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalSteps * 2 - 1, (i) {
              if (i.isOdd) {
                final stepIdx = i ~/ 2;
                final passed  = stepIdx < _currentStep || _result != null;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 2,
                    color: passed ? Colors.white : Colors.white30,
                  ),
                );
              }
              final idx      = i ~/ 2;
              final isDone   = idx < _currentStep || _result != null;
              final isActive = idx == _currentStep && _result == null;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 44 : 36,
                height: isActive ? 44 : 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone || isActive
                      ? Colors.white
                      : Colors.white.withOpacity(0.15),
                  border: Border.all(
                    color: isDone || isActive ? Colors.white : Colors.white38,
                    width: isActive ? 2.5 : 1.5,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? Icon(Icons.check_rounded, color: _teal700, size: 18)
                      : Icon(icons[idx],
                          color: isActive ? _teal700 : Colors.white54,
                          size: isActive ? 22 : 18),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _result != null
                  ? '✅  Prediksi Selesai'
                  : '${_currentStep + 1}/$_totalSteps  —  ${labels[_currentStep]}',
              style: const TextStyle(fontSize: 12, color: Colors.white,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  NAV BAR BAWAH
  // ════════════════════════════════════════════════════════
  Widget _buildNavBar() {
    final isLast = _currentStep == _totalSteps - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16,
          MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _neutral100)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _prevStep,
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                label: const Text('Kembali'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _teal700,
                  side: const BorderSide(color: _teal700, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _nextStep,
              icon: _isLoading
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(isLast
                      ? Icons.analytics_rounded
                      : Icons.arrow_forward_ios_rounded,
                      size: 15),
              label: Text(
                _isLoading ? 'Memproses...' : isLast ? 'Prediksi Sekarang' : 'Lanjut',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _neutral200,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  HASIL PAGE
  // ════════════════════════════════════════════════════════
  Widget _buildHasilPage() {
    final kategori   = _result!['kategori'] as String;
    final bmi        = (_result!['bmi'] as num).toDouble();
    final confidence = (_result!['confidence'] as num).toDouble();
    final color      = _kategoriColor(kategori);
    final rek        = _rekomendasi(kategori);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 16, 16,
          MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // Kartu hasil
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.35),
                    blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.analytics_rounded,
                    color: Colors.white, size: 48),
                const SizedBox(height: 10),
                const Text('Hasil Prediksi',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text(kategori.replaceAll('_', ' '),
                  style: const TextStyle(fontSize: 24,
                      fontWeight: FontWeight.w900, color: Colors.white),
                  textAlign: TextAlign.center),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _metricChip('BMI', bmi.toStringAsFixed(1), 'kg/m²'),
                      Container(width: 1, height: 36, color: Colors.white30),
                      _metricChip('Akurasi',
                          '${confidence.toStringAsFixed(1)}%', ''),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Tombol Simpan + Ulang
          Row(
            children: [
              Expanded(
                flex: 3,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isSaved
                      ? Container(
                          key: const ValueKey('saved'),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFA5D6A7)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF43A047), size: 18),
                              SizedBox(width: 6),
                              Text('Tersimpan',
                                style: TextStyle(color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w700)),
                            ],
                          ),
                        )
                      : ElevatedButton.icon(
                          key: const ValueKey('save_btn'),
                          onPressed: _isSaving ? null : _simpan,
                          icon: _isSaving
                              ? const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save_rounded, size: 18),
                          label: Text(
                            _isSaving ? 'Menyimpan...' : 'Simpan Hasil',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: _resetWizard,
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text('Ulang',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _teal700,
                    side: const BorderSide(color: _teal700, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),

          if (!_isSaved) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload_outlined, size: 12, color: _neutral400),
                const SizedBox(width: 4),
                Text('Simpan ke riwayat akun Anda',
                  style: TextStyle(fontSize: 11, color: _neutral400)),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Rekomendasi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _neutral100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.lightbulb_outline_rounded,
                        color: Colors.amber.shade700, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Rekomendasi',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ]),
                const SizedBox(height: 12),
                Text(rek, style: TextStyle(fontSize: 14,
                    height: 1.6, color: _neutral600)),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _buildRingkasan(),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value, String unit) => Column(
    children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      const SizedBox(height: 4),
      Text(unit.isEmpty ? value : '$value $unit',
        style: const TextStyle(color: Colors.white,
            fontSize: 20, fontWeight: FontWeight.w900)),
    ],
  );

  Widget _buildRingkasan() {
    final items = [
      (Icons.cake_outlined,           'Usia',          '${_usiaCtrl.text} tahun'),
      (Icons.height_rounded,          'Tinggi',        '${_tinggiCtrl.text} m'),
      (Icons.monitor_weight_outlined, 'Berat',         '${_beratCtrl.text} kg'),
      (Icons.person_outline_rounded,  'Jenis Kelamin', _jenisKelamin),
      (Icons.eco_outlined,            'Sayur & Buah',  '${_sayurCtrl.text} porsi/hari'),
      (Icons.restaurant_outlined,     'Makan Harian',  '${_makanCtrl.text}x/hari'),
      (Icons.water_drop_outlined,     'Air Putih',     '${_airCtrl.text} L/hari'),
      (Icons.directions_run_rounded,  'Aktivitas',     '${_aktivitasCtrl.text} jam/hari'),
      (Icons.tv_outlined,             'Waktu Layar',   '${_layarCtrl.text} jam/hari'),
      (Icons.commute_outlined,        'Transportasi',  _transport.replaceAll('_', ' ')),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _neutral100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: _teal50, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.list_alt_rounded, color: _teal700, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Ringkasan Data',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ]),
          ),
          Divider(height: 1, color: _neutral100),
          ...items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            final item   = e.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 11),
                  child: Row(children: [
                    Icon(item.$1, size: 15, color: _neutral400),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item.$2,
                        style: TextStyle(color: _neutral600, fontSize: 13))),
                    Text(item.$3,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                ),
                if (!isLast)
                  Divider(height: 1, indent: 41, color: _neutral50),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  STEP PAGES
  // ════════════════════════════════════════════════════════
  Widget _buildStep0DataFisik() => _wrap(_formKeys[0],
    Icons.person_outline_rounded, 'Data Fisik',
    'Masukkan informasi dasar tubuh Anda',
    [
      _info('Data ini digunakan untuk menghitung BMI sebagai dasar prediksi obesitas.'),
      _tf('Usia', 'Contoh: 22', 'tahun', _usiaCtrl, 'Umur Anda saat ini dalam tahun.'),
      _dd('Jenis Kelamin', _jenisKelamin, ['Laki-laki', 'Perempuan'],
          (v) => setState(() => _jenisKelamin = v!),
          'Faktor biologis yang mempengaruhi distribusi lemak tubuh.'),
      _tf('Tinggi Badan', 'Contoh: 1.70', 'meter', _tinggiCtrl,
          'Dalam satuan meter. Contoh: 170 cm → 1.70'),
      _tf('Berat Badan', 'Contoh: 65.0', 'kg', _beratCtrl,
          'Masukkan berat badan dalam kilogram.'),
    ],
  );

  Widget _buildStep1PolaMakan() => _wrap(_formKeys[1],
    Icons.restaurant_menu_rounded, 'Pola Makan',
    'Ceritakan kebiasaan makan sehari-hari',
    [
      _dd('Konsumsi Makanan Tinggi Kalori', _kaloriTinggi, ['Tidak', 'Ya'],
          (v) => setState(() => _kaloriTinggi = v!),
          'Apakah sering mengonsumsi fast food, gorengan, atau makanan berlemak?'),
      _tf('Konsumsi Sayur & Buah', 'Contoh: 2.0', 'porsi/hari', _sayurCtrl,
          '1 porsi ≈ 1 mangkuk sayur atau 1 buah sedang.'),
      _tf('Jumlah Makan Harian', 'Contoh: 3', 'kali/hari', _makanCtrl,
          'Termasuk sarapan, makan siang, dan makan malam.', isInt: true),
      _dd('Kebiasaan Ngemil', _ngamil, ['Tidak','Kadang','Sering','Selalu'],
          (v) => setState(() => _ngamil = v!),
          'Kadang: 1-2x/minggu  •  Sering: hampir tiap hari  •  Selalu: setiap hari'),
      _tf('Konsumsi Air Putih', 'Contoh: 2.0', 'L/hari', _airCtrl,
          'Rekomendasi WHO: minimal 2 liter (8 gelas) per hari.'),
    ],
  );

  Widget _buildStep2GayaHidup() => _wrap(_formKeys[2],
    Icons.spa_outlined, 'Gaya Hidup',
    'Kebiasaan dan riwayat kesehatan Anda',
    [
      _dd('Konsumsi Alkohol', _alkohol, ['Tidak','Kadang','Sering','Selalu'],
          (v) => setState(() => _alkohol = v!),
          'Alkohol mengandung kalori kosong yang dapat meningkatkan berat badan.'),
      _dd('Monitoring Kalori Harian', _monitoring, ['Tidak','Ya'],
          (v) => setState(() => _monitoring = v!),
          'Apakah aktif mencatat kalori? (misal: menggunakan aplikasi diet)'),
      _dd('Kebiasaan Merokok', _merokok, ['Tidak','Ya'],
          (v) => setState(() => _merokok = v!),
          'Merokok dapat mempengaruhi metabolisme dan distribusi lemak tubuh.'),
      _dd('Riwayat Keluarga Overweight', _riwayat, ['Ya','Tidak'],
          (v) => setState(() => _riwayat = v!),
          'Faktor genetik berperan besar dalam risiko obesitas.'),
    ],
  );

  Widget _buildStep3Aktivitas() => _wrap(_formKeys[3],
    Icons.directions_run_rounded, 'Aktivitas Fisik',
    'Seberapa aktif Anda bergerak setiap hari?',
    [
      _info('WHO: minimal 150 menit aktivitas fisik sedang per minggu (≈ 21 menit/hari).'),
      _tf('Aktivitas Fisik', 'Contoh: 1.0', 'jam/hari', _aktivitasCtrl,
          'Rata-rata durasi olahraga per hari (jalan kaki, lari, gym, dll).'),
      _tf('Waktu di Depan Layar', 'Contoh: 3.0', 'jam/hari', _layarCtrl,
          'Total waktu di depan HP, laptop, atau TV per hari.'),
      _dd('Transportasi Utama', _transport,
          ['Motor','Mobil','Jalan_Kaki','Sepeda','Transportasi_Umum'],
          (v) => setState(() => _transport = v!),
          'Jalan kaki & Sepeda lebih aktif  •  Motor/Mobil cenderung sedentari',
          displayMap: {
            'Motor':'Motor','Mobil':'Mobil','Jalan_Kaki':'Jalan Kaki',
            'Sepeda':'Sepeda','Transportasi_Umum':'Transportasi Umum',
          }),
      _info('Semua data siap! Tekan "Prediksi Sekarang".',
          color: const Color(0xFF388E3C)),
    ],
  );

  // ════════════════════════════════════════════════════════
  //  REUSABLE WIDGETS
  // ════════════════════════════════════════════════════════
  Widget _wrap(GlobalKey<FormState> key, IconData icon,
      String title, String sub, List<Widget> children) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Form(
        key: key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _neutral100),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: _teal50, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: _teal700, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 17,
                        fontWeight: FontWeight.w800, color: _teal700)),
                    const SizedBox(height: 2),
                    Text(sub, style: TextStyle(fontSize: 12, color: _neutral400)),
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _tf(String label, String hint, String suffix,
      TextEditingController ctrl, String help, {bool isInt = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: ctrl,
            keyboardType: isInt
                ? TextInputType.number
                : const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              suffixText: suffix,
              suffixStyle: TextStyle(color: _neutral400, fontSize: 12),
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _neutral200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _neutral200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _teal500, width: 1.8),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE53935)),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Wajib diisi';
              final n = isInt ? int.tryParse(v) : double.tryParse(v);
              if (n == null) return 'Masukkan angka yang valid';
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 2),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.help_outline_rounded, size: 13, color: _neutral400),
              const SizedBox(width: 4),
              Expanded(child: Text(help,
                  style: TextStyle(fontSize: 11.5,
                      color: _neutral400, height: 1.4))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _dd(String label, String value, List<String> items,
      void Function(String?) onChanged, String help,
      {Map<String, String>? displayMap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              labelText: label,
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _neutral200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _neutral200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _teal500, width: 1.8),
              ),
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            items: items.map((e) => DropdownMenuItem(
              value: e, child: Text(displayMap?[e] ?? e))).toList(),
            onChanged: onChanged,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 2),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.help_outline_rounded, size: 13, color: _neutral400),
              const SizedBox(width: 4),
              Expanded(child: Text(help,
                  style: TextStyle(fontSize: 11.5,
                      color: _neutral400, height: 1.4))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _info(String text, {Color color = const Color(0xFF00796B)}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline_rounded, color: color, size: 17),
        const SizedBox(width: 10),
        Expanded(child: Text(text,
            style: TextStyle(fontSize: 12.5,
                color: color.withOpacity(0.9), height: 1.5))),
      ]),
    );
  }
}