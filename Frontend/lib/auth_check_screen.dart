import 'package:flutter/material.dart';

// 1. IMPORT SERVICE (Path sudah diperbaiki)
import 'service/admin_service.dart';
import 'student_service.dart';

// 2. IMPORT HALAMAN TUJUAN (Nama class sudah diperbaiki)
import 'admin_dashboard_screen.dart';
import 'user_main_screen.dart'; // Menggunakan UserMainScreen
import 'login_selection_screen.dart';

// -------------------------------------------------------------------
// BAGIAN 1: "BADAN" (STATEFULWIDGET) - Struktur sudah diperbaiki
// -------------------------------------------------------------------
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({Key? key}) : super(key: key);

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

// -------------------------------------------------------------------
// BAGIAN 2: "OTAK" (STATE) - Logika dan Build method sudah diperbaiki
// -------------------------------------------------------------------
class _AuthCheckScreenState extends State<AuthCheckScreen> {
  // Buat instance KEDUA service
  final AdminService _adminService = AdminService();
  final StudentService _studentService = StudentService();

  @override
  void initState() {
    super.initState();
    // Panggil fungsi pengecekan saat halaman dimuat
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Beri jeda sedikit agar loading spinner terlihat
    await Future.delayed(const Duration(milliseconds: 500));

    // Cek DULU apakah dia admin
    if (await _adminService.isAdminLoggedIn()) {
      if (!mounted) return; // Cek 'mounted' sebelum panggil Navigator
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      );
    }
    // JIKA BUKAN ADMIN, cek apakah dia mahasiswa
    else if (await _studentService.isLoggedIn()) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserMainScreen()), // Nama class sudah benar
      );
    }
    // JIKA BUKAN KEDUANYA, lempar ke halaman pilihan login
    else {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginSelectionScreen()),
      );
    }
  }

  // METHOD 'build' YANG WAJIB ADA (Sebelumnya hilang)
  @override
  Widget build(BuildContext context) {
    // Tampilkan loading spinner selagi logic di initState berjalan
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}