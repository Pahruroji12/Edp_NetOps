import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:edp_netops/core/theme/app_colors.dart';
import 'package:edp_netops/core/widgets/custom_snackbar.dart';
import 'login_controller.dart';
import 'widgets/dot_grid_painter.dart';
import 'widgets/login_desktop_panel.dart';
import 'widgets/login_mobile_panel.dart';
import 'widgets/login_success_overlay.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _nikController = TextEditingController();
  final _passwordController = TextEditingController();
  final _controller = LoginController();

  bool get _isLoading => _controller.isLoading;

  // Cinematic success loader states
  bool _showSuccessOverlay = false;
  String _successName = '';
  String _successStatus = 'Kredensial berhasil diverifikasi...';

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

    _controller.addListener(_onControllerChanged);

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
    Animation<double> fade(double start, double end) =>
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _entryCtrl!,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        );
    Animation<Offset> slide(
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
    _bgFade = fade(0.0, 0.35);

    // Logo: 0–45%
    _logoFade = fade(0.0, 0.45);
    _logoSlide = slide(0.0, 0.5, from: const Offset(0, 0.12));

    // Title: 15–58%
    _titleFade = fade(0.15, 0.58);
    _titleSlide = slide(0.15, 0.62, from: const Offset(0, 0.1));

    // Badge chips: 30–70%
    _badgeFade = fade(0.30, 0.70);
    _badgeSlide = slide(0.30, 0.72, from: const Offset(0, 0.08));

    // Form sheet: 45–100%
    _formFade = fade(0.45, 1.0);
    _formSlide = slide(0.45, 1.0, from: const Offset(0, 0.06));

    // Mulai setelah frame pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entryCtrl?.forward();
    });
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _nikController.dispose();
    _passwordController.dispose();
    _pulseController?.dispose();
    _entryCtrl?.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final userName = await _controller.signIn(
      nik: _nikController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (userName != null) {
      // Cinematic transition overlay
      setState(() {
        _successName = userName;
        _showSuccessOverlay = true;
      });

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _successStatus = 'Menghubungkan ke NetOps Node...');

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _successStatus = 'Menginisialisasi panel kontrol...');

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      context.go('/dashboard');
      return;
    }

    CustomSnackBar.error(
      _controller.errorMessage ?? 'Login gagal',
    );

    setState(() {}); // refresh loading state
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    final logoFadeAnim = _logoFade ?? const AlwaysStoppedAnimation(1.0);
    final logoSlideAnim = _logoSlide ?? const AlwaysStoppedAnimation(Offset.zero);
    final pulseAnim = _pulseAnimation ?? const AlwaysStoppedAnimation(1.0);
    final titleFadeAnim = _titleFade ?? const AlwaysStoppedAnimation(1.0);
    final titleSlideAnim = _titleSlide ?? const AlwaysStoppedAnimation(Offset.zero);
    final badgeFadeAnim = _badgeFade ?? const AlwaysStoppedAnimation(1.0);
    final badgeSlideAnim = _badgeSlide ?? const AlwaysStoppedAnimation(Offset.zero);
    final formFadeAnim = _formFade ?? const AlwaysStoppedAnimation(1.0);
    final formSlideAnim = _formSlide ?? const AlwaysStoppedAnimation(Offset.zero);

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
                    child: LoginDesktopPanel(
                      nikController: _nikController,
                      passwordController: _passwordController,
                      isLoading: _isLoading,
                      onSignIn: _signIn,
                      logoFade: logoFadeAnim,
                      logoSlide: logoSlideAnim,
                      pulseAnimation: pulseAnim,
                      titleFade: titleFadeAnim,
                      titleSlide: titleSlideAnim,
                      badgeFade: badgeFadeAnim,
                      badgeSlide: badgeSlideAnim,
                      formFade: formFadeAnim,
                      formSlide: formSlideAnim,
                    ),
                  ),
                )
              : LoginMobilePanel(
                  nikController: _nikController,
                  passwordController: _passwordController,
                  isLoading: _isLoading,
                  onSignIn: _signIn,
                  logoFade: logoFadeAnim,
                  logoSlide: logoSlideAnim,
                  pulseAnimation: pulseAnim,
                  titleFade: titleFadeAnim,
                  titleSlide: titleSlideAnim,
                  badgeFade: badgeFadeAnim,
                  badgeSlide: badgeSlideAnim,
                  formFade: formFadeAnim,
                  formSlide: formSlideAnim,
                ),

          // Cinematic loading overlay
          if (_pulseController != null && _pulseAnimation != null)
            LoginSuccessOverlay(
              show: _showSuccessOverlay,
              successName: _successName,
              successStatus: _successStatus,
              pulseController: _pulseController!,
              pulseAnimation: _pulseAnimation!,
            ),
        ],
      ),
    );
  }

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
        const Positioned.fill(
          child: CustomPaint(
            painter: DotGridPainter(),
          ),
        ),
      ],
    );
  }
}
