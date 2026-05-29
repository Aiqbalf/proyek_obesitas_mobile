import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

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
  static const _indigo600  = Color(0xFF4338CA);
  static const _indigoBg   = Color(0xFFE0E7FF);

  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _predictionHistory = [];
  bool _isLoading        = true;
  bool _isLoadingHistory = false;
  bool _notifEnabled     = false; // ✅ state notifikasi

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

  // ══════════════════════════════════════════════
  // LOAD DATA
  // ══════════════════════════════════════════════
  Future<void> _loadUser() async {
    final data    = await ApiService.getUser();
    final notifOn = await NotificationService.isEnabled(); // ✅ baca preferensi
    if (mounted) {
      setState(() {
        _userData     = data;
        _notifEnabled = notifOn; // ✅ set state
        _isLoading    = false;
      });
      _animCtrl.forward();
      _loadPredictionHistory();
    }
  }

  Future<void> _loadPredictionHistory() async {
    final userId = _userData?['id']?.toString() ?? '';
    final result = await ApiService.getPredictionHistory(userId);
    if (!mounted) return;
    setState(() {
      final responseData = result['data'] as Map<String, dynamic>?;
      final historyList  = responseData?['data'] as List<dynamic>? ?? [];
      _predictionHistory = List<Map<String, dynamic>>.from(historyList);
      _isLoadingHistory  = false;
    });
  }

  // ══════════════════════════════════════════════
  // LOGOUT
  // ══════════════════════════════════════════════
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar Akun',
            style: TextStyle(fontWeight: FontWeight.w800, color: _neutral900)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?',
            style: TextStyle(color: _neutral600, height: 1.5)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal', style: TextStyle(color: _neutral400))),
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
      await ApiService.logout();
      if (mounted) Navigator.of(context).pop();
    }
  }

  // ══════════════════════════════════════════════
  // TOGGLE NOTIFIKASI ✅
  // ══════════════════════════════════════════════
  Future<void> _toggleNotifikasi() async {
    final newVal = !_notifEnabled;
    await NotificationService.setEnabled(newVal);
    setState(() => _notifEnabled = newVal);
    _showSnack(
      newVal
          ? 'Notifikasi diaktifkan. Anda akan mendapat rekomendasi setelah prediksi.'
          : 'Notifikasi dinonaktifkan.',
      color: newVal ? _green700 : _neutral600,
    );
  }

  // ══════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════
  void _showSnack(String msg, {required Color color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
  }

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
      const months = ['Jan','Feb','Mar','Apr','Mei','Jun',
                      'Jul','Agu','Sep','Okt','Nov','Des'];
      return 'Bergabung ${months[dt.month - 1]} ${dt.year}';
    } catch (_) { return createdAt; }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      const months = ['Jan','Feb','Mar','Apr','Mei','Jun',
                      'Jul','Agu','Sep','Okt','Nov','Des'];
      final time =
          '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $time';
    } catch (_) { return dateStr; }
  }

  // ══════════════════════════════════════════════
  // REUSABLE: styled text field
  // ══════════════════════════════════════════════
  Widget _styledField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: _neutral600, letterSpacing: 0.2)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: _neutral900),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: _neutral400),
            suffixIcon: suffix,
            filled: true,
            fillColor: _neutral100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _neutral200, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _neutral200, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _green700, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════
  // Dialog Edit Profil
  // ══════════════════════════════════════════════
  Future<void> _showEditProfileDialog() async {
    final nameCtrl  = TextEditingController(text: _userData?['name']  ?? '');
    final emailCtrl = TextEditingController(text: _userData?['email'] ?? '');

    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                    color: _green100, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.person_outline_rounded,
                    color: _green700, size: 24),
              ),
              const SizedBox(height: 14),
              const Text('Edit Profil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                      color: _neutral900)),
              const SizedBox(height: 4),
              const Text('Perbarui informasi pribadi Anda',
                  style: TextStyle(fontSize: 13, color: _neutral400)),
              const SizedBox(height: 20),
              const Divider(height: 1, thickness: 0.5, color: _neutral200),
              const SizedBox(height: 20),
              _styledField(controller: nameCtrl, label: 'Nama Lengkap',
                  icon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.name),
              const SizedBox(height: 14),
              _styledField(controller: emailCtrl, label: 'Alamat Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _neutral200),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Batal',
                        style: TextStyle(color: _neutral600, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Simpan',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    onPressed: () async {
                      final result = await ApiService.updateProfile(
                        _userData?['id'].toString() ?? '',
                        nameCtrl.text.trim(),
                        emailCtrl.text.trim(), '',
                      );
                      if (!mounted) return;
                      if (result['status'] == 200) {
                        setState(() {
                          _userData!['name']  = nameCtrl.text.trim();
                          _userData!['email'] = emailCtrl.text.trim();
                        });
                        Navigator.pop(context);
                        _showSnack('Profil berhasil diperbarui', color: _green700);
                      } else {
                        _showSnack(
                          result['data']['message'] ?? 'Gagal update profil',
                          color: Colors.red.shade600,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green700,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // Dialog Ubah Password
  // ══════════════════════════════════════════════
  Future<void> _showChangePasswordDialog() async {
    final oldPassCtrl  = TextEditingController();
    final newPassCtrl  = TextEditingController();
    final confPassCtrl = TextEditingController();

    bool showOld  = false;
    bool showNew  = false;
    bool showConf = false;

    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) {
          Widget passField({
            required TextEditingController ctrl,
            required String label,
            required bool show,
            required VoidCallback onToggle,
            Color borderFocus = _indigo600,
          }) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: _neutral600, letterSpacing: 0.2)),
                const SizedBox(height: 6),
                TextField(
                  controller: ctrl,
                  obscureText: !show,
                  style: const TextStyle(fontSize: 14, color: _neutral900),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.key_outlined,
                        size: 18, color: _neutral400),
                    suffixIcon: IconButton(
                      icon: Icon(
                        show ? Icons.visibility_off_outlined
                             : Icons.visibility_outlined,
                        size: 18, color: _neutral400,
                      ),
                      onPressed: onToggle,
                    ),
                    filled: true, fillColor: _neutral100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _neutral200, width: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _neutral200, width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderFocus, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            );
          }

          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                        color: _indigoBg,
                        borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.lock_outline_rounded,
                        color: _indigo600, size: 24),
                  ),
                  const SizedBox(height: 14),
                  const Text('Ubah Password',
                      style: TextStyle(fontSize: 18,
                          fontWeight: FontWeight.w800, color: _neutral900)),
                  const SizedBox(height: 4),
                  const Text(
                    'Masukkan password lama lalu buat\npassword baru yang kuat',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: _neutral400, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, thickness: 0.5, color: _neutral200),
                  const SizedBox(height: 20),
                  passField(
                    ctrl: oldPassCtrl,
                    label: 'Password Lama',
                    show: showOld,
                    onToggle: () => setLocal(() => showOld = !showOld),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    const Expanded(child: Divider(color: _neutral200)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('Password Baru',
                          style: TextStyle(fontSize: 11,
                              color: _neutral400,
                              fontWeight: FontWeight.w500)),
                    ),
                    const Expanded(child: Divider(color: _neutral200)),
                  ]),
                  const SizedBox(height: 14),
                  passField(
                    ctrl: newPassCtrl,
                    label: 'Password Baru',
                    show: showNew,
                    onToggle: () => setLocal(() => showNew = !showNew),
                  ),
                  const SizedBox(height: 14),
                  passField(
                    ctrl: confPassCtrl,
                    label: 'Konfirmasi Password Baru',
                    show: showConf,
                    onToggle: () => setLocal(() => showConf = !showConf),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _neutral200),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: const Text('Batal',
                            style: TextStyle(color: _neutral600, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.shield_outlined, size: 16),
                        label: const Text('Simpan',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                        onPressed: () async {
                          if (oldPassCtrl.text.trim().isEmpty) {
                            _showSnack('Password lama wajib diisi',
                                color: Colors.red.shade600);
                            return;
                          }
                          if (newPassCtrl.text.trim().length < 6) {
                            _showSnack('Password baru minimal 6 karakter',
                                color: Colors.red.shade600);
                            return;
                          }
                          if (newPassCtrl.text != confPassCtrl.text) {
                            _showSnack('Konfirmasi password tidak cocok',
                                color: Colors.red.shade600);
                            return;
                          }
                          if (oldPassCtrl.text == newPassCtrl.text) {
                            _showSnack(
                                'Password baru tidak boleh sama dengan password lama',
                                color: Colors.red.shade600);
                            return;
                          }
                          final result = await ApiService.changePassword(
                            _userData?['id'].toString() ?? '',
                            oldPassCtrl.text.trim(),
                            newPassCtrl.text.trim(),
                          );
                          if (!mounted) return;
                          if (result['status'] == 200) {
                            Navigator.pop(ctx);
                            _showSnack('Password berhasil diubah',
                                color: _indigo600);
                          } else {
                            _showSnack(
                              result['data']?['message'] ??
                                  'Gagal ubah password',
                              color: Colors.red.shade600,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _indigo600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════
  // Dialog Detail Prediksi
  // ══════════════════════════════════════════════
  void _showPredictionDetail(Map<String, dynamic> item) {
    final hasil      = item['hasil'] as Map<String, dynamic>?;
    final result     = hasil?['kategori'] as String? ?? '-';
    final confidence = hasil?['confidence'] as num?;
    final isPositive = _isPositiveResult(result);
    final color      = isPositive ? Colors.red.shade600 : _green700;
    final bgColor    = isPositive ? Colors.red.shade50  : _green50;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: _neutral200,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Column(children: [
                Icon(
                  isPositive ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline_rounded,
                  color: color, size: 36,
                ),
                const SizedBox(height: 8),
                Text(result, style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w800, color: color)),
                if (confidence != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Kepercayaan: ${(confidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12,
                        color: color.withOpacity(0.8),
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 20),
            _detailRow(Icons.category_outlined, 'Jenis Prediksi', 'Prediksi Obesitas'),
            _detailRow(Icons.calendar_today_outlined, 'Tanggal',
                _formatDate(item['prediksi_at'] as String?)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity, height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _neutral200),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Tutup',
                    style: TextStyle(color: _neutral600, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: _neutral400),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11,
            color: _neutral400, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600, color: _neutral900)),
      ])),
    ]),
  );

  bool _isPositiveResult(String result) {
    final lower = result.toLowerCase();
    return lower.contains('positif') || lower.contains('berisiko') ||
           lower.contains('sakit')   || lower.contains('terdeteksi');
  }

  // ══════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════
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
                      child: Column(children: [
                        const SizedBox(height: 20),
                        _buildInfoCards(),
                        const SizedBox(height: 24),
                        _buildPredictionHistorySection(),
                        const SizedBox(height: 24),
                        _buildMenuSection(),
                        const SizedBox(height: 24),
                        _buildLogoutButton(),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ══════════════════════════════════════════════
  // APP BAR
  // ══════════════════════════════════════════════
  Widget _buildAppBar() {
    final name   = _userData?['name']   as String? ?? 'Pengguna';
    final email  = _userData?['email']  as String? ?? '';
    final avatar = _userData?['avatar'] as String?;
    final since  = _memberSince(_userData?['created_at'] as String?);

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: _green700,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 14, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
          ),
          onPressed: _showEditProfileDialog,
          tooltip: 'Edit Profil',
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(children: [
          Container(decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [_green500, _green900],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
          )),
          Positioned(top: -40, right: -40,
              child: _decorCircle(180, Colors.white.withOpacity(0.05))),
          Positioned(top: 60,  right: 30,
              child: _decorCircle(80,  Colors.white.withOpacity(0.06))),
          Positioned(bottom: 40, left: -30,
              child: _decorCircle(120, Colors.white.withOpacity(0.05))),
          Positioned.fill(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.6), width: 2.5)),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: _green100,
                  backgroundImage: (avatar != null && avatar.isNotEmpty)
                      ? NetworkImage(avatar) : null,
                  child: (avatar == null || avatar.isEmpty)
                      ? Text(_initials(name), style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w800,
                          color: _green900))
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              Text(name, style: const TextStyle(fontSize: 22,
                  fontWeight: FontWeight.w800, color: Colors.white,
                  letterSpacing: -0.4)),
              const SizedBox(height: 4),
              Text(email, style: TextStyle(fontSize: 13,
                  color: Colors.white.withOpacity(0.75))),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(since, style: const TextStyle(
                    fontSize: 11, color: Colors.white,
                    fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _decorCircle(double size, Color color) => Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color));

  // ══════════════════════════════════════════════
  // INFO CARDS
  // ══════════════════════════════════════════════
  Widget _buildInfoCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionLabel('Informasi Akun'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _neutral200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(children: [
            _infoRow(Icons.person_outline_rounded, 'Nama Lengkap',
                _userData?['name'] ?? '-'),
            _divider(),
            _infoRow(Icons.email_outlined, 'Email',
                _userData?['email'] ?? '-'),
          ]),
        ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      Container(width: 38, height: 38,
          decoration: BoxDecoration(color: _green50,
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: _green700, size: 18)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11,
            color: _neutral400, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14,
            fontWeight: FontWeight.w600, color: _neutral900)),
      ])),
    ]),
  );

  Widget _divider() => Divider(height: 1, thickness: 1,
      color: _neutral100, indent: 16, endIndent: 16);

  // ══════════════════════════════════════════════
  // RIWAYAT PREDIKSI
  // ══════════════════════════════════════════════
  Widget _buildPredictionHistorySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const _SectionLabel('Riwayat Prediksi'),
          if (!_isLoadingHistory && _predictionHistory.isNotEmpty)
            GestureDetector(
              onTap: _showAllPredictionHistory,
              child: const Text('Lihat Semua',
                  style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600, color: _green700)),
            ),
        ]),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _neutral200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: _isLoadingHistory
              ? const Padding(padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator(
                      color: _green700, strokeWidth: 2)))
              : _predictionHistory.isEmpty
                  ? _buildEmptyPrediction()
                  : Column(children: [
                      ..._predictionHistory.take(3).toList().asMap().entries.map((e) {
                        final isLast = e.key == (_predictionHistory.length > 3
                            ? 2 : _predictionHistory.length - 1);
                        return Column(children: [
                          _predictionHistoryItem(e.value),
                          if (!isLast) _divider(),
                        ]);
                      }),
                    ]),
        ),
      ]),
    );
  }

  Widget _buildEmptyPrediction() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(children: [
        Container(width: 56, height: 56,
            decoration: BoxDecoration(color: _green50,
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.history_outlined, color: _green700, size: 26)),
        const SizedBox(height: 12),
        const Text('Belum ada riwayat prediksi',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: _neutral900)),
        const SizedBox(height: 4),
        const Text('Prediksi yang Anda lakukan\nakan muncul di sini',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _neutral400, height: 1.5)),
      ]),
    );
  }

  Widget _predictionHistoryItem(Map<String, dynamic> item) {
    final hasil       = item['hasil'] as Map<String, dynamic>?;
    final result      = hasil?['kategori'] as String? ?? '-';
    final createdAt   = item['prediksi_at'] as String?;
    final confidence  = hasil?['confidence'] as num?;
    final isPositive  = _isPositiveResult(result);
    final resultColor = isPositive ? Colors.red.shade600 : _green700;
    final resultBg    = isPositive ? Colors.red.shade50  : _green50;
    final resultIcon  = isPositive
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline_rounded;

    return InkWell(
      onTap: () => _showPredictionDetail(item),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(width: 42, height: 42,
              decoration: BoxDecoration(color: resultBg,
                  borderRadius: BorderRadius.circular(13)),
              child: Icon(resultIcon, color: resultColor, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Text('Prediksi Obesitas',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: _neutral900), maxLines: 1,
                  overflow: TextOverflow.ellipsis)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: resultBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: resultColor.withOpacity(0.25), width: 0.8)),
                child: Text(result, style: TextStyle(fontSize: 10,
                    fontWeight: FontWeight.w700, color: resultColor)),
              ),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              Text(_formatDate(createdAt), style: const TextStyle(
                  fontSize: 11, color: _neutral400)),
              if (confidence != null) ...[
                const SizedBox(width: 8),
                Container(width: 3, height: 3,
                    decoration: const BoxDecoration(shape: BoxShape.circle,
                        color: _neutral400)),
                const SizedBox(width: 8),
                Text('${confidence.toStringAsFixed(0)}% yakin',
                    style: const TextStyle(fontSize: 11, color: _neutral400)),
              ],
            ]),
          ])),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: _neutral400, size: 18),
        ]),
      ),
    );
  }

  void _showAllPredictionHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75, maxChildSize: 0.95, minChildSize: 0.4,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(children: [
            Padding(padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: _neutral200,
                      borderRadius: BorderRadius.circular(2)))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: _green50,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.history_outlined,
                        color: _green700, size: 18)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Riwayat Prediksi', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800,
                      color: _neutral900)),
                  Text('${_predictionHistory.length} prediksi',
                      style: const TextStyle(fontSize: 12, color: _neutral400)),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: _neutral100),
            Expanded(child: ListView.separated(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _predictionHistory.length,
              separatorBuilder: (_, __) => Divider(height: 1,
                  color: _neutral100, indent: 16, endIndent: 16),
              itemBuilder: (_, i) => _predictionHistoryItem(_predictionHistory[i]),
            )),
          ]),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // MENU SECTION ✅ notifikasi sekarang fungsional
  // ══════════════════════════════════════════════
  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionLabel('Pengaturan'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _neutral200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(children: [
            _menuRow(
              Icons.edit_note_rounded,
              'Edit Profil',
              'Perbarui data pribadi Anda',
              _green700,
              _showEditProfileDialog,
            ),
            _divider(),
            _menuRow(
              Icons.lock_outline_rounded,
              'Ubah Password',
              'Ganti kata sandi akun',
              _indigo600,
              _showChangePasswordDialog,
            ),
            _divider(),
            // ✅ DIPERBAIKI: notifikasi sekarang menggunakan switch
            _menuRowWithTrailing(
              Icons.notifications_none_rounded,
              'Notifikasi',
              _notifEnabled ? 'Aktif — rekomendasi prediksi' : 'Nonaktif',
              const Color(0xFFF59E0B),
              _toggleNotifikasi,
              Switch(
                value: _notifEnabled,
                onChanged: (_) => _toggleNotifikasi(),
                activeColor: _green700,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // Menu row standar (dengan chevron)
  Widget _menuRow(IconData icon, String title, String subtitle,
      Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.w700, color: _neutral900)),
            Text(subtitle, style: const TextStyle(fontSize: 11,
                color: _neutral400, fontWeight: FontWeight.w400)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: _neutral400, size: 20),
        ]),
      ),
    );
  }

  // ✅ Menu row dengan trailing widget (untuk switch notifikasi)
  Widget _menuRowWithTrailing(IconData icon, String title, String subtitle,
      Color iconColor, VoidCallback onTap, Widget trailing) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.w700, color: _neutral900)),
            Text(subtitle, style: const TextStyle(fontSize: 11,
                color: _neutral400, fontWeight: FontWeight.w400)),
          ])),
          trailing,
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // LOGOUT BUTTON
  // ══════════════════════════════════════════════
  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity, height: 52,
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
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          color: Color(0xFF4B5563), letterSpacing: 0.2));
}