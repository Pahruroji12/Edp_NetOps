import 'package:flutter/material.dart';

/// globals.dart — key global yang dibutuhkan lintas layer.
///
/// Lokasi: core/globals.dart
///
/// Dipakai di:
///   - app/app.dart → scaffoldMessengerKey
///   - core/widgets/custom_snackbar.dart → CustomSnackBar.showFromKey(...)
///
final GlobalKey<ScaffoldMessengerState> globalMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
