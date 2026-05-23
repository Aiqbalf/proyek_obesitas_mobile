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

  // ── Palette ──
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
    _resultAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _resultFade =
        CurvedAnimation(parent: _resultAnim, curve: Curves.easeOut);
    _resultSlide =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
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

  // BMI scale: pointer position 0.0–1.0
  double get _scalePosition {
    final b = _bmi!.clamp(10.0, 40.0);
    return (b - 10.0) / 30.0;
  }

  // ── Widgets ──

  Widget _buildGenderButton(String label) {
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
                ? [
                    BoxShadow(
                        color: _green700.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isSelected ? _green100 : _neutral100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  label == 'Laki-laki'
                      ? Icons.person_rounded
                      : Icons.person_2_rounded,
                  size: 42,
                  color: isSelected ? _green700 : _neutral400,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? _green700 : _neutral600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberInput(
      String label, TextEditingController ctrl, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _neutral600)),
            const SizedBox(width: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                  color: _green100,
                  borderRadius: BorderRadius.circular(6)),
              child: Text(unit,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _green700)),
            ),
            const Text(' *',
                style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _neutral200),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              _buildCounter(Icons.remove_rounded, () {
                final v = double.tryParse(ctrl.text) ?? 0;
                if (v > 1) ctrl.text = (v - 1).toStringAsFixed(0);
                setState(() {});
              }),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                  ],
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _neutral900),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
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
        width: 44,
        height: 56,
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Icon(icon, color: _green700, size: 22),
      ),
    );
  }

  // ── Result Card ──
  Widget _buildResult() {
    return FadeTransition(
      opacity: _resultFade,
      child: SlideTransition(
        position: _resultSlide,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: _green700.withOpacity(0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // ── Label ──
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _green50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _green100, width: 1.5),
                  ),
                  child: Text(
                    'Hasil BMI · $_gender',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _green700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── BMI Circle ──
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Soft glow
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _categoryColor.withOpacity(0.12),
                            _categoryColor.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                    // Outer ring
                    Container(
                      width: 136,
                      height: 136,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _categoryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    // Inner circle
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _categoryColor.withOpacity(0.08),
                        border: Border.all(
                          color: _categoryColor.withOpacity(0.35),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _bmi!.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: _categoryColor,
                              letterSpacing: -1,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'BMI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _categoryColor.withOpacity(0.7),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Divider ──
                Divider(color: _neutral200, height: 1),

                const SizedBox(height: 20),

                // ── Cek Ulang ──
                GestureDetector(
                  onTap: _reset,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _green50,
                          shape: BoxShape.circle,
                          border: Border.all(color: _green100),
                        ),
                        child: const Icon(Icons.refresh_rounded,
                            color: _green700, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Cek Ulang',
                        style: TextStyle(
                          color: _green700,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Main Build ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _neutral50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.embedded
            ? null
            : GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: _neutral100,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: _neutral900),
                ),
              ),
        title: const Text(
          'Cek BMI',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _neutral900,
              letterSpacing: -0.3),
        ),
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
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: _green50,
                          borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.info_outline_rounded,
                          color: _green700, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Apa itu BMI?',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _neutral900),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Body Mass Index (BMI) adalah cara menghitung berat badan ideal berdasarkan tinggi dan berat badan.',
                            style: TextStyle(
                                fontSize: 12,
                                color: _neutral400,
                                height: 1.4),
                          ),
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
                    _buildGenderButton('Laki-laki'),
                    const SizedBox(width: 12),
                    _buildGenderButton('Perempuan'),
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

      // ── Calculate Button ──
      bottomNavigationBar: _bmi == null
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border(top: BorderSide(color: _neutral200, width: 1)),
              ),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _calculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calculate_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('HITUNG BMI',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}