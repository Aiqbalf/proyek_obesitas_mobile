import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with TickerProviderStateMixin {
  // ── Palette (sama dengan login_page) ──
  static const Color _green900  = Color(0xFF064E3B);
  static const Color _green700  = Color(0xFF047857);
  static const Color _green500  = Color(0xFF10B981);
  static const Color _green100  = Color(0xFFD1FAE5);
  static const Color _green50   = Color(0xFFF0FDF4);
  static const Color _neutral50  = Color(0xFFF9FAFB);
  static const Color _neutral200 = Color(0xFFE5E7EB);
  static const Color _neutral300 = Color(0xFFD1D5DB);
  static const Color _neutral400 = Color(0xFF9CA3AF);
  static const Color _neutral600 = Color(0xFF4B5563);
  static const Color _neutral900 = Color(0xFF111827);

  // ── State ──
  int _step = 0; // 0 = email, 1 = new password, 2 = success
  bool _isLoading = false;
  bool _obscurePass  = true;
  bool _obscurePass2 = true;

  final _emailCtrl     = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  final _formKeyEmail  = GlobalKey<FormState>();
  final _formKeyPass   = GlobalKey<FormState>();

  // ── Animations ──
  late AnimationController _pageAnim;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  late AnimationController _stepAnim;
  late Animation<double>   _stepFade;
  late Animation<Offset>   _stepSlide;

  late AnimationController _successAnim;
  late Animation<double>   _successScale;
  late Animation<double>   _successFade;

  @override
  void initState() {
    super.initState();

    // Page enter animation
    _pageAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut));
    _pageAnim.forward();

    // Step transition animation
    _stepAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _stepFade = CurvedAnimation(parent: _stepAnim, curve: Curves.easeOut);
    _stepSlide = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _stepAnim, curve: Curves.easeOut));
    _stepAnim.forward();

    // Success animation
    _successAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _successScale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _successAnim, curve: Curves.elasticOut));
    _successFade = CurvedAnimation(parent: _successAnim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pageAnim.dispose();
    _stepAnim.dispose();
    _successAnim.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Transition ke step berikutnya ──
  void _goToStep(int step) {
    _stepAnim.reset();
    setState(() => _step = step);
    _stepAnim.forward();
    if (step == 2) _successAnim.forward();
  }

  // ── Step 0: Verifikasi email ──
  Future<void> _handleVerifyEmail() async {
    if (!_formKeyEmail.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final result = await ApiService.checkEmail(_emailCtrl.text.trim());

    setState(() => _isLoading = false);

    if (result['status'] == 200) {
      _goToStep(1);
    } else {
      _showSnack(result['data']['message'] ?? 'Email tidak ditemukan.', isError: true);
    }
  }

  // ── Step 1: Reset password ──
  Future<void> _handleResetPassword() async {
    if (!_formKeyPass.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final result = await ApiService.resetPassword(
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result['status'] == 200) {
      _goToStep(2);
    } else {
      _showSnack(result['data']['message'] ?? 'Gagal mereset password.', isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: isError ? const Color(0xFFEF4444) : _green700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
  }

  // ── Input field builder ──
  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool? showObscure,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _neutral600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, color: _neutral900),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _neutral300, fontSize: 14),
            prefixIcon: Icon(icon, color: _neutral400, size: 20),
            suffixIcon: onToggleObscure != null
                ? GestureDetector(
                    onTap: onToggleObscure,
                    child: Icon(
                      showObscure!
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: _neutral400,
                      size: 20,
                    ),
                  )
                : null,
            filled: true,
            fillColor: _neutral50,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _neutral200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _neutral200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _green700, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step indicator ──
  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (i) {
        final isActive   = i == _step || (i == 1 && _step == 2);
        final isComplete = (_step == 1 && i == 0) || _step == 2;
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isActive ? 32 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: isComplete
                    ? _green500
                    : isActive
                        ? _green700
                        : _neutral200,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            if (i < 1)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: isComplete ? _green500 : _neutral200,
              ),
          ],
        );
      }),
    );
  }

  // ── STEP 0: Email form ──
  Widget _buildEmailStep() {
    return Form(
      key: _formKeyEmail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _green50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _green100, width: 1.5),
            ),
            child: const Icon(Icons.mark_email_unread_rounded,
                color: _green700, size: 28),
          ),
          const SizedBox(height: 20),

          const Text('Lupa Password?',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _neutral900,
                  letterSpacing: -0.4)),
          const SizedBox(height: 6),
          const Text(
            'Masukkan email yang terdaftar.\nKami akan memverifikasi akunmu.',
            style: TextStyle(fontSize: 13, color: _neutral400, height: 1.5),
          ),
          const SizedBox(height: 28),

          _buildField(
            ctrl: _emailCtrl,
            label: 'Alamat Email',
            hint: 'contoh@email.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return 'Email tidak boleh kosong';
              final re = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!re.hasMatch(v.trim())) return 'Format email tidak valid';
              return null;
            },
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleVerifyEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _green100,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Verifikasi Email',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2)),
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP 1: New password form ──
  Widget _buildNewPasswordStep() {
    return Form(
      key: _formKeyPass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _green50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _green100, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: _green500, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _emailCtrl.text,
                    style: const TextStyle(
                        fontSize: 13,
                        color: _green700,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _green50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _green100, width: 1.5),
            ),
            child: const Icon(Icons.lock_reset_rounded,
                color: _green700, size: 28),
          ),
          const SizedBox(height: 20),

          const Text('Buat Password Baru',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _neutral900,
                  letterSpacing: -0.4)),
          const SizedBox(height: 6),
          const Text(
            'Pastikan password baru mudah diingat\nnamun sulit ditebak.',
            style: TextStyle(fontSize: 13, color: _neutral400, height: 1.5),
          ),
          const SizedBox(height: 28),

          _buildField(
            ctrl: _passCtrl,
            label: 'Password Baru',
            hint: 'Minimal 6 karakter',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePass,
            showObscure: _obscurePass,
            onToggleObscure: () =>
                setState(() => _obscurePass = !_obscurePass),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password tidak boleh kosong';
              if (v.length < 6) return 'Password minimal 6 karakter';
              return null;
            },
          ),
          const SizedBox(height: 16),

          _buildField(
            ctrl: _confirmCtrl,
            label: 'Konfirmasi Password',
            hint: 'Ulangi password baru',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePass2,
            showObscure: _obscurePass2,
            onToggleObscure: () =>
                setState(() => _obscurePass2 = !_obscurePass2),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
              if (v != _passCtrl.text) return 'Password tidak cocok';
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Password strength indicator
          _buildPasswordStrength(_passCtrl.text),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleResetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green700,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _green100,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Simpan Password Baru',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Password strength indicator ──
  Widget _buildPasswordStrength(String pass) {
    int strength = 0;
    if (pass.length >= 6) strength++;
    if (pass.length >= 10) strength++;
    if (pass.contains(RegExp(r'[A-Z]'))) strength++;
    if (pass.contains(RegExp(r'[0-9]'))) strength++;
    if (pass.contains(RegExp(r'[!@#$%^&*]'))) strength++;

    final labels  = ['', 'Lemah', 'Cukup', 'Baik', 'Kuat', 'Sangat Kuat'];
    final colors  = [
      _neutral200,
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFF84CC16),
      _green500,
      _green700,
    ];

    if (pass.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) => Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
              decoration: BoxDecoration(
                color: i < strength ? colors[strength] : _neutral200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          )),
        ),
        const SizedBox(height: 6),
        Text(
          'Kekuatan: ${strength > 0 ? labels[strength] : ""}',
          style: TextStyle(
              fontSize: 12,
              color: strength > 0 ? colors[strength] : _neutral400,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ── STEP 2: Success ──
  Widget _buildSuccessStep() {
    return FadeTransition(
      opacity: _successFade,
      child: Column(
        children: [
          const SizedBox(height: 16),
          ScaleTransition(
            scale: _successScale,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_green500, _green700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: _green500.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 52),
            ),
          ),
          const SizedBox(height: 28),

          const Text('Password Berhasil Diubah!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _neutral900,
                  letterSpacing: -0.3)),
          const SizedBox(height: 10),
          const Text(
            'Password akunmu telah berhasil diperbarui.\nSilakan masuk dengan password baru.',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: _neutral400, height: 1.6),
          ),
          const SizedBox(height: 36),

          // Decorative dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) => Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i == 1 ? _green500 : _green100,
                shape: BoxShape.circle,
              ),
            )),
          ),
          const SizedBox(height: 36),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Masuk Sekarang',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _neutral50,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottom),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [

            // ── Header ──
            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                      24, MediaQuery.of(context).padding.top + 24, 24, 36),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_green700, _green900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(36)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () {
                          if (_step > 0 && _step < 2) {
                            _goToStep(_step - 1);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Header text
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                  width: 1.5),
                            ),
                            child: const Icon(Icons.health_and_safety_rounded,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ObesityCheck',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.3)),
                              Text('Pemulihan Akun',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.65))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Step indicator (hanya tampil saat step 0 & 1)
                      if (_step < 2) _buildStepIndicator(),
                    ],
                  ),
                ),
              ),
            ),

            // ── Content ──
            FadeTransition(
              opacity: _stepFade,
              child: SlideTransition(
                position: _stepSlide,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: child,
                    ),
                    child: _step == 0
                        ? _buildEmailStep()
                        : _step == 1
                            ? _buildNewPasswordStep()
                            : _buildSuccessStep(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}