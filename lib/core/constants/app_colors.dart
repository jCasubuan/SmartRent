import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const primary = Color(0xFFC79F1D);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const textDark  = Color(0xFF2C2C2C);
  static const textMid   = Color(0xFF666666);
  static const textLight = Color(0xFF999999);

  // ── Input ─────────────────────────────────────────────────────────────────
  static const inputHint = Color(0xFFBBBBBB);

  // ── Borders ───────────────────────────────────────────────────────────────
  static const border = Color(0xFFE0E0E0);

  // ── Backgrounds ───────────────────────────────────────────────────────────
  /// Pure white — default scaffold / card background
  static const background = Colors.white;

  /// Light grey — used for search bars, input containers, stat cards, image placeholders
  static const surfaceGrey = Color(0xFFF5F5F5);

  /// Slightly darker grey — used for admin badge chip background
  static const surfaceMidGrey = Color(0xFFF0F0F0);

  /// Warm cream — used for measurement grid cells in gown detail
  static const surfaceCream = Color(0xFFF9F6EC);

  // ── Foreground on coloured surfaces ───────────────────────────────────────
  /// White text / icons on primary or dark backgrounds
  static const defaultForeground = Colors.white;

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const error        = Colors.redAccent;
  static const errorHighlight = Colors.redAccent; // alias kept for compatibility

  // ── Overlay / scrim ───────────────────────────────────────────────────────
  /// Semi-transparent black used for image overlays (back button circle, counter badge)
  static const Color overlayDark   = Color(0x59000000); // black @ 35 %
  static const Color overlayDarker = Color(0x73000000); // black @ 45 %
  static const Color overlayModal  = Color(0x4D000000); // black @ 30 %

  // ── Gown status colours ───────────────────────────────────────────────────
  static const statusAvailable = primary;
  static const statusReserved  = Color(0xFFBDBDBD); // light grey — reserved/unavailable
  static const statusRented    = Color(0xFF757575); // dark grey — physically rented out
  static const statusCleaning  = Color(0xFF2196F3); // blue
  static const statusRepair    = Color(0xFFF44336); // red

  // ── Rental request status colours ────────────────────────────────────────
  static const rentalPending   = Color(0xFFC79F1D); // gold — same as primary
  static const rentalApproved  = Color(0xFF4CAF50); // green
  static const rentalPickedUp  = Color(0xFF2196F3); // blue
  static const rentalDeclined  = Color(0xFFF44336); // red
  static const rentalCancelled = Color(0xFF9E9E9E); // grey
  static const rentalCompleted = Color(0xFF8BC34A); // light green
  static const rentalNoShow    = Color(0xFFFF9800); // orange

  /// Returns the colour for a given rental status string.
  static Color rentalStatusColor(String status) {
    return switch (status) {
      'pending'   => rentalPending,
      'approved'  => rentalApproved,
      'picked_up' => rentalPickedUp,
      'rejected'  => rentalDeclined,
      'cancelled' => rentalCancelled,
      'completed' => rentalCompleted,
      'no_show'   => rentalNoShow,
      _           => rentalPending,
    };
  }

  /// Returns the display label for a given rental status string.
  static String rentalStatusLabel(String status) {
    return switch (status) {
      'pending'   => 'PENDING',
      'approved'  => 'APPROVED',
      'picked_up' => 'PICKED UP',
      'rejected'  => 'DECLINED',
      'cancelled' => 'CANCELLED',
      'completed' => 'COMPLETED',
      'no_show'   => 'NO SHOW',
      _           => status.toUpperCase(),
    };
  }

  /// Returns the colour for a given gown status string.
  static Color gownStatusColor(String status) {
    return switch (status) {
      'available' => statusAvailable,
      'reserved'  => statusReserved,
      'rented'    => statusRented,
      'cleaning'  => statusCleaning,
      'repair'    => statusRepair,
      _           => statusAvailable,
    };
  }

  /// Returns the display label for a given gown status string.
  static String gownStatusLabel(String status) {
    return switch (status) {
      'available' => 'AVAILABLE',
      'reserved'  => 'UNAVAILABLE',
      'rented'    => 'RENTED',
      'cleaning'  => 'CLEANING',
      'repair'    => 'REPAIR',
      _           => status.toUpperCase(),
    };
  }
}
