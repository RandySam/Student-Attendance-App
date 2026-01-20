import 'package:flutter/material.dart';
import 'student_service.dart';
import 'otp_verification_screen.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({Key? key}) : super(key: key);

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nimController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final StudentService _studentService = StudentService();
  bool _isLoading = false;

  static const Color primaryColor = Color(0xFF0090D1);
  static const Color pageBackground = Color(0xFFF5F7FB);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nimController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    // PANGGIL API REGISTRASI
    final response = await _studentService.register(
      name: _nameController.text,
      nim: _nimController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    // Cek di debug log
    // print("Register response: $response");

    // --- JANGAN PAKAI response.message DULU ---
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("OTP terkirim, silakan cek email!"),
        backgroundColor: Colors.green,
      ),
    );

    // Pindah ke halaman OTP
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpVerificationScreen(
          email: _emailController.text,
        ),
      ),
    );
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
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}


  // Helper decoration biar konsisten
  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Register Akun',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              // Paksa tinggi minimal = tinggi layar yang tersedia
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center( // center secara vertikal & horizontal
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),

                        const Text(
                          'Buat Akun Baru',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Isi data diri kamu dengan benar untuk melanjutkan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 20),

                        Card(
                          elevation: 5,
                          shadowColor: primaryColor.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 22),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // === Name ===
                                  TextFormField(
                                    controller: _nameController,
                                    enabled: !_isLoading,
                                    decoration: _inputDecoration(
                                      label: 'Name',
                                      hint: 'John Doe',
                                      icon: Icons.person_outline,
                                    ),
                                    validator: (v) =>
                                        v == null || v.isEmpty
                                            ? 'Nama tidak boleh kosong'
                                            : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // === Email ===
                                  TextFormField(
                                    controller: _emailController,
                                    enabled: !_isLoading,
                                    decoration: _inputDecoration(
                                      label: 'Email',
                                      hint: 'contoh@gmail.com',
                                      icon: Icons.email_outlined,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Email tidak boleh kosong';
                                      }
                                      if (!v.contains('@')) {
                                        return 'Email tidak valid';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // === NIM ===
                                  TextFormField(
                                    controller: _nimController,
                                    enabled: !_isLoading,
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDecoration(
                                      label: 'NIM',
                                      hint: '2602191024',
                                      icon: Icons.badge_outlined,
                                    ),
                                    validator: (v) =>
                                        v == null || v.isEmpty
                                            ? 'NIM tidak boleh kosong'
                                            : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // === Password ===
                                  TextFormField(
                                    controller: _passwordController,
                                    enabled: !_isLoading,
                                    obscureText: true,
                                    decoration: _inputDecoration(
                                      label: 'Password',
                                      hint: 'Minimal 6 karakter',
                                      icon: Icons.lock_outline,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Password tidak boleh kosong';
                                      }
                                      if (v.length < 6) {
                                        return 'Password minimal 6 karakter';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // === Confirm Password ===
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    enabled: !_isLoading,
                                    obscureText: true,
                                    decoration: _inputDecoration(
                                      label: 'Confirm Password',
                                      hint: 'Ulangi password kamu',
                                      icon: Icons.lock_reset_outlined,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Mohon konfirmasi password';
                                      }
                                      if (v != _passwordController.text) {
                                        return 'Password tidak cocok';
                                      }
                                      return null;
                                    },
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                  ),
                                  const SizedBox(height: 26),

                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _register,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        disabledBackgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        elevation: 3,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Register',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
           ), 
          );
        },
      ),

    );
  }
}
