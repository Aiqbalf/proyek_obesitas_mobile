import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'dashboard_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
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

  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _formKey   = GlobalKey<FormState>();

  bool _obscurePass = true;
  bool _isLoading   = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Login handler ──
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final result = await AuthService.login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSnack('Selamat datang kembali! 👋', isError: false);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
        (route) => false,
      );
    } else {
      _showSnack(result['message'] ?? 'Email atau password salah.', isError: true);
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

            // ── Hero header ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).padding.top + 48, 24, 48),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_green700, _green900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App icon
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25), width: 1.5),
                    ),
                    child: const Icon(Icons.health_and_safety_rounded,
                        color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),

                  const Text('ObesityCheck',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  Text('Pantau kesehatanmu setiap hari',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.72))),

                  const SizedBox(height: 32),

                  // Stats pill row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _statPill('10K+', 'Pengguna'),
                      Container(
                          width: 1,
                          height: 28,
                          color: Colors.white.withOpacity(0.25),
                          margin:
                              const EdgeInsets.symmetric(horizontal: 20)),
                      _statPill('98%', 'Akurasi'),
                      Container(
                          width: 1,
                          height: 28,
                          color: Colors.white.withOpacity(0.25),
                          margin:
                              const EdgeInsets.symmetric(horizontal: 20)),
                      _statPill('24/7', 'Support'),
                    ],
                  ),
                ],
              ),
            ),

            // ── Form ──
            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Text('Masuk ke Akun',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: _neutral900,
                                letterSpacing: -0.3)),
                        const SizedBox(height: 4),
                        const Text('Selamat datang kembali 👋',
                            style: TextStyle(
                                fontSize: 13, color: _neutral400)),
                        const SizedBox(height: 24),

                        // Email
                        _buildField(
                          ctrl: _emailCtrl,
                          label: 'Email',
                          hint: 'contoh@email.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Email tidak boleh kosong';
                            final re = RegExp(
                                r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!re.hasMatch(v.trim()))
                              return 'Format email tidak valid';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password
                        _buildField(
                          ctrl: _passCtrl,
                          label: 'Password',
                          hint: 'Masukkan password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscurePass,
                          showObscure: _obscurePass,
                          onToggleObscure: () =>
                              setState(() => _obscurePass = !_obscurePass),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Password tidak boleh kosong';
                            if (v.length < 6)
                              return 'Password minimal 6 karakter';
                            return null;
                          },
                        ),

                        // Lupa password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8)),
                            child: const Text('Lupa Password?',
                                style: TextStyle(
                                    color: _green700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Tombol Login
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
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
                                        strokeWidth: 2.5,
                                        color: Colors.white),
                                  )
                                : const Text('Masuk',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2)),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Divider
                        Row(children: [
                          const Expanded(
                              child: Divider(color: _neutral200)),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14),
                            child: Text('atau',
                                style: TextStyle(
                                    fontSize: 12, color: _neutral400)),
                          ),
                          const Expanded(
                              child: Divider(color: _neutral200)),
                        ]),

                        const SizedBox(height: 20),

                        // Tombol Daftar
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterPage()),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _green700,
                              side: const BorderSide(
                                  color: _green700, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Buat Akun Baru',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Footer
                        Center(
                          child: Text(
                            '© 2024 ObesityCheck',
                            style: TextStyle(
                                fontSize: 11, color: _neutral300),
                          ),
                        ),

                        const SizedBox(height: 12),
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

  Widget _statPill(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.3)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.65),
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}