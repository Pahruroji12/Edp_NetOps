import 'package:flutter/material.dart';
import 'package:edp_netops/core/theme/app_colors.dart';

class LoginMobilePanel extends StatefulWidget {
  final TextEditingController nikController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSignIn;

  // Animations
  final Animation<double> logoFade;
  final Animation<Offset> logoSlide;
  final Animation<double> pulseAnimation;
  final Animation<double> titleFade;
  final Animation<Offset> titleSlide;
  final Animation<double> badgeFade;
  final Animation<Offset> badgeSlide;
  final Animation<double> formFade;
  final Animation<Offset> formSlide;

  const LoginMobilePanel({
    super.key,
    required this.nikController,
    required this.passwordController,
    required this.isLoading,
    required this.onSignIn,
    required this.logoFade,
    required this.logoSlide,
    required this.pulseAnimation,
    required this.titleFade,
    required this.titleSlide,
    required this.badgeFade,
    required this.badgeSlide,
    required this.formFade,
    required this.formSlide,
  });

  @override
  State<LoginMobilePanel> createState() => _LoginMobilePanelState();
}

class _LoginMobilePanelState extends State<LoginMobilePanel> {
  bool _isButtonHovered = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
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
                    opacity: widget.formFade,
                    child: SlideTransition(
                      position: widget.formSlide,
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

  Widget _buildMobileHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo — fade + slide + pulse
          FadeTransition(
            opacity: widget.logoFade,
            child: SlideTransition(
              position: widget.logoSlide,
              child: ScaleTransition(
                scale: widget.pulseAnimation,
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
            opacity: widget.titleFade,
            child: SlideTransition(
              position: widget.titleSlide,
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
            opacity: widget.badgeFade,
            child: SlideTransition(
              position: widget.badgeSlide,
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
            controller: widget.nikController,
            hint: 'Contoh: 2012xxxxx',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('PASSWORD', Icons.lock_outline),
          const SizedBox(height: 7),
          _buildInputField(
            controller: widget.passwordController,
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
              'EDP NetOps v2.8.0  ·  Developed by Pahruroji',
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
        onSubmitted: (_) => widget.onSignIn(),
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
    final hoverOffset = _isButtonHovered && !widget.isLoading
        ? const Offset(3, 0)
        : Offset.zero;

    return MouseRegion(
      onEnter: (_) => setState(() => _isButtonHovered = true),
      onExit: (_) => setState(() => _isButtonHovered = false),
      cursor: widget.isLoading
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isButtonHovered && !widget.isLoading ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.isLoading
                ? []
                : [
                    BoxShadow(
                      color: _isButtonHovered
                          ? context.accentColor.withOpacity(0.45)
                          : context.accentColor.withOpacity(0.3),
                      blurRadius: _isButtonHovered ? 20 : 16,
                      offset: Offset(0, _isButtonHovered ? 7 : 5),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onSignIn,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: widget.isLoading
                      ? null
                      : LinearGradient(
                          colors: _isButtonHovered
                              ? [
                                  const Color(0xFF00C3FF),
                                  const Color(0xFF00A8CC),
                                ]
                              : [context.accentColor, const Color(0xFF00A8CC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: widget.isLoading ? context.borderColor : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: widget.isLoading
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
                            AnimatedSlide(
                              offset: hoverOffset,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              child: Container(
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
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
