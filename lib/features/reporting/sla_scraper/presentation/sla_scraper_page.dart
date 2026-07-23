import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/page_entry_transition.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/app_hamburger_button.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/platform/native_io.dart';
import 'sla_scraper_controller.dart';
import '../../../ticket/presentation/widgets/custom_calendar_popup.dart';
import '../../../settings/presentation/settings_widgets.dart';

class SlaScraperPage extends StatefulWidget {
  const SlaScraperPage({super.key});

  @override
  State<SlaScraperPage> createState() => _SlaScraperPageState();
}

class _SlaScraperPageState extends State<SlaScraperPage> {
  final SlaScraperController _controller = SlaScraperController.instance;
  final ScrollController _logScrollController = ScrollController();
  final ScrollController _fileScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);

    // Inisialisasi data non-blocking setelah page dirender
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.init();
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _logScrollController.dispose();
    _fileScrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
      // Auto scroll ke bawah di console log jika sedang running
      if (_controller.isRunning && _logScrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_logScrollController.hasClients) {
            _logScrollController.animateTo(
              _logScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  Future<void> _pickStartDate(SlaScraperController controller) async {
    if (controller.isRunning) return;
    final picked = await CustomCalendarPopup.show(
      context: context,
      initialDate: controller.startDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.setStartDate(picked);
    }
  }

  Future<void> _pickEndDate(SlaScraperController controller) async {
    if (controller.isRunning) return;
    final picked = await CustomCalendarPopup.show(
      context: context,
      initialDate: controller.endDate,
      firstDate: controller.startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.setEndDate(picked);
    }
  }

  Future<void> _openFile(File file) async {
    try {
      await Process.run('cmd.exe', [
        '/c',
        'start',
        '""',
        file.path,
      ], runInShell: true);
      CustomSnackBar.success('Membuka file: ${file.path.split('\\').last}');
    } catch (e) {
      CustomSnackBar.error('Gagal membuka file: $e');
    }
  }

  Future<void> _openFolder(File file) async {
    try {
      await Process.run('explorer.exe', ['/select,', file.path]);
    } catch (e) {
      CustomSnackBar.error('Gagal membuka folder: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: PageEntryTransition(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.pagePaddingH,
                  context.scaledPadding(20),
                  context.pagePaddingH,
                  40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Warning Kredensial ──
                    if (!controller.credentialsExist) ...[
                      _buildAlertBanner(
                        message:
                            'Harap lengkapi Kredensial Login SLA di menu Pengaturan & Sistem -> Setting terlebih dahulu sebelum men-generate.',
                        color: context.dangerColor,
                        icon: Icons.error_outline_rounded,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Section 1: Konfigurasi ──
                    const SectionHeader(
                      title: "PARAMETER REKAP",
                      icon: Icons.settings_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildFormCard(controller),
                    const SizedBox(height: 24),

                    // ── Section 2: Console Log ──
                    if (controller.logLines.isNotEmpty ||
                        controller.isRunning) ...[
                      const SectionHeader(
                        title: "PROSES GENERATE LOGS",
                        icon: Icons.terminal_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildConsoleCard(controller),
                      const SizedBox(height: 24),
                    ],

                    // ── Section 3: Riwayat File ──
                    const SectionHeader(
                      title: "DAFTAR FILE HASIL GENERATE",
                      icon: Icons.folder_open_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildHistoryCard(controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
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
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: context.accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: context.accentColor.withOpacity(0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "REKAP SLA / DISPENSASI",
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              Text(
                "Laporan SLA Toko — Reporting",
                style: TextStyle(color: context.textSecondary, fontSize: 10),
              ),
            ],
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

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── Form Card Widget ──────────────────────────────────────────
  Widget _buildFormCard(SlaScraperController controller) {
    final df = DateFormat('dd/MM/yyyy');
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsResponsiveRow(
            threshold: 720,
            children: [
              // Tanggal Awal Field
              Expanded(
                child: _buildDateButton(
                  label: "TANGGAL AWAL",
                  value: df.format(controller.startDate),
                  onTap: () => _pickStartDate(controller),
                  disabled: controller.isRunning,
                ),
              ),
              const SizedBox(width: 16),
              // Tanggal Akhir Field
              Expanded(
                child: _buildDateButton(
                  label: "TANGGAL AKHIR",
                  value: df.format(controller.endDate),
                  onTap: () => _pickEndDate(controller),
                  disabled: controller.isRunning,
                ),
              ),
              const SizedBox(width: 16),
              // Tipe Laporan Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TIPE LAPORAN",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: context.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.borderColor.withOpacity(0.5),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: controller.reportType,
                          dropdownColor: context.cardColor,
                          isDense: true,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: controller.isRunning
                                ? context.textSecondary.withOpacity(0.5)
                                : context.accentColor,
                            size: 16,
                          ),
                          style: TextStyle(
                            color: context.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'dispensasi',
                              child: Text('Rekap Dispensasi'),
                            ),
                            DropdownMenuItem(
                              value: 'detail-cabang',
                              child: Text('Rekap Cabang'),
                            ),
                          ],
                          onChanged: controller.isRunning
                              ? null
                              : (val) {
                                  if (val != null) {
                                    controller.setReportType(val);
                                  }
                                },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Inline Warning jika retensi >4 hari
          if (controller.hasRetentionWarning) ...[
            const SizedBox(height: 14),
            _buildAlertBanner(
              message:
                  'Peringatan: Tanggal Awal lebih dari 4 hari lalu. Riwayat detail down time untuk tanggal ini mungkin sudah tidak tersedia di web probing.',
              color: context.warningColor,
              icon: Icons.warning_amber_rounded,
            ),
          ],

          const SizedBox(height: 20),

          // Row Button Aksi
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      (!controller.credentialsExist || controller.isRunning)
                      ? null
                      : () => controller.startScraping(),
                  icon: controller.isRunning
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.primaryColor,
                          ),
                        )
                      : Icon(
                          Icons.flash_on_rounded,
                          color: context.primaryColor,
                          size: 16,
                        ),
                  label: Text(
                    controller.isRunning
                        ? 'Memproses Scraper...'
                        : 'Jalankan Scraper',
                    style: TextStyle(
                      color: context.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.accentColor,
                    disabledBackgroundColor: context.accentColor.withOpacity(
                      0.3,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              if (controller.isRunning) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => controller.cancelScraping(),
                  icon: const Icon(
                    Icons.cancel_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: const Text(
                    'Batalkan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.dangerColor,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required String value,
    required VoidCallback onTap,
    bool disabled = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: context.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: context.primaryColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.borderColor.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: disabled
                        ? context.textSecondary
                        : context.textPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: disabled
                      ? context.textSecondary.withOpacity(0.5)
                      : context.accentColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertBanner({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Console Log Widget ────────────────────────────────────────
  Widget _buildConsoleCard(SlaScraperController controller) {
    final color = controller.isRunning
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
          // Console Header Tabs
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
                "SCRAPER OUTPUT CONSOLE",
                style: TextStyle(
                  color: context.textPrimary.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              Text(
                controller.isRunning ? "RUNNING" : "COMPLETED",
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

          // Log terminal list
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
                itemCount: controller.logLines.length,
                itemBuilder: (context, index) {
                  return _buildConsoleLine(context, controller.logLines[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleLine(BuildContext context, String line) {
    // Pola regex untuk mendeteksi: optional timestamp, lalu [TAG], lalu pesan
    final regex = RegExp(
      r'^(.*?\s)?\[(INFO|WARNING|ERROR|SYSTEM|SUCCESS|info|warning|error|system|success)\](.*)$',
      caseSensitive: false,
    );
    final match = regex.firstMatch(line);

    if (match != null) {
      final timestamp = match.group(1) ?? '';
      final tag = match.group(2)!.toUpperCase();
      final message = match.group(3)!;

      Color tagColor;
      switch (tag) {
        case 'INFO':
          tagColor = const Color(0xFF00E5FF); // Soft cyan/blue
          break;
        case 'SYSTEM':
          tagColor = context.accentColor;
          break;
        case 'SUCCESS':
          tagColor = context.successColor;
          break;
        case 'WARNING':
          tagColor = context.warningColor;
          break;
        case 'ERROR':
          tagColor = context.dangerColor;
          break;
        default:
          tagColor = context.textSecondary;
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: context.textPrimary.withOpacity(0.85),
            ),
            children: [
              if (timestamp.isNotEmpty)
                TextSpan(
                  text: timestamp,
                  style: TextStyle(color: context.textSecondary.withOpacity(0.6)),
                ),
              TextSpan(
                text: '[$tag]',
                style: TextStyle(
                  color: tagColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: message,
              ),
            ],
          ),
        ),
      );
    }

    // Fallback jika format tidak menggunakan tag
    Color color = context.textPrimary.withOpacity(0.85);
    bool isBold = false;

    if (line.startsWith('OK -') || line.startsWith('OK \u2014')) {
      color = context.successColor;
      isBold = true;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        line,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  // ── History Card Widget ────────────────────────────────────────
  Widget _buildHistoryCard(SlaScraperController controller) {
    if (controller.generatedFiles.isEmpty) {
      return _buildCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Icon(
                  Icons.folder_off_outlined,
                  size: 32,
                  color: context.textSecondary.withOpacity(0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum ada berkas laporan ter-generate',
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final listContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < controller.generatedFiles.length; i++) ...[
          if (i > 0)
            Divider(color: context.borderColor.withOpacity(0.5), height: 16),
          _buildFileItemRow(controller.generatedFiles[i]),
        ],
      ],
    );

    final showScroll = controller.generatedFiles.length > 5;

    return _buildCard(
      child: showScroll
          ? ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: Scrollbar(
                controller: _fileScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _fileScrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(right: 12),
                  child: listContent,
                ),
              ),
            )
          : listContent,
    );
  }

  Widget _buildFileItemRow(SlaGeneratedFile fileData) {
    final fileName = fileData.name;
    final isDispensasi = fileData.isDispensasi;

    // Formatting date modified (pre-computed in controller)
    final formatFmt = DateFormat('dd/MM/yyyy HH:mm');
    final timeStr = formatFmt.format(fileData.modified.toLocal());

    // Formatting size (pre-computed in controller)
    final sizeKb = (fileData.sizeInBytes / 1024).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.table_chart_rounded,
              size: 18,
              color: context.accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$timeStr \u2022 $sizeKb KB',
                  style: TextStyle(color: context.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Badge Tipe (Moved here to align with action buttons)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2.5,
            ),
            decoration: BoxDecoration(
              color:
                  (isDispensasi
                          ? Colors.purpleAccent
                          : Colors.tealAccent)
                      .withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color:
                    (isDispensasi
                            ? Colors.purpleAccent
                            : Colors.tealAccent)
                        .withOpacity(0.2),
              ),
            ),
            child: Text(
              isDispensasi ? 'Dispensasi' : 'Cabang',
              style: TextStyle(
                color: isDispensasi
                    ? Colors.purple.shade300
                    : Colors.teal.shade300,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Action Buka File
          IconButton(
            icon: Icon(
              Icons.open_in_new_rounded,
              size: 20,
              color: context.accentColor,
            ),
            tooltip: 'Buka File Excel',
            onPressed: () => _openFile(fileData.file),
            splashRadius: 22,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
          // Action Buka Folder
          IconButton(
            icon: Icon(
              Icons.folder_shared_outlined,
              size: 20,
              color: context.textSecondary,
            ),
            tooltip: 'Tampilkan di Folder',
            onPressed: () => _openFolder(fileData.file),
            splashRadius: 22,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
        ],
      ),
    );
  }
}
