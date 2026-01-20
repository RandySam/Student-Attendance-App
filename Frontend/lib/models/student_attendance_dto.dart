class StudentAttendanceDTO {
  final String studentNim;
  final String studentName;
  final String attendanceDate;
  final String? clockIn;  // Bisa null jika belum absen
  final String? clockOut; // Bisa null jika belum pulang
  final String status;    // "Hadir", "Telat", "Alpha"

  StudentAttendanceDTO({
    required this.studentNim,
    required this.studentName,
    required this.attendanceDate,
    required this.clockIn,
    required this.clockOut,
    required this.status,
  });

  factory StudentAttendanceDTO.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceDTO(
      studentNim: json['studentNim'] ?? '',
      studentName: json['studentName'] ?? '',
      attendanceDate: json['attendanceDate'] ?? '',
      clockIn: json['clockIn'],
      clockOut: json['clockOut'],
      status: json['status'] ?? 'Absent',
    );
  }
}