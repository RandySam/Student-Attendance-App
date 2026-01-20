import 'package:flutter/material.dart';
import 'student_service.dart'; // Sesuaikan path
import 'models/student_profile_dto.dart'; // Sesuaikan path
import 'edit_profile_screen.dart'; // Halaman Edit
import 'user_main_screen.dart'; // Jika suatu saat mau dipakai

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StudentService _studentService = StudentService();

  StudentProfileDTO? _profileData;
  bool _isLoading = true;

  static const Color primaryColor = Color(0xFF0090D1);
  static const Color pageBackground = Color(0xFFF5F7FB);

  // PNG logo aplikasi (topi)
  static const String appLogoPath = 'assets/images/Binus_Attendance.png';

  // PNG avatar default (optional, bisa pakai sama seperti edit profile)
  static const String defaultAvatarPath = 'assets/images/profile_avatar.png';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final profile = await _studentService.getProfile();
      if (!mounted) return;
      setState(() {
        _profileData = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal memuat profil: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToEditProfile() async {
    if (_profileData == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(profileData: _profileData!),
      ),
    );

    if (result != null && result is StudentProfileDTO) {
      setState(() {
        _profileData = result;
      });
      // Jika mau benar-benar sinkron dengan server setelah edit:
      // _loadProfileData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: PreferredSize(
  preferredSize: const Size.fromHeight(72),
  child: AppBar(
    backgroundColor: primaryColor,
    elevation: 0,
    centerTitle: false, // <-- MATIKAN CENTER
    titleSpacing: 0,    // <-- BIAR MELEKAT KE KIRI
    title: Padding(
      padding: const EdgeInsets.only(left: 16), // Jarak kecil dari kiri
      child: Image.asset(
        appLogoPath,
        height: 50, // PERBESAR LOGO
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => const Icon(
          Icons.school,
          color: Colors.white,
          size: 40,
        ),
      ),
    ),
    automaticallyImplyLeading: false,
  ),
),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profileData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Gagal memuat data."),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadProfileData,
                        child: const Text("Coba Lagi"),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfileData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildHeaderCard(),
                        const SizedBox(height: 20),
                        _buildDetailCard(),
                      ],
                    ),
                  ),
                ),
    );
  }

  /// Card atas: foto, nama, NIM, jurusan
  Widget _buildHeaderCard() {
    final profile = _profileData!;
    return Card(
      elevation: 6,
      shadowColor: primaryColor.withOpacity(0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          children: [
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 46,
                backgroundColor: Colors.white,
                backgroundImage: const AssetImage(defaultAvatarPath),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              profile.studentName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profile.studentNim,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profile.studentMajor ?? 'Jurusan belum diisi',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card bawah: email, telp, alamat + tombol edit
  Widget _buildDetailCard() {
    final p = _profileData!;
    return Card(
      elevation: 5,
      shadowColor: primaryColor.withOpacity(0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoTextField(
              'Email',
              p.studentEmail,
              Icons.email_outlined,
            ),
            const SizedBox(height: 16),
            _buildInfoTextField(
              'No. Telp',
              p.studentTelephone ?? '-',
              Icons.phone_outlined,
            ),
            const SizedBox(height: 16),
            _buildInfoTextField(
              'Alamat',
              p.studentAddress ?? '-',
              Icons.home_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _navigateToEditProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Edit Profil',
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
    );
  }

  Widget _buildInfoTextField(
    String label,
    String value,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          readOnly: true,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[700]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
