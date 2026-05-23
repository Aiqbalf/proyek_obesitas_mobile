import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'login_page.dart';
import 'bmi_page.dart';
import 'chat_page.dart';
import 'obesity_predict_page.dart';
import 'profile_page.dart';
import 'article_page.dart';

// ─────────────────────────────────────────────
//  SHELL — satu Scaffold, bottom nav selalu ada
// ─────────────────────────────────────────────
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  int  _currentIndex = 0;
  bool _isLogin      = false;

  static const Color _green700   = Color(0xFF047857);
  static const Color _green100   = Color(0xFFD1FAE5);
  static const Color _neutral200 = Color(0xFFE5E7EB);
  static const Color _neutral400 = Color(0xFF9CA3AF);
  static const Color _neutral900 = Color(0xFF111827);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLogin();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkLogin();
  }

  Future<void> _checkLogin() async {
    bool status = await ApiService.isLoggedIn();
    if (status) {
      // Verifikasi token ke server
      final user = await ApiService.getUser();
      if (user == null) {
        // Token tidak valid atau expired
        await ApiService.logout();
        status = false;
      }
    }
    if (mounted) setState(() => _isLogin = status);
  }

  Future<void> _navigateToLogin() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const LoginPage()));
    await _checkLogin();
  }

  Future<void> _navigateToProfile() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ProfilePage()));
    await _checkLogin();
  }

  void _switchTab(int index) {
    const protectedTabs = {2, 3};
    if (protectedTabs.contains(index) && !_isLogin) {
      _showLoginSheet();
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  }

  void _showLoginSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: _neutral200,
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 28),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                shape: BoxShape.circle,
                border: Border.all(color: _green100, width: 2),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: _green700, size: 34),
            ),
            const SizedBox(height: 20),
            const Text('Login Diperlukan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  color: _neutral900, letterSpacing: -0.3)),
            const SizedBox(height: 8),
            const Text('Silakan login untuk mengakses fitur ini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _neutral400, height: 1.5)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _navigateToLogin();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Login Sekarang',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nanti Saja',
                  style: TextStyle(color: _neutral400, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(
            key                : ValueKey(_isLogin),
            isLogin            : _isLogin,
            onNavigateToLogin  : _navigateToLogin,
            onNavigateToProfile: _navigateToProfile,
            onSwitchTab        : _switchTab,
          ),
          const BmiPage(embedded: true),
          ChatPage(embedded: true),
          ObesityPredictPage(embedded: true),
          const ArticlePage(embedded: true),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _neutral200, width: 1)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _navItem(0, Icons.home_rounded,           Icons.home_outlined,           'Beranda'),
                _navItem(1, Icons.monitor_weight_rounded, Icons.monitor_weight_outlined, 'BMI'),
                _navItem(2, Icons.chat_bubble_rounded,    Icons.chat_bubble_outline,     'SiObe'),
                _navItem(3, Icons.psychology_rounded,     Icons.psychology_outlined,     'Prediksi'),
                _navItem(4, Icons.article_rounded,        Icons.article_outlined,        'Artikel'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData activeIcon, IconData inactiveIcon,
      String label) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? _green100 : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? activeIcon : inactiveIcon,
                color: isActive ? _green700 : _neutral400,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? _green700 : _neutral400,
              )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TAB 0 — Beranda
// ─────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final bool isLogin;
  final Future<void> Function() onNavigateToLogin;
  final Future<void> Function() onNavigateToProfile;
  final void Function(int) onSwitchTab;

  const _HomeTab({
    required Key key,
    required this.isLogin,
    required this.onNavigateToLogin,
    required this.onNavigateToProfile,
    required this.onSwitchTab,
  }) : super(key: key);

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab>
    with SingleTickerProviderStateMixin {
  static const Color _green900   = Color(0xFF064E3B);
  static const Color _green700   = Color(0xFF047857);
  static const Color _green500   = Color(0xFF10B981);
  static const Color _green100   = Color(0xFFD1FAE5);
  static const Color _green50    = Color(0xFFF0FDF4);
  static const Color _neutral50  = Color(0xFFF9FAFB);
  static const Color _neutral100 = Color(0xFFF3F4F6);
  static const Color _neutral200 = Color(0xFFE5E7EB);
  static const Color _neutral400 = Color(0xFF9CA3AF);
  static const Color _neutral600 = Color(0xFF4B5563);
  static const Color _neutral900 = Color(0xFF111827);

  late AnimationController _anim;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ── Top bar ──
  Widget _topBar() => Padding(
    padding: EdgeInsets.fromLTRB(
        16, MediaQuery.of(context).padding.top + 12, 16, 0),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_green500, _green700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.health_and_safety_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Text('ObesityCheck',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
              color: _neutral900, letterSpacing: -0.4)),
        const Spacer(),
        if (!widget.isLogin)
          GestureDetector(
            onTap: widget.onNavigateToLogin,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                  color: _green700,
                  borderRadius: BorderRadius.circular(24)),
              child: const Text('Login',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          )
        else
          GestureDetector(
            onTap: widget.onNavigateToProfile,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _green50, shape: BoxShape.circle,
                border: Border.all(color: _green100, width: 1.5),
              ),
              child: const Icon(Icons.person_rounded,
                  color: _green700, size: 22),
            ),
          ),
      ],
    ),
  );

  // ── Hero banner ──
  Widget _hero() => FadeTransition(
    opacity: _fade,
    child: SlideTransition(
      position: _slide,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_green700, _green900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: _green700.withOpacity(0.35),
                blurRadius: 24, offset: const Offset(0, 10))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('KUIS KESEHATAN',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: Colors.white, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 14),
                  const Text('Cek Risiko\nObesitas',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900,
                        color: Colors.white, height: 1.15, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Text('BMI akurat & konsultasi ahli gizi',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75), fontSize: 13)),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => widget.onSwitchTab(3), // ← mengarah ke ObesityPredictPage
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Mulai Cek',
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w700, color: _green700)),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded,
                              size: 16, color: _green700),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/img/gambar_awal.png',
                width: 110, height: 160, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 110, height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.fitness_center,
                      size: 48, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // ── Stats row ──
  Widget _stats() {
    final items = [
      ('10K+', 'Pengguna'),
      ('98%',  'Akurasi'),
      ('24/7', 'Support'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: isLast ? 0 : 10),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _neutral200),
              ),
              child: Column(children: [
                Text(e.value.$1,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                      color: _green700, letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text(e.value.$2,
                  style: const TextStyle(fontSize: 11, color: _neutral400,
                      fontWeight: FontWeight.w500)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Service card ──
  Widget _card({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _neutral200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03),
                blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                  color: _green50, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: _green700, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(title,
                      style: const TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w700, color: _neutral900)),
                    if (badge != null) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor ?? _green100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(badge,
                          style: TextStyle(fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: badgeColor != null
                                  ? Colors.white
                                  : _green700,
                              letterSpacing: 0.3)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text(desc,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12,
                        color: _neutral400, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  color: _neutral100,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: _neutral600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: _neutral50,
            child: Column(children: [
              _topBar(),
              const SizedBox(height: 20),
              _hero(),
              const SizedBox(height: 20),
              _stats(),
              const SizedBox(height: 28),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text('Layanan Kami',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                  color: _neutral900, letterSpacing: -0.2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              _card(
                icon: Icons.monitor_weight_rounded,
                title: 'Cek BMI',
                desc: 'Hitung indeks massa tubuh berdasarkan berat '
                    'dan tinggi badan secara presisi.',
                onTap: () => widget.onSwitchTab(1),
                badge: 'GRATIS',
              ),
              _card(
                icon: Icons.chat_bubble_rounded,
                title: 'SiObe Assistant',
                desc: 'Chat dengan asisten kesehatan virtual 24/7 '
                    'untuk konsultasi cepat.',
                onTap: () => widget.onSwitchTab(2),
                badge: 'NEW',
                badgeColor: const Color(0xFF6366F1),
              ),
              _card(
                icon: Icons.psychology_rounded,
                title: 'Prediksi Obesitas',
                desc: 'Prediksi kategori obesitas dengan AI '
                    'berdasarkan data fisik dan gaya hidup.',
                onTap: () => widget.onSwitchTab(3),
                badge: 'AI',
                badgeColor: const Color(0xFFEC4899),
              ),
              _card(
                icon: Icons.article_rounded,
                title: 'Baca Artikel',
                desc: 'Temukan artikel kesehatan, tips nutrisi, '
                    'dan gaya hidup sehat terpercaya.',
                onTap: () => widget.onSwitchTab(4),
                badge: 'INFO',
                badgeColor: const Color(0xFFF59E0B),
              ),
            ]),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}