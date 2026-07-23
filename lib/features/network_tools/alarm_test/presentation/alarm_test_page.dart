import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:edp_netops/core/theme/app_colors.dart';
import 'package:edp_netops/core/utils/responsive_helper.dart';
import 'package:edp_netops/core/widgets/custom_snackbar.dart';
import 'package:edp_netops/core/widgets/page_entry_transition.dart';
import 'package:edp_netops/core/widgets/app_hamburger_button.dart';
import 'package:edp_netops/core/widgets/confirm_dialog.dart';
import 'package:edp_netops/core/widgets/network_action_buttons.dart';
import 'alarm_test_controller.dart';

class AlarmTestPage extends StatefulWidget {
  const AlarmTestPage({super.key});

  @override
  State<AlarmTestPage> createState() => _AlarmTestPageState();
}

class _AlarmTestPageState extends State<AlarmTestPage> {
  final _controller = AlarmTestController.instance;
  final _logScrollController = ScrollController();
  bool _animationsReady = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    // Hanya load config jika belum pernah dimuat (first visit)
    if (_controller.servers.isEmpty && !_controller.isLoading) {
      _controller.loadConfig();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animationsReady = true);
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    // Jangan dispose controller — biarkan hidup selama aplikasi berjalan
    _logScrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});

    // Auto scroll ke bawah di console log jika sedang running
    if (_controller.isTesting && _logScrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScrollController.hasClients) {
          _logScrollController.animateTo(
            _logScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _confirmAndRunTest() async {
    final selectedCount = _controller.servers.where((s) => s.isSelected).length;
    if (selectedCount == 0) {
      CustomSnackBar.show(
        context,
        'Pilih minimal 1 server database!',
        context.dangerColor,
      );
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      title: 'Jalankan Dial Alarm Test?',
      message:
          'Sistem akan menghapus data test lama pada $selectedCount database server yang dipilih, lalu menyuntikkan data test baru untuk penerima dan alarm. Lanjutkan?',
      confirmLabel: 'Ya, Jalankan',
      cancelLabel: 'Batal',
      icon: Icons.ring_volume_outlined,
      isDanger: false,
    );

    if (confirmed == true && mounted) {
      _controller.runAlarmTest();
    }
  }

  Widget _buildLoadingState() {
    return Container(
      color: context.primaryColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: context.accentColor,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "MEMUAT...",
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      body: PageEntryTransition(
        child: _controller.isLoading
            ? _buildLoadingState()
            : AnimatedOpacity(
                opacity: _animationsReady ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          context.pagePaddingH,
                          0,
                          context.pagePaddingH,
                          40,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),

                            // ── SECTION 1: DATABASE ALARM SERVERS ──
                            _buildSectionLabel(
                              "DATABASE ALARM SERVERS",
                              Icons.storage_outlined,
                            ),
                            const SizedBox(height: 12),
                            _buildServersCard(),
                            const SizedBox(height: 24),

                            // ── SECTION 2: PARAMETER & PENERIMA ──
                            _buildSectionLabel(
                              "PARAMETER & DAFTAR PENERIMA",
                              Icons.settings_outlined,
                            ),
                            const SizedBox(height: 12),
                            _buildParameterAndRecipientsCard(),
                            const SizedBox(height: 24),

                            // ── SECTION 3: CONSOLE LOGS ──
                            if (_controller.logs.isNotEmpty ||
                                _controller.isTesting) ...[
                              _buildSectionLabel(
                                "DIAL TEST EXECUTION CONSOLE",
                                Icons.terminal_outlined,
                              ),
                              const SizedBox(height: 12),
                              _buildConsoleCard(),
                              const SizedBox(height: 24),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      backgroundColor: context.primaryColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: context.isDesktop
          ? null
          : const Center(child: AppHamburgerButton()),
      iconTheme: IconThemeData(color: context.textPrimary),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.accentColor.withOpacity(0.15),
                  context.secondaryAccent.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.accentColor.withOpacity(0.2)),
            ),
            child: Icon(
              Icons.ring_volume_outlined,
              color: context.accentColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TEST DIAL ALARM",
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  "Pengujian Alarm & Registrasi Nomor Telepon",
                  style: TextStyle(color: context.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                context.accentColor.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServersCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: _buildServersList(),
    );
  }

  Widget _buildParameterAndRecipientsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parameters: Kode Toko & No Telepon
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              return Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: "Kode Toko",
                      controller: _controller.shopCodeCtrl,
                      icon: Icons.storefront_outlined,
                    ),
                  ),
                  SizedBox(width: isWide ? 16 : 10),
                  Expanded(
                    child: _buildTextField(
                      label: "No Telepon Alarm",
                      controller: _controller.phoneAlarmCtrl,
                      icon: Icons.phone_android_outlined,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Divider(color: context.borderColor, height: 1),
          const SizedBox(height: 20),

          // Recipients sub-header
          Row(
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 16,
                color: context.accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                "DAFTAR PENERIMA ALARM",
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Recipients list
          for (int i = 0; i < _controller.recipients.length; i++) ...[
            if (i > 0) Divider(color: context.borderColor, height: 24),
            _buildRecipientRow(_controller.recipients[i]),
          ],

          const SizedBox(height: 20),
          Divider(color: context.borderColor, height: 1),
          const SizedBox(height: 20),

          // Execute button (compact, like STB generate button)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _controller.isTesting ? null : _confirmAndRunTest,
              icon: _controller.isTesting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.primaryColor,
                      ),
                    )
                  : Icon(
                      Icons.play_arrow_rounded,
                      color: context.primaryColor,
                      size: 18,
                    ),
              label: Text(
                _controller.isTesting ? 'Mengeksekusi...' : 'EXECUTE ALARM',
                style: TextStyle(
                  color: context.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.accentColor,
                disabledBackgroundColor: context.accentColor.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientRow(AlarmRecipient recip) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final content = [
          SizedBox(
            width: isCompact ? double.infinity : 180,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: context.accentColor.withOpacity(0.12),
                  child: Icon(
                    Icons.ring_volume_outlined,
                    color: context.accentColor,
                    size: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recip.jabatan,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8, width: 12),
          Expanded(
            flex: 2,
            child: _buildMiniTextField(
              label: "Nama Penerima",
              controller: recip.nameCtrl,
              icon: Icons.person_outline,
            ),
          ),
          const SizedBox(height: 8, width: 12),
          Expanded(
            flex: 2,
            child: _buildMiniTextField(
              label: "No Handphone",
              controller: recip.phoneCtrl,
              icon: Icons.phone_iphone_outlined,
            ),
          ),
        ];

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              content[0], // header
              const SizedBox(height: 12),
              content[2], // Nama
              const SizedBox(height: 10),
              content[4], // HP
            ],
          );
        }

        return Row(
          children: [
            content[0], // Info urutan/jabatan
            const SizedBox(width: 16),
            content[2], // Nama
            const SizedBox(width: 16),
            content[4], // HP
          ],
        );
      },
    );
  }

  Widget _buildServersList() {
    if (_controller.servers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Center(
          child: Text(
            "Belum ada server alarm terdaftar. Tambahkan di menu Setting.",
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (int i = 0; i < _controller.servers.length; i++) ...[
          if (i > 0)
            Divider(height: 1, color: context.borderColor.withOpacity(0.6)),
          _buildServerRow(_controller.servers[i]),
        ],
      ],
    );
  }

  Widget _buildServerRow(AlarmServer server) {
    final bool hasHost = server.host.isNotEmpty;

    final ipWidget = GestureDetector(
      onTap: hasHost
          ? () {
              Clipboard.setData(ClipboardData(text: server.host));
              CustomSnackBar.show(
                context,
                "${server.label} IP disalin!",
                const Color(0xFF00D4FF),
              );
            }
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hasHost ? server.host : "—",
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: hasHost
                  ? context.textPrimary
                  : context.textSecondary.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
          if (hasHost) ...[
            const SizedBox(width: 5),
            Icon(
              Icons.copy_outlined,
              size: 11,
              color: context.textSecondary.withOpacity(0.5),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Checkbox(
            activeColor: context.accentColor,
            value: server.isSelected,
            onChanged: (val) {
              setState(() {
                server.isSelected = val ?? false;
              });
            },
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.desktop_windows_outlined,
            color: hasHost
                ? context.accentColor.withOpacity(0.7)
                : context.textSecondary,
            size: 17,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  server.label,
                  style: TextStyle(color: context.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ipWidget,
                    const SizedBox(width: 8),
                    _buildStatusIndicator(server),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MiniActionButton(
                label: "VNC",
                icon: Icons.desktop_windows_outlined,
                color: const Color(0xFF00C9A7),
                onTap: () => _controller.launchVnc(server.host),
              ),
              const SizedBox(width: 4),
              MiniActionButton(
                label: "CEK KONEKSI DB",
                color: context.textSecondary,
                onTap: () => _controller.testConnection(server),
                isOutline: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(AlarmServer server) {
    if (server.isChecking) {
      return SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: context.accentColor,
        ),
      );
    }

    final isOnline = server.isOnline;
    if (isOnline == null) {
      return const SizedBox.shrink();
    }

    if (isOnline) {
      final latencyStr = server.latencyMs != null
          ? " ${server.latencyMs}ms"
          : "";
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: context.successColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: context.successColor.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: context.successColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              "ON$latencyStr",
              style: TextStyle(
                color: context.successColor,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: context.dangerColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: context.dangerColor.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: context.dangerColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              "OFF",
              style: TextStyle(
                color: context.dangerColor,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildConsoleCard() {
    final color = _controller.isTesting
        ? context.accentColor
        : context.successColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.amberAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "DIAL TEST LOGS",
                style: TextStyle(
                  color: context.textPrimary.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              if (_controller.isTesting)
                Row(
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        color: color,
                        strokeWidth: 1.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "EXECUTING",
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                )
              else
                Text(
                  "FINISHED",
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
          Divider(color: context.borderColor, height: 20),
          Container(
            width: double.infinity,
            height: 250,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Scrollbar(
              controller: _logScrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _logScrollController,
                physics: const BouncingScrollPhysics(),
                itemCount: _controller.logs.length,
                itemBuilder: (context, index) {
                  return _buildLogLine(_controller.logs[index]);
                },
              ),
            ),
          ),
          if (_controller.isTesting) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _controller.progressValue,
                minHeight: 5,
                backgroundColor: context.textPrimary.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogLine(AlarmLogLine log) {
    String time =
        "${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}";
    Color tagColor = context.textSecondary;

    switch (log.type) {
      case '[system]':
        tagColor = Colors.grey;
        break;
      case '[info]':
        tagColor = const Color(0xFF00E5FF);
        break;
      case '[error]':
        tagColor = context.dangerColor;
        break;
      case '[success]':
        tagColor = context.successColor;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.4,
            color: context.textPrimary,
          ),
          children: [
            TextSpan(
              text: "$time ",
              style: TextStyle(color: context.textSecondary.withOpacity(0.5)),
            ),
            TextSpan(
              text: "${log.type} ",
              style: TextStyle(color: tagColor, fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: log.message,
              style: TextStyle(
                color: log.type == '[error]'
                    ? context.dangerColor.withOpacity(0.9)
                    : (log.type == '[success]'
                          ? context.successColor
                          : context.textPrimary.withOpacity(0.85)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isNumeric = false,
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
        cursorColor: context.accentColor,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumeric
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        style: TextStyle(color: context.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: context.textSecondary, fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: context.textSecondary),
          isDense: true,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: context.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: context.accentColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
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
        cursorColor: context.accentColor,
        style: TextStyle(color: context.textPrimary, fontSize: 12),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: context.textSecondary, fontSize: 12),
          prefixIcon: Icon(icon, size: 14, color: context.textSecondary),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: context.accentColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 13, color: context.accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.borderColor, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
