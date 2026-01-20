import 'package:binus_attendance/admin_login_screen.dart';
import 'package:binus_attendance/login_reg.dart';
import 'package:flutter/material.dart';

class LoginSelectionScreen extends StatelessWidget {
  const LoginSelectionScreen({super.key});

  static const Color primaryColor = Color(0xFF0090D1);

  Widget _buildHeader() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 48, bottom: 32),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0090D1), Color(0xFF00B4FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/Binus_Attendance.png',
              width: 300,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 75),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
    child: Column(
      children: [
        // Bagian ini yang bikin card di tengah
        Expanded(
          child: Center(
            child: Card(
              elevation: 6,
              shadowColor: primaryColor.withOpacity(0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Welcome to Binus Attendance',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Silakan pilih jenis login sesuai peran Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // --- BUTTON STUDENT ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.school_outlined),
                        label: const Text(
                          'Login as Student',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- BUTTON ADMIN ---
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.admin_panel_settings_outlined),
                        label: const Text(
                          'Login as Admin',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminLoginScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: primaryColor,
                            width: 1.5,
                          ),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Footer tetap di bawah
        const Text(
          '© Binus Attendance',
          style: TextStyle(
            fontSize: 11,
            color: Colors.black45,
          ),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }
}
