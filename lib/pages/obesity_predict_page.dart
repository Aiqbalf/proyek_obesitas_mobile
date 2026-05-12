import 'package:flutter/material.dart';
import '../services/obesity_service.dart';

class ObesityPredictPage extends StatefulWidget {
  const ObesityPredictPage({super.key, required bool embedded});

  @override
  State<ObesityPredictPage> createState() => _ObesityPredictPageState();
}

class _ObesityPredictPageState extends State<ObesityPredictPage> {
  // ── Page Controller ─────────────────────────────────────
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4; // Step 0–3 (hasil tampil di step 3 setelah submit)

  bool _isLoading = false;
  Map<String, dynamic>? _result;

  // ── Form Keys per Step ───────────────────────────────────
  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());

  // ── Controllers ──────────────────────────────────────────
  final _usiaCtrl      = TextEditingController(text: '22');
  final _tinggiCtrl    = TextEditingController(text: '1.70');
  final _beratCtrl     = TextEditingController(text: '65.0');
  final _sayurCtrl     = TextEditingController(text: '2.0');
  final _makanCtrl     = TextEditingController(text: '3');
  final _airCtrl       = TextEditingController(text: '2.0');
  final _aktivitasCtrl = TextEditingController(text: '1.0');
  final _layarCtrl     = TextEditingController(text: '1.0');

  // ── Dropdowns ────────────────────────────────────────────
  String _jenisKelamin = 'Laki-laki';
  String _alkohol      = 'Tidak';
  String _kaloriTinggi = 'Tidak';
  String _monitoring   = 'Tidak';
  String _merokok      = 'Tidak';
  String _riwayat      = 'Ya';
  String _ngamil       = 'Kadang';
  String _transport    = 'Motor';

  @override
  void dispose() {
    _pageController.dispose();
    _usiaCtrl.dispose();
    _tinggiCtrl.dispose();
    _beratCtrl.dispose();
    _sayurCtrl.dispose();
    _makanCtrl.dispose();
    _airCtrl.dispose();
    _aktivitasCtrl.dispose();
    _layarCtrl.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════
  //  HELPER — warna & teks
  // ════════════════════════════════════════════════════════
  Color _getKategoriColor(String k) {
    switch (k) {
      case 'Kurus':                return Colors.blue;
      case 'Normal':               return Colors.green;
      case 'Overweight_Tingkat_1': return Colors.yellow.shade700;
      case 'Overweight_Tingkat_2': return Colors.orange;
      case 'Obesitas_Tipe_1':      return Colors.red.shade300;
      case 'Obesitas_Tipe_2':      return Colors.red.shade600;
      case 'Obesitas_Tipe_3':      return Colors.red.shade900;
      default:                     return Colors.grey;
    }
  }

  String _getRekomendasi(String k) {
    switch (k) {
      case 'Kurus':
        return 'Tingkatkan asupan kalori bergizi. Konsultasi dengan ahli '
            'gizi untuk program penambahan berat badan yang sehat.';
      case 'Normal':
        return 'Pertahankan pola makan sehat dan aktivitas fisik rutin. '
            'Anda berada di kondisi ideal!';
      case 'Overweight_Tingkat_1':
        return 'Kurangi makanan tinggi kalori, tingkatkan aktivitas fisik '
            'minimal 30 menit/hari.';
      case 'Overweight_Tingkat_2':
        return 'Konsultasi dokter. Perlu diet ketat, hindari makanan '
            'berlemak, dan olahraga teratur.';
      case 'Obesitas_Tipe_1':
        return 'Segera konsultasi dokter. Diet rendah kalori dan olahraga '
            'rutin sangat dianjurkan.';
      case 'Obesitas_Tipe_2':
        return 'Konsultasi dokter spesialis. Mungkin perlu penanganan '
            'medis dan perubahan gaya hidup drastis.';
      case 'Obesitas_Tipe_3':
        return 'Segera tangani dengan dokter spesialis. Risiko kesehatan '
            'sangat tinggi — perlu intervensi medis segera.';
      default:
        return 'Konsultasikan dengan tenaga medis.';
    }
  }

  // ════════════════════════════════════════════════════════
  //  NAVIGASI WIZARD
  // ════════════════════════════════════════════════════════
  void _nextStep() {
    // Validasi form step saat ini
    if (!_formKeys[_currentStep].currentState!.validate()) return;

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      // Step terakhir → prediksi
      _predict();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _resetWizard() {
    setState(() {
      _currentStep = 0;
      _result = null;
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  // ════════════════════════════════════════════════════════
  //  PREDIKSI
  // ════════════════════════════════════════════════════════
  Future<void> _predict() async {
    setState(() { _isLoading = true; _result = null; });
    try {
      final result = await ObesityService.predictObesity(
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Prediksi Obesitas'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Progress Header ──────────────────────────────
          _buildProgressHeader(),

          // ── Konten Step ─────────────────────────────────
          Expanded(
            child: _result != null
                ? _buildHasilPage()
                : PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep0DataFisik(),
                      _buildStep1PolaMakan(),
                      _buildStep2GayaHidup(),
                      _buildStep3Aktivitas(),
                    ],
                  ),
          ),

          // ── Tombol Navigasi ─────────────────────────────
          if (_result == null) _buildNavBar(),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  PROGRESS HEADER
  // ════════════════════════════════════════════════════════
  Widget _buildProgressHeader() {
    final steps = ['Data Fisik', 'Pola Makan', 'Gaya Hidup', 'Aktivitas'];
    final icons = [
      Icons.person_outline,
      Icons.restaurant_menu,
      Icons.local_drink,
      Icons.directions_run,
    ];

    return Container(
      color: Colors.teal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Step indicators
          Row(
            children: List.generate(_totalSteps, (i) {
              final isActive   = i == _currentStep && _result == null;
              final isDone     = i < _currentStep || _result != null;
              final isInactive = !isActive && !isDone;

              return Expanded(
                child: Row(
                  children: [
                    // Lingkaran step
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? Colors.white
                            : isActive
                                ? Colors.white
                                : Colors.teal.shade300,
                        border: Border.all(
                          color: Colors.white,
                          width: isActive ? 3 : 1.5,
                        ),
                      ),
                      child: Center(
                        child: isDone
                            ? Icon(Icons.check,
                                color: Colors.teal, size: 18)
                            : Icon(icons[i],
                                color: isInactive
                                    ? Colors.white60
                                    : Colors.teal,
                                size: 18),
                      ),
                    ),
                    // Garis penghubung
                    if (i < _totalSteps - 1)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 2,
                          color: i < _currentStep || _result != null
                              ? Colors.white
                              : Colors.white30,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // Label step aktif
          if (_result == null)
            Text(
              'Langkah ${_currentStep + 1} dari $_totalSteps — '
              '${steps[_currentStep]}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            )
          else
            const Text(
              '✅ Prediksi Selesai',
              style: TextStyle(color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.bold),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          // Tombol Kembali
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _prevStep,
                icon: const Icon(Icons.arrow_back_ios, size: 16),
                label: const Text('Kembali'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal,
                  side: const BorderSide(color: Colors.teal),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),

          // Tombol Lanjut / Prediksi
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _nextStep,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(isLast ? Icons.analytics : Icons.arrow_forward_ios,
                      size: 16),
              label: Text(
                _isLoading
                    ? 'Memproses...'
                    : isLast
                        ? 'Prediksi Sekarang'
                        : 'Lanjut',
                style: const TextStyle(fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  STEP 0 — DATA FISIK
  // ════════════════════════════════════════════════════════
  Widget _buildStep0DataFisik() {
    return _stepWrapper(
      formKey: _formKeys[0],
      icon: Icons.person_outline,
      title: 'Data Fisik',
      subtitle: 'Masukkan informasi dasar tubuh Anda',
      children: [
        _infoBox(
          icon: Icons.info_outline,
          text: 'Data ini digunakan untuk menghitung BMI (Body Mass Index) '
              'sebagai dasar prediksi obesitas.',
        ),
        _buildTF(
          label: 'Usia',
          hint: 'Contoh: 22',
          suffix: 'tahun',
          ctrl: _usiaCtrl,
          help: 'Masukkan umur Anda saat ini dalam tahun.',
        ),
        _buildDropdownItem(
          label: 'Jenis Kelamin',
          value: _jenisKelamin,
          items: ['Laki-laki', 'Perempuan'],
          onChanged: (v) => setState(() => _jenisKelamin = v!),
          help: 'Faktor biologis yang mempengaruhi distribusi lemak tubuh.',
        ),
        _buildTF(
          label: 'Tinggi Badan',
          hint: 'Contoh: 1.70',
          suffix: 'meter',
          ctrl: _tinggiCtrl,
          help: 'Masukkan tinggi badan dalam satuan meter (bukan cm).\n'
              'Contoh: 170 cm → 1.70',
        ),
        _buildTF(
          label: 'Berat Badan',
          hint: 'Contoh: 65.0',
          suffix: 'kg',
          ctrl: _beratCtrl,
          help: 'Masukkan berat badan Anda dalam kilogram.',
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  //  STEP 1 — POLA MAKAN
  // ════════════════════════════════════════════════════════
  Widget _buildStep1PolaMakan() {
    return _stepWrapper(
      formKey: _formKeys[1],
      icon: Icons.restaurant_menu,
      title: 'Pola Makan',
      subtitle: 'Ceritakan kebiasaan makan Anda sehari-hari',
      children: [
        _buildDropdownItem(
          label: 'Konsumsi Makanan Tinggi Kalori',
          value: _kaloriTinggi,
          items: ['Tidak', 'Ya'],
          onChanged: (v) => setState(() => _kaloriTinggi = v!),
          help: 'Apakah Anda sering mengonsumsi makanan '
              'berlemak tinggi, fast food, atau gorengan?',
        ),
        _buildTF(
          label: 'Konsumsi Sayur & Buah',
          hint: 'Contoh: 2.0',
          suffix: 'porsi/hari',
          ctrl: _sayurCtrl,
          help: 'Rata-rata porsi sayur dan buah yang Anda makan per hari.\n'
              '1 porsi ≈ 1 mangkuk sayur atau 1 buah sedang.',
        ),
        _buildTF(
          label: 'Jumlah Makan Harian',
          hint: 'Contoh: 3',
          suffix: 'kali/hari',
          ctrl: _makanCtrl,
          help: 'Berapa kali Anda makan dalam sehari '
              '(termasuk sarapan, makan siang, makan malam).',
          isInt: true,
        ),
        _buildDropdownItem(
          label: 'Kebiasaan Ngemil (CAEC)',
          value: _ngamil,
          items: ['Tidak', 'Kadang', 'Sering', 'Selalu'],
          onChanged: (v) => setState(() => _ngamil = v!),
          help: 'Seberapa sering Anda ngemil di antara waktu makan?\n'
              '• Kadang: 1-2x seminggu\n'
              '• Sering: hampir tiap hari\n'
              '• Selalu: setiap hari',
        ),
        _buildTF(
          label: 'Konsumsi Air Putih',
          hint: 'Contoh: 2.0',
          suffix: 'liter/hari',
          ctrl: _airCtrl,
          help: 'Rata-rata konsumsi air putih per hari.\n'
              'Rekomendasi WHO: minimal 2 liter (8 gelas) per hari.',
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  //  STEP 2 — GAYA HIDUP
  // ════════════════════════════════════════════════════════
  Widget _buildStep2GayaHidup() {
    return _stepWrapper(
      formKey: _formKeys[2],
      icon: Icons.local_drink,
      title: 'Gaya Hidup',
      subtitle: 'Informasi kebiasaan dan riwayat kesehatan',
      children: [
        _buildDropdownItem(
          label: 'Konsumsi Alkohol (CALC)',
          value: _alkohol,
          items: ['Tidak', 'Kadang', 'Sering', 'Selalu'],
          onChanged: (v) => setState(() => _alkohol = v!),
          help: 'Seberapa sering Anda mengonsumsi minuman beralkohol?\n'
              'Alkohol mengandung kalori kosong yang dapat meningkatkan '
              'berat badan.',
        ),
        _buildDropdownItem(
          label: 'Monitoring Kalori Harian',
          value: _monitoring,
          items: ['Tidak', 'Ya'],
          onChanged: (v) => setState(() => _monitoring = v!),
          help: 'Apakah Anda aktif mencatat atau memantau '
              'jumlah kalori yang dikonsumsi setiap hari?\n'
              '(Misalnya menggunakan aplikasi diet)',
        ),
        _buildDropdownItem(
          label: 'Kebiasaan Merokok',
          value: _merokok,
          items: ['Tidak', 'Ya'],
          onChanged: (v) => setState(() => _merokok = v!),
          help: 'Apakah Anda seorang perokok aktif?\n'
              'Merokok dapat mempengaruhi metabolisme dan distribusi '
              'lemak tubuh.',
        ),
        _buildDropdownItem(
          label: 'Riwayat Keluarga Overweight',
          value: _riwayat,
          items: ['Ya', 'Tidak'],
          onChanged: (v) => setState(() => _riwayat = v!),
          help: 'Apakah ada anggota keluarga (orang tua/saudara kandung) '
              'yang memiliki riwayat kelebihan berat badan?\n'
              'Faktor genetik berperan besar dalam risiko obesitas.',
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  //  STEP 3 — AKTIVITAS
  // ════════════════════════════════════════════════════════
  Widget _buildStep3Aktivitas() {
    return _stepWrapper(
      formKey: _formKeys[3],
      icon: Icons.directions_run,
      title: 'Aktivitas Fisik',
      subtitle: 'Seberapa aktif Anda bergerak setiap hari?',
      children: [
        _infoBox(
          icon: Icons.favorite_outline,
          text: 'WHO merekomendasikan minimal 150 menit aktivitas fisik '
              'sedang per minggu (≈ 21 menit/hari).',
        ),
        _buildTF(
          label: 'Aktivitas Fisik',
          hint: 'Contoh: 1.0',
          suffix: 'jam/hari',
          ctrl: _aktivitasCtrl,
          help: 'Rata-rata durasi olahraga atau aktivitas fisik '
              'per hari.\n'
              'Contoh: jalan kaki, lari, gym, bersepeda, dll.',
        ),
        _buildTF(
          label: 'Waktu di Depan Layar',
          hint: 'Contoh: 3.0',
          suffix: 'jam/hari',
          ctrl: _layarCtrl,
          help: 'Rata-rata waktu yang dihabiskan di depan layar '
              '(HP, laptop, TV) per hari.\n'
              'Terlalu lama duduk berkaitan dengan risiko obesitas.',
        ),
        _buildDropdownItem(
          label: 'Transportasi Utama',
          value: _transport,
          items: [
            'Motor',
            'Mobil',
            'Jalan_Kaki',
            'Sepeda',
            'Transportasi_Umum',
          ],
          onChanged: (v) => setState(() => _transport = v!),
          help: 'Moda transportasi yang paling sering Anda gunakan '
              'sehari-hari.\n'
              '• Jalan kaki & Sepeda → lebih aktif\n'
              '• Motor/Mobil → cenderung lebih sedentari',
          displayMap: {
            'Motor': 'Motor',
            'Mobil': 'Mobil',
            'Jalan_Kaki': 'Jalan Kaki',
            'Sepeda': 'Sepeda',
            'Transportasi_Umum': 'Transportasi Umum',
          },
        ),
        const SizedBox(height: 8),
        _infoBox(
          icon: Icons.check_circle_outline,
          text: 'Semua data telah diisi! Tekan "Prediksi Sekarang" '
              'untuk mendapatkan hasil analisis.',
          color: Colors.green,
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  //  HASIL PAGE
  // ════════════════════════════════════════════════════════
  Widget _buildHasilPage() {
    final result     = _result!;
    final kategori   = result['kategori'] as String;
    final bmi        = result['bmi'];
    final confidence = result['confidence'];
    final color      = _getKategoriColor(kategori);
    final rekomendasi = _getRekomendasi(kategori);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Kartu Utama ────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.analytics, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text('Hasil Prediksi',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  kategori.replaceAll('_', ' '),
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _whiteMetric('BMI',
                        '${bmi.toStringAsFixed(2)}', 'kg/m²'),
                    Container(width: 1, height: 40, color: Colors.white38),
                    _whiteMetric('Confidence',
                        '${confidence.toStringAsFixed(1)}', '%'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Rekomendasi ────────────────────────────────
          _buildRekomendasiCard(rekomendasi),

          const SizedBox(height: 16),

          // ── Ringkasan Input ────────────────────────────
          _buildRingkasanInput(),

          const SizedBox(height: 16),

          // ── Tombol Ulangi ──────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resetWizard,
              icon: const Icon(Icons.refresh),
              label: const Text('Prediksi Ulang',
                  style: TextStyle(fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _whiteMetric(String label, String value, String unit) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRekomendasiCard(String rekomendasi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue),
              SizedBox(width: 8),
              Text('Rekomendasi',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          Text(rekomendasi, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildRingkasanInput() {
    final items = [
      ('Usia',          '${_usiaCtrl.text} tahun'),
      ('Tinggi',        '${_tinggiCtrl.text} m'),
      ('Berat',         '${_beratCtrl.text} kg'),
      ('Jenis Kelamin', _jenisKelamin),
      ('Sayur & Buah',  '${_sayurCtrl.text} porsi/hari'),
      ('Makan Harian',  '${_makanCtrl.text}x/hari'),
      ('Konsumsi Air',  '${_airCtrl.text} L/hari'),
      ('Aktivitas',     '${_aktivitasCtrl.text} jam/hari'),
      ('Waktu Layar',   '${_layarCtrl.text} jam/hari'),
      ('Transportasi',  _transport.replaceAll('_', ' ')),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(Icons.list_alt, color: Colors.grey.shade600, size: 18),
                const SizedBox(width: 8),
                Text('Ringkasan Data',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...items.map((e) => _ringkasanRow(e.$1, e.$2)),
        ],
      ),
    );
  }

  Widget _ringkasanRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  REUSABLE WIDGETS
  // ════════════════════════════════════════════════════════

  /// Wrapper scrollable untuk tiap step
  Widget _stepWrapper({
    required GlobalKey<FormState> formKey,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header step
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.teal, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal)),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// TextField dengan label, hint, satuan, dan teks bantuan
  Widget _buildTF({
    required String label,
    required String hint,
    required String suffix,
    required TextEditingController ctrl,
    required String help,
    bool isInt = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: ctrl,
            keyboardType:
                isInt ? TextInputType.number : TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              suffixText: suffix,
              suffixStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Wajib diisi';
              final n = isInt ? int.tryParse(v) : double.tryParse(v);
              if (n == null) return 'Masukkan angka yang valid';
              return null;
            },
          ),
          // Teks bantuan
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.help_outline,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    help,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Dropdown dengan teks bantuan
  Widget _buildDropdownItem({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required String help,
    Map<String, String>? displayMap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              labelText: label,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              filled: true,
              fillColor: Colors.white,
            ),
            items: items.map((e) {
              final display = displayMap?[e] ?? e;
              return DropdownMenuItem(value: e, child: Text(display));
            }).toList(),
            onChanged: onChanged,
          ),
          // Teks bantuan
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.help_outline,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    help,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Info box berwarna
  Widget _infoBox({
    required IconData icon,
    required String text,
    Color color = Colors.teal,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 13, color: color.withOpacity(0.9), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
