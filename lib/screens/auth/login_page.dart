import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/dashboard_page.dart';
import '../../utils/custom_snackbar.dart';
// import '../../utils/encryption_helper.dart';
import '../../utils/app_colors.dart';
import '../../utils/activity_logger.dart';

// ==========================================
// VARIABLE GLOBAL
// ==========================================
String currentUserNik = '';
String currentUserName = '';
String currentUserRole = '';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _nikController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // ── Pulse animation (logo berdetak) ──
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  // ── Staggered entry animation ──
  AnimationController? _entryCtrl;

  // Logo
  Animation<double>? _logoFade;
  Animation<Offset>? _logoSlide;
  // Title + subtitle
  Animation<double>? _titleFade;
  Animation<Offset>? _titleSlide;
  // Badge chips
  Animation<double>? _badgeFade;
  Animation<Offset>? _badgeSlide;
  // Form sheet (mobile) / desktop card
  Animation<double>? _formFade;
  Animation<Offset>? _formSlide;
  // Background glow
  Animation<double>? _bgFade;

  @override
  void initState() {
    super.initState();

    // ── Pulse (logo scale) ──
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );

    // ── Entry controller: 950ms total ──
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    // helper
    Animation<double> _fade(double start, double end) =>
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _entryCtrl!,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        );
    Animation<Offset> _slide(
      double start,
      double end, {
      Offset from = const Offset(0, 0.08),
    }) => Tween<Offset>(begin: from, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entryCtrl!,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );

    // Background: 0–35%
    _bgFade = _fade(0.0, 0.35);

    // Logo: 0–45%
    _logoFade = _fade(0.0, 0.45);
    _logoSlide = _slide(0.0, 0.5, from: const Offset(0, 0.12));

    // Title: 15–58%
    _titleFade = _fade(0.15, 0.58);
    _titleSlide = _slide(0.15, 0.62, from: const Offset(0, 0.1));

    // Badge chips: 30–70%
    _badgeFade = _fade(0.30, 0.70);
    _badgeSlide = _slide(0.30, 0.72, from: const Offset(0, 0.08));

    // Form sheet: 45–100%
    _formFade = _fade(0.45, 1.0);
    _formSlide = _slide(0.45, 1.0, from: const Offset(0, 0.06));

    // Mulai setelah frame pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entryCtrl?.forward();
    });
  }

  @override
  void dispose() {
    _nikController.dispose();
    _passwordController.dispose();
    _pulseController?.dispose();
    _entryCtrl?.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final nik = _nikController.text.trim();
    final password = _passwordController.text.trim();

    if (nik.isEmpty || password.isEmpty) {
      CustomSnackBar.show(context, "NIK dan Password wajib diisi!", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Bersihkan NIK dari spasi saat mencoba login
      final String cleanNik = nik.replaceAll(' ', '');
      final String fakeEmail = '$cleanNik@edp.com';

      final AuthResponse res = await Supabase.instance.client.auth
          .signInWithPassword(email: fakeEmail, password: password);

      // 2. Jika sukses login, ambil data detail dari tabel profiles
      if (res.user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', res.user!.id)
            .single();

        // 3. Isi variabel global seperti kodingan Mas sebelumnya
        currentUserNik = profile['nik'] ?? '';
        currentUserName = profile['nama'] ?? 'Karyawan';
        currentUserRole = profile['role'] ?? 'user';

        // 4. Nyalakan status Online dan catat Log Aktivitas
        await ActivityLogger.updateOnlineStatus(true);
        await ActivityLogger.logAction(
          actionType: "LOGIN",
          description: "Pengguna berhasil masuk ke sistem",
        );

        if (mounted) {
          CustomSnackBar.show(
            context,
            "Selamat datang, $currentUserName!",
            Colors.blue,
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
        }
      }
    } on AuthException catch (_) {
      // Menangkap error khusus dari Supabase Auth (misal: password salah)
      if (mounted) {
        CustomSnackBar.show(
          context,
          "Login Gagal: NIK atau Password salah!",
          Colors.red,
        );
      }
    } catch (e) {
      // Menangkap error jaringan atau lainnya
      if (mounted) {
        CustomSnackBar.show(context, "Terjadi kesalahan: $e", Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: context.primaryColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background dengan fade-in
          FadeTransition(
            opacity: _bgFade ?? const AlwaysStoppedAnimation(1.0),
            child: _buildBackground(),
          ),

          // Konten utama
          isDesktop
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildDesktopLayout(size),
                  ),
                )
              : _buildMobileLayout(size),
        ],
      ),
    );
  }

  // ==========================================
  // BACKGROUND
  // ==========================================
  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  context.accentColor.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          right: -80,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  context.secondaryAccent.withOpacity(0.07),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
      ],
    );
  }

  // ==========================================
  // DESKTOP LAYOUT — seluruh card fade+slide up
  // ==========================================
  Widget _buildDesktopLayout(Size size) {
    return FadeTransition(
      opacity: _formFade ?? const AlwaysStoppedAnimation(1.0),
      child: SlideTransition(
        position: _formSlide ?? const AlwaysStoppedAnimation(Offset.zero),
        child: Container(
          width: 920,
          height: 560,
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: context.borderColor),
            boxShadow: [
              BoxShadow(
                color: context.accentColor.withOpacity(0.06),
                blurRadius: 60,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(flex: 5, child: _buildBrandingPanel()),
              Container(width: 1, color: context.borderColor),
              Expanded(flex: 4, child: _buildFormPanel()),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MOBILE LAYOUT
  // ==========================================
  Widget _buildMobileLayout(Size size) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
          ),
          child: IntrinsicHeight(
            child: Column(
              children: [
                _buildMobileHero(),
                Expanded(
                  child: FadeTransition(
                    opacity: _formFade ?? const AlwaysStoppedAnimation(1.0),
                    child: SlideTransition(
                      position:
                          _formSlide ??
                          const AlwaysStoppedAnimation(Offset.zero),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 24,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: _buildMobileForm(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MOBILE HERO — staggered per elemen
  // ==========================================
  Widget _buildMobileHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo — fade + slide + pulse
          FadeTransition(
            opacity: _logoFade ?? const AlwaysStoppedAnimation(1.0),
            child: SlideTransition(
              position: _logoSlide ?? const AlwaysStoppedAnimation(Offset.zero),
              child: ScaleTransition(
                scale: _pulseAnimation ?? const AlwaysStoppedAnimation(1.0),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: context.accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: context.accentColor.withOpacity(0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.accentColor.withOpacity(0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.lan_outlined,
                    size: 28,
                    color: context.accentColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title — fade + slide
          FadeTransition(
            opacity: _titleFade ?? const AlwaysStoppedAnimation(1.0),
            child: SlideTransition(
              position:
                  _titleSlide ?? const AlwaysStoppedAnimation(Offset.zero),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'EDP',
                          style: TextStyle(
                            color: context.accentColor,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            height: 1,
                          ),
                        ),
                        TextSpan(
                          text: ' NetOps',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pusat kendali infrastruktur IT & jaringan.',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Badge chips — fade + slide
          FadeTransition(
            opacity: _badgeFade ?? const AlwaysStoppedAnimation(1.0),
            child: SlideTransition(
              position:
                  _badgeSlide ?? const AlwaysStoppedAnimation(Offset.zero),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildOnlineBadge(),
                  _buildMobileChip(Icons.router_outlined, 'Network'),
                  _buildMobileChip(Icons.desktop_windows_outlined, 'VNC'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.successColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: context.successColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.successColor.withOpacity(0.7),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'System Online',
            style: TextStyle(
              color: context.successColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: context.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MOBILE FORM
  // ==========================================
  Widget _buildMobileForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [context.accentColor, context.secondaryAccent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign In',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Gunakan NIK dan password Anda',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _buildFieldLabel('NIK KARYAWAN', Icons.badge_outlined),
          const SizedBox(height: 7),
          _buildInputField(
            controller: _nikController,
            hint: 'Contoh: 2012xxxxx',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('PASSWORD', Icons.lock_outline),
          const SizedBox(height: 7),
          _buildInputField(
            controller: _passwordController,
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: context.textSecondary,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 28),
          _buildLoginButton(),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'EDP NetOps v2.0  ·  Developed by Pahruroji',
              style: TextStyle(
                color: context.textSecondary.withOpacity(0.45),
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BRANDING PANEL (Desktop kiri)
  // ==========================================
  Widget _buildBrandingPanel() {
    return Container(
      padding: const EdgeInsets.all(44),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          bottomLeft: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          FadeTransition(
            opacity: _logoFade ?? const AlwaysStoppedAnimation(1.0),
            child: SlideTransition(
              position: _logoSlide ?? const AlwaysStoppedAnimation(Offset.zero),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.accentColor.withOpacity(0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.accentColor.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.rocket_launch_outlined,
                  size: 32,
                  color: context.accentColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Title
          FadeTransition(
            opacity: _titleFade ?? const AlwaysStoppedAnimation(1.0),
            child: SlideTransition(
              position:
                  _titleSlide ?? const AlwaysStoppedAnimation(Offset.zero),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Welcome to\n',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            height: 1.8,
                          ),
                        ),
                        TextSpan(
                          text: 'EDP',
                          style: TextStyle(
                            color: context.accentColor,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            height: 1,
                          ),
                        ),
                        TextSpan(
                          text: ' NetOps',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'EDP Network Operations.\nPusat kendali infrastruktur IT dan jaringan dalam satu platform terintegrasi.',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Badges
          FadeTransition(
            opacity: _badgeFade ?? const AlwaysStoppedAnimation(1.0),
            child: SlideTransition(
              position:
                  _badgeSlide ?? const AlwaysStoppedAnimation(Offset.zero),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFeatureBadge(
                    Icons.router_outlined,
                    'Network Monitoring',
                  ),
                  _buildFeatureBadge(Icons.router_outlined, 'Router Control'),
                  _buildFeatureBadge(
                    Icons.desktop_windows_outlined,
                    'Remote VNC',
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          FadeTransition(
            opacity: _badgeFade ?? const AlwaysStoppedAnimation(1.0),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E676).withOpacity(0.7),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'System Online  ·  © 2026 Developed by Pahruroji.',
                  style: TextStyle(
                    color: context.textSecondary.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: context.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FORM PANEL (Desktop kanan)
  // ==========================================
  Widget _buildFormPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 44),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [context.accentColor, context.secondaryAccent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign In',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    'Gunakan NIK dan password Anda',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 36),
          _buildFieldLabel('NIK KARYAWAN', Icons.badge_outlined),
          const SizedBox(height: 7),
          _buildInputField(
            controller: _nikController,
            hint: 'Contoh: 2012xxxxx',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('PASSWORD', Icons.lock_outline),
          const SizedBox(height: 7),
          _buildInputField(
            controller: _passwordController,
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: context.textSecondary,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 32),
          _buildLoginButton(),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(width: 24, height: 1, color: context.borderColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'EDP NetOps v2.0  ·  Developed by Pahruroji',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textSecondary.withOpacity(0.5),
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 24, height: 1, color: context.borderColor),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SHARED WIDGETS
  // ==========================================
  Widget _buildFieldLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 11, color: context.accentColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: context.accentColor,
          selectionColor: context.accentColor.withOpacity(0.3),
          selectionHandleColor: context.accentColor,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        cursorColor: context.accentColor,
        style: TextStyle(
          color: context.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        onSubmitted: (_) => _signIn(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: context.textSecondary.withOpacity(0.4),
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, size: 18, color: context.textSecondary),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: context.surfaceColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.accentColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isLoading
            ? []
            : [
                BoxShadow(
                  color: context.accentColor.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _signIn,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: _isLoading
                  ? null
                  : LinearGradient(
                      colors: [context.accentColor, const Color(0xFF00A8CC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: _isLoading ? context.borderColor : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: context.textSecondary,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Memverifikasi...',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Masuk ke Dashboard',
                          style: TextStyle(
                            color: context.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: context.primaryColor,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// BACKGROUND DOT GRID PAINTER
// ==========================================
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E3A5F).withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.fill;
    const spacing = 32.0;
    const dotRadius = 1.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
