import 'package:flutter/material.dart';
// --- INI PERBAIKANNYA ---
import 'models/student_profile_dto.dart'; // Path sudah benar
import 'student_service.dart'; // Langsung dari lib
import 'user_main_screen.dart'; // Halaman Dashboard

class StudentUpdateProfileScreen extends StatefulWidget {
  const StudentUpdateProfileScreen({Key? key}) : super(key: key);

  @override
  _StudentUpdateProfileScreenState createState() =>
      _StudentUpdateProfileScreenState();
}

class _StudentUpdateProfileScreenState
    extends State<StudentUpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controller untuk SEMUA field
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nimController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _majorController = TextEditingController();

  final StudentService _studentService = StudentService();
  bool _isLoading = true; // Set true untuk loading awal

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }
  
  @override
  void dispose() {
    // Selalu dispose controllers Anda
    _nameController.dispose();
    _emailController.dispose();
    _nimController.dispose();
    _telephoneController.dispose();
    _addressController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  // --- FUNGSI UNTUK MENGAMBIL DATA SAAT HALAMAN DIBUKA ---
  Future<void> _loadProfileData() async {
    try {
      final profile = await _studentService.getProfile();
      
      // Set data ke controllers
      setState(() {
        _nameController.text = profile.studentName;
        _emailController.text = profile.studentEmail;
        _nimController.text = profile.studentNim;
        _telephoneController.text = profile.studentTelephone ?? '';
        _addressController.text = profile.studentAddress ?? '';
        _majorController.text = profile.studentMajor ?? '';
        
        _isLoading = false; // Sembunyikan loading
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) { // Cek 'mounted' sebelum panggil ScaffoldMessenger
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat data: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- FUNGSI UNTUK MENGIRIM (UPDATE) DATA ---
  Future<void> _handleUpdateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true; // Tampilkan loading
    });

    try {
      // Panggil service updateProfile
      await _studentService.updateProfile(
        telephone: _telephoneController.text,
        address: _addressController.text,
        major: _majorController.text,
      );

      // SUKSES!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Profil berhasil diperbarui!"),
            backgroundColor: Colors.green,
          ),
        );

        // Pindah ke Halaman Dashboard Utama
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserMainScreen()),
        );
      }
    } catch (e) {
      // GAGAL!
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
          _isLoading = false; // Sembunyikan loading
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update Profil"),
      ),
      // Tampilkan loading spinner di tengah jika _isLoading
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- DATA READ-ONLY ---
                    TextFormField(
                      controller: _nameController,
                      readOnly: true, // Tidak bisa diubah
                      decoration: InputDecoration(
                        labelText: "Name",
                        border: OutlineInputBorder(),
                        fillColor: Colors.grey[200],
                        filled: true,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      readOnly: true, // Tidak bisa diubah
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                        fillColor: Colors.grey[200],
                        filled: true,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _nimController,
                      readOnly: true, // Tidak bisa diubah
                      decoration: InputDecoration(
                        labelText: "NIM",
                        border: OutlineInputBorder(),
                        fillColor: Colors.grey[200],
                        filled: true,
                      ),
                    ),
                    SizedBox(height: 24),

                    // --- DATA YANG BISA DI-EDIT ---
                    TextFormField(
                      controller: _telephoneController,
                      enabled: !_isLoading, // Nonaktifkan saat loading
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Telephone",
                        hintText: "0812...",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Telepon tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      enabled: !_isLoading, // Nonaktifkan saat loading
                      decoration: InputDecoration(
                        labelText: "Address",
                        hintText: "Jl. Kebon Jeruk...",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Alamat tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _majorController,
                      enabled: !_isLoading, // Nonaktifkan saat loading
                      decoration: InputDecoration(
                        labelText: "Major",
                        hintText: "Teknik Informatika",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jurusan tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 32),

                    // Tombol Simpan
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleUpdateProfile,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading 
                        ? SizedBox(
                            height: 20, 
                            width: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                          )
                        : Text("Simpan Perubahan", style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}