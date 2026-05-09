import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'bmi_page.dart';
import 'chat_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  bool _isLogin = false;

  // Theme colors - more professional palette
  static const Color _primaryColor = Color(0xFF059669); // Emerald green
  static const Color _primaryDarkColor = Color(0xFF047857);
  static const Color _primaryLightColor = Color(0xFFD1FAE5);
  static const Color _accentColor = Color(0xFF10B981);
  static const Color _surfaceColor = Color(0xFFF9FAFB);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimaryColor = Color(0xFF111827);
  static const Color _textSecondaryColor = Color(0xFF6B7280);
  static const Color _textTertiaryColor = Color(0xFF9CA3AF);
  static const Color _borderColor = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final status = await AuthService.isLoggedIn();
    if (mounted) {
      setState(() => _isLogin = status);
    }
  }

  void _handleProtectedFeature(VoidCallback action) {
    if (_isLogin) {
      action();
    } else {
      _showLoginWarning();
    }
  }

  void _handleDevelopmentFeature() {
    if (_isLogin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fitur sedang dalam pengembangan'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _showLoginWarning();
    }
  }

  // Perbaikan: Function untuk navigasi ke login
  Future<void> _navigateToLogin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    // Refresh status login setelah kembali dari halaman login
    await _checkLogin();
  }

  void _showLoginWarning() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: _cardColor,
      elevation: 0,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryLightColor, _primaryColor.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(Icons.lock_outline_rounded, color: _primaryColor, size: 32),
            ),
            const SizedBox(height: 20),
            const Text(
              'Akses Perlu Login',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textPrimaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              'Silakan login untuk mengakses fitur ini dan nikmati pengalaman lengkap ObesityCheck',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textSecondaryColor, height: 1.4),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _navigateToLogin();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Login Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Nanti Saja', style: TextStyle(color: _textSecondaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryLightColor, _primaryColor.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: _primaryColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: _textPrimaryColor,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _primaryLightColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _primaryColor),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          color: _textSecondaryColor,
                          fontSize: 13,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.arrow_forward_ios, color: _primaryColor, size: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryColor, _accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.health_and_safety, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'ObesityCheck',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textPrimaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              
              // Login Button or Avatar
              if (!_isLogin)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _primaryColor, width: 1.5),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _navigateToLogin,
                      borderRadius: BorderRadius.circular(30),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.login_rounded, color: _primaryColor, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Login',
                              style: TextStyle(
                                color: _primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor, _accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleDevelopmentFeature(),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: const Icon(Icons.person, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Hero Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _primaryDarkColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'KUIS KESEHATAN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Cek Risiko\nObesitas Anda',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Perhitungan BMI akurat & konsultasi dengan ahli gizi',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const BmiPage()));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Mulai Cek BMI',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/img/gambar_awal.png',
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 180,
                            color: Colors.white.withOpacity(0.1),
                            child: const Icon(Icons.fitness_center, size: 60, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: _cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryLightColor, _primaryColor.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.favorite, color: _primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'ObesityCheck',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimaryColor),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Solusi digital terpercaya untuk memantau kesehatan tubuh dan risiko obesitas masyarakat Indonesia.',
            style: TextStyle(color: _textSecondaryColor, height: 1.5),
          ),
          const SizedBox(height: 24),
          const Divider(color: _borderColor, height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Akses Cepat', style: TextStyle(fontWeight: FontWeight.w700, color: _textPrimaryColor)),
                    const SizedBox(height: 12),
                    _buildFooterLink('Beranda'),
                    _buildFooterLink('Tentang Kami'),
                    _buildFooterLink('Kontak'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Layanan', style: TextStyle(fontWeight: FontWeight.w700, color: _textPrimaryColor)),
                    const SizedBox(height: 12),
                    _buildFooterLink('Cek BMI'),
                    _buildFooterLink('Konsultasi'),
                    _buildFooterLink('Riwayat'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: _borderColor, height: 1),
          const SizedBox(height: 20),
          const Text('Hubungi Kami', style: TextStyle(fontWeight: FontWeight.w700, color: _textPrimaryColor)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.email_outlined, size: 16, color: _textSecondaryColor),
              const SizedBox(width: 8),
              Text('support@obesitycheck.id', style: TextStyle(color: _textSecondaryColor, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSocialIcon(Icons.language_outlined),
              const SizedBox(width: 12),
              _buildSocialIcon(Icons.email_outlined),
              const SizedBox(width: 12),
              _buildSocialIcon(Icons.phone_outlined),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '© 2024 ObesityCheck. All rights reserved.',
              style: TextStyle(color: _textTertiaryColor, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: TextStyle(color: _textSecondaryColor, fontSize: 13)),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Icon(icon, size: 18, color: _textSecondaryColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Layanan Kami',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimaryColor),
                        ),
                        const SizedBox(height: 16),
                        _buildServiceCard(
                          icon: Icons.monitor_weight_rounded,
                          title: 'Cek BMI',
                          description: 'Hitung indeks massa tubuh secara presisi berdasarkan berat, tinggi, dan usia.',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BmiPage())),
                          badge: 'GRATIS',
                        ),
                        _buildServiceCard(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'SiObe Assistant',
                          description: 'Chat interaktif dengan asisten kesehatan virtual 24/7 untuk konsultasi cepat.',
                          onTap: () => _handleProtectedFeature(() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatPage()))),
                          badge: 'NEW',
                        ),
                        _buildServiceCard(
                          icon: Icons.favorite_rounded,
                          title: 'Konsultasi Ahli',
                          description: 'Dapatkan rekomendasi kesehatan dan nutrisi dari ahli gizi terpercaya.',
                          onTap: () => _handleDevelopmentFeature(),
                        ),
                        _buildServiceCard(
                          icon: Icons.history_rounded,
                          title: 'Riwayat BMI',
                          description: 'Pantau progres kesehatan dengan grafik riwayat yang mudah dipahami.',
                          onTap: () => _handleDevelopmentFeature(),
                        ),
                      ],
                    ),
                  ),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: _primaryColor,
          unselectedItemColor: _textSecondaryColor,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: _cardColor,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          onTap: (index) {
            setState(() => _currentIndex = index);

            switch (index) {
              case 0:
                break;
              case 1:
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BmiPage()));
                break;
                case 2:
                  _handleDevelopmentFeature();
                  break;
                case 3:
                  _handleProtectedFeature(() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatPage())));
                  break;
                case 4:
                  _handleDevelopmentFeature();
                  break;
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.monitor_weight_outlined), activeIcon: Icon(Icons.monitor_weight_rounded), label: 'Cek BMI'),
            BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history_rounded), label: 'Riwayat'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'SiObe'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}