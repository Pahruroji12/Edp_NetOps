import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/custom_snackbar.dart';
import '../../domain/store_model.dart';
import '../controllers/store_form_controller.dart';
import '../widgets/store_form_sections.dart';

class StoreFormPage extends StatefulWidget {
  final StoreModel? store;

  const StoreFormPage({super.key, this.store});

  @override
  State<StoreFormPage> createState() => _StoreFormPageState();
}

class _StoreFormPageState extends State<StoreFormPage> {
  late final StoreFormController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _animationsReady = false;

  @override
  void initState() {
    super.initState();
    _controller = StoreFormController(existingStore: widget.store);
    _controller.init();
    _controller.addListener(_onControllerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animationsReady = true);
    });
  }

  void _onControllerChanged() {
    // 1. Tangani notifikasi snackbar
    final notif = _controller.pendingNotification;
    if (notif != null) {
      CustomSnackBar.show(context, notif.message, notif.color);
      _controller.clearNotification();
    }

    // 2. Jika berhasil disimpan, pop page
    if (_controller.savedSuccessfully && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.primaryColor,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return _buildLoadingState();
          }

          return AnimatedOpacity(
            opacity: _animationsReady ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          StoreFormInfoSection(controller: _controller),
                          const SizedBox(height: 20),
                          StoreFormIpSection(controller: _controller),
                          const SizedBox(height: 24),
                          _buildSaveButton(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
              _controller.isEdit ? "MENYIMPAN PERUBAHAN..." : "MENAMBAHKAN TOKO...",
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: context.cardColor,
      elevation: 0,
      iconTheme: IconThemeData(color: context.textPrimary),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _controller.isEdit ? "Edit Data Toko" : "Tambah Toko Baru",
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            _controller.isEdit
                ? "${widget.store!.storeCode} — ${widget.store!.storeName}"
                : "Isi informasi dan data IP toko",
            style: TextStyle(color: context.textSecondary, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: context.accentColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _controller.saveData(_formKey),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.accentColor,
                  context.accentColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _controller.isEdit ? Icons.save_outlined : Icons.add_circle_outline,
                  color: context.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  _controller.isEdit ? "Simpan Perubahan" : "Simpan Toko Baru",
                  style: TextStyle(
                    color: context.primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
