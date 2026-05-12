import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  static const _green900   = Color(0xFF064E3B);
  static const _green700   = Color(0xFF047857);
  static const _green500   = Color(0xFF10B981);
  static const _green100   = Color(0xFFD1FAE5);
  static const _green50    = Color(0xFFF0FDF4);
  static const _neutral50  = Color(0xFFF9FAFB);
  static const _neutral100 = Color(0xFFF3F4F6);
  static const _neutral200 = Color(0xFFE5E7EB);
  static const _neutral400 = Color(0xFF9CA3AF);
  static const _neutral600 = Color(0xFF4B5563);
  static const _neutral900 = Color(0xFF111827);

  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _loadUser();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final data = await AuthService.getUser();
    if (mounted) {
      setState(() {
        _userData  = data;
        _isLoading = false;
      });
      _animCtrl.forward();
    }
  }

  // ══════════════════════════════════════════════
  // FIX UTAMA: logout TIDAK push LoginPage langsung.
  // Cukup logout + pop kembali ke DashboardPage.
  // DashboardPage akan _checkLogin() dan tampilkan
  // tombol "Login" di beranda — tidak paksa ke LoginPage.
  // ══════════════════════════════════════════════
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar Akun',
            style: TextStyle(fontWeight: FontWeight.w800, color: _neutral900)),
        content: const Text(
            'Apakah Anda yakin ingin keluar dari akun ini?',
            style: TextStyle(color: _neutral600, height: 1.5)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal',
                  style: TextStyle(color: _neutral400))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout(); // hapus token + SharedPreferences
      if (mounted) {
        // 🔥 FIX: pop saja — DashboardPage._navigateToProfile()
        //         akan memanggil _checkLogin() setelah ini,
        //         sehingga tombol avatar berubah jadi "Login"
        //         tanpa memaksa user ke halaman LoginPage.
        Navigator.of(context).pop();
      }
    }
  }

  void _snackDev() => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Fitur sedang dalam pengembangan'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _neutral900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ));

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  String _memberSince(String? createdAt) {
    if (createdAt == null) return '-';
    try {
      final dt = DateTime.parse(createdAt);
      const months = [
        'Jan','Feb','Mar','Apr','Mei','Jun',
        'Jul','Agu','Sep','Okt','Nov','Des'
      ];
      return 'Bergabung ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return createdAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _neutral50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _green700))
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildInfoCards(),
                          const SizedBox(height: 24),
                          _buildMenuSection(),
                          const SizedBox(height: 24),
                          _buildLogoutButton(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAppBar() {
    final name   = _userData?['name']       as String? ?? 'Pengguna';
    final email  = _userData?['email']      as String? ?? '';
    final avatar = _userData?['avatar']     as String?;
    final since  = _memberSince(_userData?['created_at'] as String?);

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: _green700,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 14, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context), // kembali ke Dashboard
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
          ),
          onPressed: _snackDev,
          tooltip: 'Edit Profil',
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_green500, _green900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(top: -40, right: -40,
                child: _decorCircle(180, Colors.white.withOpacity(0.05))),
            Positioned(top: 60, right: 30,
                child: _decorCircle(80, Colors.white.withOpacity(0.06))),
            Positioned(bottom: 40, left: -30,
                child: _decorCircle(120, Colors.white.withOpacity(0.05))),
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.6), width: 2.5)),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: _green100,
                      backgroundImage:
                          (avatar != null && avatar.isNotEmpty)
                              ? NetworkImage(avatar)
                              : null,
                      child: (avatar == null || avatar.isEmpty)
                          ? Text(_initials(name),
                              style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: _green900))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(name,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4)),
                  const SizedBox(height: 4),
                  Text(email,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.75))),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(since,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorCircle(double size, Color color) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color));

  Widget _buildInfoCards() {
    final phone  = _userData?['phone']  as String? ?? '-';
    final gender = _userData?['gender'] as String?;
    final genderText = gender == 'male'   || gender == 'Laki-laki'
        ? 'Laki-laki'
        : gender == 'female' || gender == 'Perempuan'
            ? 'Perempuan'
            : gender ?? '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Informasi Akun'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _neutral200),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              children: [
                _infoRow(Icons.person_outline_rounded,
                    'Nama Lengkap', _userData?['name'] ?? '-'),
                _divider(),
                _infoRow(Icons.email_outlined,
                    'Email', _userData?['email'] ?? '-'),
                _divider(),
                _infoRow(Icons.phone_outlined, 'Nomor Telepon', phone),
                _divider(),
                _infoRow(
                    gender == 'female' || gender == 'Perempuan'
                        ? Icons.female_rounded
                        : Icons.male_rounded,
                    'Jenis Kelamin', genderText),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  color: _green50, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: _green700, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11,
                          color: _neutral400,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _neutral900)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _divider() => Divider(
      height: 1, thickness: 1, color: _neutral100, indent: 16, endIndent: 16);

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Pengaturan & Lainnya'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _neutral200),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              children: [
                _menuRow(Icons.edit_note_rounded, 'Edit Profil',
                    'Perbarui data pribadi Anda', _green700, _snackDev),
                _divider(),
                _menuRow(Icons.lock_outline_rounded, 'Ubah Password',
                    'Ganti kata sandi akun',
                    const Color(0xFF6366F1), _snackDev),
                _divider(),
                _menuRow(Icons.notifications_none_rounded, 'Notifikasi',
                    'Atur preferensi notifikasi',
                    const Color(0xFFF59E0B), _snackDev),
                _divider(),
                _menuRow(Icons.help_outline_rounded, 'Bantuan & FAQ',
                    'Pusat bantuan dan pertanyaan umum',
                    const Color(0xFF3B82F6), _snackDev),
                _divider(),
                _menuRow(Icons.privacy_tip_outlined, 'Kebijakan Privasi',
                    'Baca kebijakan privasi kami', _neutral600, _snackDev),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuRow(IconData icon, String title, String subtitle,
      Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _neutral900)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11,
                          color: _neutral400,
                          fontWeight: FontWeight.w400)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: _neutral400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Keluar dari Akun',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4B5563),
          letterSpacing: 0.2));
}