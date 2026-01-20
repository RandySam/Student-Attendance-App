// File: lib/screens/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'dart:async';

import 'history_admin.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color primaryColor = Color(0xFF0090D1);
  static const Color secondaryColor = Color(0xFF00B4FF);
  static const Color pageBackground = Color(0xFFF5F7FB);

  @override
  void initState() {
    super.initState();
    _navigateToHistory();
  }

  void _navigateToHistory() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HistoryAdminScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ====== HEADER GRADIENT ======
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SizedBox(height: 4),
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Mengambil data riwayat absensi...\nHarap tunggu sebentar.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 12),
                ],
              ),
            ),

            // ====== BODY CONTENT ======
            Expanded(
              child: Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Card(
                      elevation: 6,
                      shadowColor: primaryColor.withOpacity(0.25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 26),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon / ilustrasi
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 42,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Selamat Datang, Admin!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Sistem sedang menyiapkan data riwayat kehadiran '
                              'mahasiswa untuk Anda.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 26),

                            // Progress + text kecil
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: primaryColor,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Memuat riwayat absensi...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),
                            const Text(
                              'Anda akan diarahkan ke halaman riwayat otomatis.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
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

            // OPTIONAL: FOOTER KECIL
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                '© Binus Attendance Admin',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
