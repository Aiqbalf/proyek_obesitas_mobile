
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BmiPage extends StatefulWidget {
  final bool embedded;
  const BmiPage({super.key, this.embedded = false});

  @override
  State<BmiPage> createState() => _BmiPageState();
}

class _BmiPageState extends State<BmiPage> with TickerProviderStateMixin {
  final _heightCtrl = TextEditingController(text: '170');
  final _weightCtrl = TextEditingController(text: '60');

  String _gender = 'Laki-laki';
  double? _bmi;

  // ── Palette (selaras dengan DashboardPage) ──
  static const Color _green900  = Color(0xFF064E3B);
  static const Color _green700  = Color(0xFF047857);
  static const Color _green500  = Color(0xFF10B981);
  static const Color _green100  = Color(0xFFD1FAE5);
  static const Color _green50   = Color(0xFFF0FDF4);
  static const Color _neutral50  = Color(0xFFF9FAFB);
  static const Color _neutral100 = Color(0xFFF3F4F6);
  static const Color _neutral200 = Color(0xFFE5E7EB);
  static const Color _neutral400 = Color(0xFF9CA3AF);
  static const Color _neutral600 = Color(0xFF4B5563);
  static const Color _neutral900 = Color(0xFF111827);

  late AnimationController _resultAnim;
  late Animation<double> _resultFade;
  late Animation<Offset> _resultSlide;

  @override
  void initState() {
    super.initState();
    _resultAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _resultFade = CurvedAnimation(parent: _resultAnim, curve: Curves.easeOut);
    _resultSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _resultAnim, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _resultAnim.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final h = double.tryParse(_heightCtrl.text);
    final w = double.tryParse(_weightCtrl.text);
    if (h != null && w != null && h > 0) {
      HapticFeedback.mediumImpact();
      setState(() => _bmi = w / ((h / 100) * (h / 100)));
      _resultAnim.forward(from: 0);
    }
  }

  void _reset() {
    setState(() => _bmi = null);
    _resultAnim.reset();
  }

  // ── BMI helpers ──
  String get _category {
    final b = _bmi!;
    if (b < 18.5) return 'Berat Kurang';
    if (b < 25.0) return 'Berat Ideal';
    if (b < 30.0) return 'Kelebihan Berat';
    return 'Obesitas';
  }

