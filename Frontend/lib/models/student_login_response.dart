class StudentLoginResponse {
  // Sesuai dengan DTO di back-end Anda
  final String? token;
  final String? studentEmail;
  
  // Ini untuk menangkap pesan error (misal: "Password salah")
  final String? message; 

  StudentLoginResponse({
    this.token,
    this.studentEmail,
    this.message,
  });

  // Factory constructor untuk mengubah JSON menjadi objek
  factory StudentLoginResponse.fromJson(Map<String, dynamic> json) {
    return StudentLoginResponse(
      token: json['token'],
      studentEmail: json['studentEmail'],
      message: json['message'], // Tangkap juga 'message' jika ada
    );
  }
}