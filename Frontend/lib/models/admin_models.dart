class StudentListItemDTO {
  final String nim;
  final String name;
  final String date;
  final String clockIn;
  final String clockOut;
  final String status;
  final String major; 

  StudentListItemDTO({
    required this.nim,
    required this.name,
    required this.date,
    required this.clockIn,
    required this.clockOut,
    required this.status,
    this.major = "-", 
  });

  factory StudentListItemDTO.fromJson(Map<String, dynamic> json) {
    // Cek apakah data 'student' ada di dalam JSON (Nested Object)
    // Backend Spring Boot Anda mengirimkan:
    // { "student": { "studentName": "...", "studentNim": "..." }, "clockIn": "...", ... }
    final studentData = json['student'] ?? {}; 

    return StudentListItemDTO(
      // 1. Ambil NIM & Nama dari dalam objek 'student'
      // Kita gunakan operator ?? berantai untuk jaga-jaga
      nim: (studentData['studentNim'] ?? studentData['nim'] ?? json['studentNim'] ?? '-').toString(),
      
      name: (studentData['studentName'] ?? studentData['name'] ?? json['studentName'] ?? '-').toString(),
      
      // Ambil Jurusan juga dari dalam objek 'student'
      major: (studentData['studentMajor'] ?? studentData['major'] ?? '-').toString(),

      // 2. Ambil data Absensi dari root JSON (bukan di dalam 'student')
      date: (json['attendanceDate'] ?? json['date'] ?? '-').toString(),
      
      clockIn: (json['clockIn'] ?? '-').toString(),
      
      clockOut: (json['clockOut'] ?? '-').toString(),
      
      status: (json['status'] ?? '-').toString(),
    );
  }
}

// Model Summary (Digunakan untuk Modal Detail Statistik)
class StudentSummaryDTO {
  final String name;
  final String nim;
  final String major;
  final int presentCount;
  final int lateCount;
  final int absentCount;

  StudentSummaryDTO({
    required this.name,
    required this.nim,
    required this.major,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
  });
  
}