  Color get _categoryColor {
    final b = _bmi!;
    if (b < 18.5) return const Color(0xFF3B82F6);
    if (b < 25.0) return const Color(0xFF10B981);
    if (b < 30.0) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get _advice {
    final b = _bmi!;
    if (b < 18.5) return 'Tingkatkan asupan kalori dan protein untuk mencapai berat badan ideal.';
    if (b < 25.0) return 'Pastikan asupan kalori sesuai dengan kebutuhan kalori harian & konsumsi makanan sehat.';
    if (b < 30.0) return 'Kurangi asupan kalori dan tingkatkan aktivitas fisik secara rutin.';
    return 'Disarankan berkonsultasi dengan dokter atau ahli gizi untuk program penurunan berat badan.';
  }

  // BMI scale: pointer position 0.0–1.0
  double get _scalePosition {
    final b = _bmi!.clamp(10.0, 40.0);
    return (b - 10.0) / 30.0;
  }

  // ── Widgets ──

  Widget _buildGenderButton(String label, String asset) {
    final isSelected = _gender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isSelected ? _green50 : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? _green700 : _neutral200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: _green700.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))]
                : [],
          ),
          child: Column(
            children: [
              // Avatar placeholder circle
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: isSelected ? _green100 : _neutral100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  label == 'Laki-laki' ? Icons.person_rounded : Icons.person_2_rounded,
                  size: 42,
                  color: isSelected ? _green700 : _neutral400,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? _green700 : _neutral600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberInput(String label, TextEditingController ctrl, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _neutral600)),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: _green100, borderRadius: BorderRadius.circular(6)),
              child: Text(unit, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _green700)),
            ),
            const Text(' *', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _neutral200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              // minus
              _buildCounter(Icons.remove_rounded, () {
                final v = double.tryParse(ctrl.text) ?? 0;
                if (v > 1) ctrl.text = (v - 1).toStringAsFixed(0);
                setState(() {});
              }),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _neutral900),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              // plus
              _buildCounter(Icons.add_rounded, () {
                final v = double.tryParse(ctrl.text) ?? 0;
                ctrl.text = (v + 1).toStringAsFixed(0);
                setState(() {});
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCounter(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 56,
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Icon(icon, color: _green700, size: 22),
      ),
    );
  }

  Widget _buildBmiScale() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final pos = _scalePosition * w;
        return Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // gradient bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 14,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF3B82F6), // underweight
                          Color(0xFF10B981), // normal
                          Color(0xFFF59E0B), // overweight
                          Color(0xFFEF4444), // obese
                        ],
                        stops: [0.0, 0.28, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // pointer
                Positioned(
                  left: pos - 18,
                  top: 18,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _neutral900,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: Text(
                          _bmi!.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                      // triangle
                      CustomPaint(size: const Size(12, 7), painter: _TrianglePainter()),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            // scale labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Kurang', style: TextStyle(fontSize: 10, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
                Text('Ideal', style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                Text('Lebih', style: TextStyle(fontSize: 10, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600)),
                Text('Obesitas', style: TextStyle(fontSize: 10, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        );
      },
    );
  }

  // ── Result Card ──
  Widget _buildResult() {
    return FadeTransition(
      opacity: _resultFade,
      child: SlideTransition(
        position: _resultSlide,
        child: Column(
          children: [
            // Avatar header
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_green50, _neutral50],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    color: _neutral100,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Icon(
                    _gender == 'Laki-laki' ? Icons.person_rounded : Icons.person_2_rounded,
                    size: 56,
                    color: _green700,
                  ),
                ),
              ],
            ),

            // Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  Text('BMI untuk $_gender',
                    style: const TextStyle(fontSize: 13, color: _neutral400, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text(_category,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _categoryColor, letterSpacing: -0.5)),
                  const SizedBox(height: 16),
                  // height & weight row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatChip('Tinggi (cm)', _heightCtrl.text),
                      const SizedBox(width: 24),
                      _buildStatChip('Berat (kg)', _weightCtrl.text),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildBmiScale(),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _green50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _green100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_rounded, color: _green700, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_advice,
                            style: const TextStyle(fontSize: 13, color: _neutral600, height: 1.45)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _reset,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Icon(Icons.refresh_rounded, color: _green700, size: 17),
                        SizedBox(width: 5),
                        Text('Cek Ulang',
                          style: TextStyle(color: _green700, fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _neutral400)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _neutral900, letterSpacing: -0.5)),
      ],
    );
  }

  // ── Main Build ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _neutral50,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _neutral100, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _neutral900),
          ),
        ),
        title: const Text('Cek BMI',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _neutral900, letterSpacing: -0.3)),
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            if (_bmi == null) ...[
              // ── Info Banner ──
              Container(
                margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _neutral200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: _green50, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.info_outline_rounded, color: _green700, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Apa itu BMI?',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _neutral900)),
                          const SizedBox(height: 3),
                          Text('Body Mass Index (BMI) adalah cara menghitung berat badan ideal berdasarkan tinggi dan berat badan.',
                            style: const TextStyle(fontSize: 12, color: _neutral400, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Gender Selector ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildGenderButton('Laki-laki', ''),
                    const SizedBox(width: 12),
                    _buildGenderButton('Perempuan', ''),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Inputs ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildNumberInput('Tinggi Badan', _heightCtrl, 'cm'),
                    const SizedBox(height: 16),
                    _buildNumberInput('Berat Badan', _weightCtrl, 'kg'),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ] else ...[
              const SizedBox(height: 16),
              _buildResult(),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),

      // ── Calculate Button (only when form shown) ──
      bottomNavigationBar: _bmi == null
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _neutral200, width: 1)),
              ),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calculate_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('HITUNG BMI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

// ── Triangle painter for scale pointer ──
class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF111827);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}