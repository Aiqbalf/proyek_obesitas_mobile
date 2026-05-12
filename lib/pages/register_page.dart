import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  // ── Palette ──
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

  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _isLoading      = false;
  bool _agreeTerms     = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      _showSnack('Harap setujui syarat dan ketentuan terlebih dahulu.', isError: true);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final result = await ApiService.register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    setState(() => _isLoading = false);

    if (result['status'] == 200) {
      _showSnack('Registrasi berhasil! Silakan login.', isError: false);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);
    } else {
      _showSnack(result['data']['message'] ?? 'Registrasi gagal.', isError: true);
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

  // ── Input field ──
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
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _neutral600)),
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
                      showObscure! ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: _neutral400, size: 20,
                    ),
                  )
                : null,
            filled: true,
            fillColor: _neutral50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _neutral50,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottom),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Top gradient header ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_green700, _green900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logo
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),

                  const Text('Buat Akun Baru',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  Text('Daftar dan mulai pantau kesehatanmu',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.75))),
                ],
              ),
            ),

            // ── Form card ──
            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Nama ──
                        _buildField(
                          ctrl: _nameCtrl,
                          label: 'Nama Lengkap',
                          hint: 'Masukkan nama lengkap',
                          icon: Icons.person_outline_rounded,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Nama tidak boleh kosong';
                            if (v.trim().length < 3) return 'Nama minimal 3 karakter';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── Email ──
                        _buildField(
                          ctrl: _emailCtrl,
                          label: 'Email',
                          hint: 'contoh@email.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email tidak boleh kosong';
                            final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(v.trim())) return 'Format email tidak valid';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── Password ──
                        _buildField(
                          ctrl: _passCtrl,
                          label: 'Password',
                          hint: 'Minimal 8 karakter',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscurePass,
                          showObscure: _obscurePass,
                          onToggleObscure: () => setState(() => _obscurePass = !_obscurePass),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password tidak boleh kosong';
                            if (v.length < 8) return 'Password minimal 8 karakter';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── Konfirmasi Password ──
                        _buildField(
                          ctrl: _confirmCtrl,
                          label: 'Konfirmasi Password',
                          hint: 'Ulangi password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscureConfirm,
                          showObscure: _obscureConfirm,
                          onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Konfirmasi password tidak boleh kosong';
                            if (v != _passCtrl.text) return 'Password tidak cocok';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // ── Syarat & Ketentuan ──
                        GestureDetector(
                          onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22, height: 22,
                                decoration: BoxDecoration(
                                  color: _agreeTerms ? _green700 : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _agreeTerms ? _green700 : _neutral300,
                                    width: 1.5,
                                  ),
                                ),
                                child: _agreeTerms
                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 13, color: _neutral600, height: 1.4),
                                    children: [
                                      const TextSpan(text: 'Saya menyetujui '),
                                      TextSpan(text: 'Syarat & Ketentuan',
                                        style: const TextStyle(color: _green700, fontWeight: FontWeight.w600)),
                                      const TextSpan(text: ' dan '),
                                      TextSpan(text: 'Kebijakan Privasi',
                                        style: const TextStyle(color: _green700, fontWeight: FontWeight.w600)),
                                      const TextSpan(text: ' ObesityCheck.'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Tombol Daftar ──
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _green700,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: _green100,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                  )
                                : const Text('Daftar Sekarang',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Sudah punya akun ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Sudah punya akun? ',
                              style: TextStyle(fontSize: 13, color: _neutral400)),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text('Login',
                                style: TextStyle(fontSize: 13, color: _green700,
                                    fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
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