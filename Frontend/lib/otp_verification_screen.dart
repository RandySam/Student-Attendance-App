import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

// Import halaman Login (LoginScreen) dari file login_reg.dart
import 'login_reg.dart'; 

import '../student_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();

  final StudentService _studentService = StudentService();

  late Timer _timer;
  int _start = 60;
  bool _canResend = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    setState(() {
      _canResend = false;
      _start = 60;
    });
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        if (_start == 0) {
          if (mounted) {
            setState(() {
              _canResend = true;
              timer.cancel();
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _start--;
            });
          }
        }
      },
    );
  }

  // --- FUNGSI VERIFIKASI OTP YANG SUDAH DIPERBAIKI ---
  Future<void> _verifyOtp(String pin) async {
    if (pin.length < 6) return;

    setState(() => _isLoading = true);

    try {
      // 1. Panggil API Verify (Sekarang return boolean true/exception)
      await _studentService.verifyOtp(
        email: widget.email,
        otp: pin
      );

      if (mounted) {
        // 2. Tampilkan Snackbar HIJAU (Sukses)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verifikasi Berhasil! Silakan Login.'),
            backgroundColor: Colors.green, // WARNA HIJAU
            duration: Duration(seconds: 2),
          ),
        );

        // Beri jeda 1 detik agar user sempat membaca pesan
        await Future.delayed(const Duration(milliseconds: 1000));

        // 3. Pindah ke Halaman Login (LoginScreen)
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            // Pastikan class LoginScreen ada di dalam file 'login_reg.dart'
            MaterialPageRoute(builder: (context) => const LoginScreen()), 
            (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      // 4. Jika Gagal -> Tampilkan Snackbar MERAH
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
        _pinController.clear(); // Hapus inputan agar user bisa mencoba lagi
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResend() async {
    setState(() => _isLoading = true);
    try {
      await _studentService.resendOtp(email: widget.email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode OTP baru telah dikirim ke email.'),
            backgroundColor: Colors.green,
          ),
        );
        startTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  @override
Widget build(BuildContext context) {
  final defaultPinTheme = PinTheme(
    width: 56,
    height: 60,
    textStyle: const TextStyle(
      fontSize: 22,
      color: Color(0xFF333333),
      fontWeight: FontWeight.w600,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F9FE),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE0E0E0)),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.05),
          spreadRadius: 1,
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
  );

  final focusedPinTheme = defaultPinTheme.copyDecorationWith(
    border: Border.all(color: const Color(0xFF0090D1), width: 2),
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0090D1).withOpacity(0.18),
        blurRadius: 10,
        spreadRadius: 2,
        offset: const Offset(0, 4),
      ),
    ],
  );

  final submittedPinTheme = defaultPinTheme.copyWith(
    decoration: defaultPinTheme.decoration!.copyWith(
      color: const Color(0xFFF0FDF4),
      border: Border.all(color: Colors.green),
    ),
  );

  return Scaffold(
    backgroundColor: const Color(0xFFF5F7FB),
    body: SafeArea(
      child: Column(
        children: [
          // ===== HEADER GRADIENT =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0090D1), Color(0xFF00B4FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          "Verifikasi OTP",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // untuk balance row
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Keamanan akun kamu adalah prioritas kami',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // ===== BODY DALAM CARD =====
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Card(
                    elevation: 5,
                    shadowColor: const Color(0xFF0090D1).withOpacity(0.18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE3F2FD),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                height: 48,
                                errorBuilder: (c, e, s) => const Icon(
                                  Icons.lock_outline,
                                  size: 48,
                                  color: Color(0xFF0090D1),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Masukkan Kode Verifikasi",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 10),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              text:
                                  "Kode 6 digit telah dikirimkan ke email\n",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                height: 1.5,
                              ),
                              children: [
                                TextSpan(
                                  text: widget.email,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // PIN INPUT
                          Pinput(
                            length: 6,
                            controller: _pinController,
                            focusNode: _focusNode,
                            defaultPinTheme: defaultPinTheme,
                            focusedPinTheme: focusedPinTheme,
                            submittedPinTheme: submittedPinTheme,
                            showCursor: true,
                            enabled: !_isLoading,
                            pinputAutovalidateMode:
                                PinputAutovalidateMode.onSubmit,
                            onCompleted: (pin) => _verifyOtp(pin),
                          ),

                          const SizedBox(height: 28),

                          // Tombol Verifikasi
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _verifyOtp(_pinController.text),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0090D1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Verifikasi',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Teks resend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Belum menerima kode? ",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                              _canResend
                                  ? GestureDetector(
                                      onTap:
                                          _isLoading ? null : _handleResend,
                                      child: const Text(
                                        "Kirim Ulang",
                                        style: TextStyle(
                                          color: Color(0xFF0090D1),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      "Tunggu ${_start}s",
                                      style: const TextStyle(
                                        color: Color(0xFF0090D1),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

}