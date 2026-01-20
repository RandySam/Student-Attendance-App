class StudentProfileDTO {
  final String studentNim;
  final String studentName;
  final String studentEmail;
  final String? studentTelephone;
  final String? studentAddress;
  final String? studentMajor;

  StudentProfileDTO({
    required this.studentNim,
    required this.studentName,
    required this.studentEmail,
    this.studentTelephone,
    this.studentAddress,
    this.studentMajor,
  });

  factory StudentProfileDTO.fromJson(Map<String, dynamic> json) {
    return StudentProfileDTO(
      studentNim: json['studentNim'] ?? '',
      studentName: json['studentName'] ?? '',
      studentEmail: json['studentEmail'] ?? '',
      studentTelephone: json['studentTelephone'],
      studentAddress: json['studentAddress'],
      studentMajor: json['studentMajor'],
    );
  }
}