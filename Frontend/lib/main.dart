import 'package:flutter/material.dart';
import 'login_selection_screen.dart';
import 'history_admin.dart'; // Pastikan file ini ada dan namanya benar

void main() {
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Binus Attendance',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      // Ganti ini ke MainAppWrapper jika ingin bypass login saat testing
      // Atau biarkan LoginSelectionScreen jika alur normal
      home: const LoginSelectionScreen(), 
      debugShowCheckedModeBanner: false,
    );
  }
}

// ============================================================
// WRAPPER UTAMA (NAVIGASI DISINI SAJA)
// ============================================================
class MainAppWrapper extends StatefulWidget {
  const MainAppWrapper({super.key});

  @override
  State<MainAppWrapper> createState() => _MainAppWrapperState();
}

class _MainAppWrapperState extends State<MainAppWrapper> {
  int _currentIndex = 1; // Default ke Dashboard (Index 1 lebih umum)

  // Daftar Halaman
  final List<Widget> _screens = [
    // 0: Profile
    const Center(child: Text('Profile Screen: Coming Soon!')),
    // 1: Dashboard
    const DashboardScreen(),
    // 2: Riwayat (History)
    // Pastikan HistoryAdminScreen TIDAK mengembalikan Scaffold dengan BottomNavBar lagi
    const HistoryAdminScreen(), 
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar Global
      appBar: AppBar(
        toolbarHeight: 80, // Sedikit lebih tinggi agar lega
        backgroundColor: const Color(0xFF007BFF),
        title: Row(
          children: [
            const Icon(Icons.access_time_filled, color: Colors.white, size: 32),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("BINUS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Text("ATTENDANCE", style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
           IconButton(onPressed: (){}, icon: const Icon(Icons.logout, color: Colors.white)),
        ],
        automaticallyImplyLeading: false,
      ),
      
      // Body sesuai index
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      
      // Bottom Nav Bar (Satu-satunya)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF007BFF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Agar icon tidak bergeser
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
        ],
      ),
    );
  }
}

// ============================================================
// DASHBOARD SCREEN (DUMMY DATA)
// ============================================================
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Helper Cell
  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.black : Colors.black87,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Data Dummy
    final List<Map<String, String>> attendanceData = [
      {'clock_in': '08:00', 'clock_out': '17:00', 'tanggal': '20/10/25', 'status': 'Present'},
      {'clock_in': '08:30', 'clock_out': '17:00', 'tanggal': '19/10/25', 'status': 'Late'},
      {'clock_in': '08:00', 'clock_out': '17:00', 'tanggal': '18/10/25', 'status': 'Present'},
      {'clock_in': '-', 'clock_out': '-', 'tanggal': '17/10/25', 'status': 'Absent'},
      {'clock_in': '08:00', 'clock_out': '18:00', 'tanggal': '16/10/25', 'status': 'Present'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Card Tabel
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ringkasan Absensi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.filter_list, size: 16),
                        label: const Text('Filter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1.2),
                      3: FlexColumnWidth(1),
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(color: Color(0xFFE0E0E0)),
                        children: [
                          _buildTableCell('Clock In', isHeader: true),
                          _buildTableCell('Clock Out', isHeader: true),
                          _buildTableCell('Tanggal', isHeader: true),
                          _buildTableCell('Status', isHeader: true),
                        ],
                      ),
                      ...attendanceData.map((data) => TableRow(
                        children: [
                          _buildTableCell(data['clock_in']!),
                          _buildTableCell(data['clock_out']!),
                          _buildTableCell(data['tanggal']!),
                          _buildTableCell(data['status']!),
                        ],
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Summary Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Absent', 1, Colors.red),
                _buildSummaryItem('Late', 2, Colors.orange),
                _buildSummaryItem('Present', 3, Colors.green),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text("$count", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}