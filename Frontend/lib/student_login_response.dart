class StudentLoginResponse {
  final String? token;
  final String? message;
  // Tambahkan properti lain jika back-end Anda mengirimkannya
  // final Map<String, dynamic>? user; 

  StudentLoginResponse({
    this.token,
    this.message,
    // this.user,
  });

  // Factory constructor untuk mengubah JSON menjadi objek
  factory StudentLoginResponse.fromJson(Map<String, dynamic> json) {
    return StudentLoginResponse(
      // 'json['token']' akan otomatis bernilai null jika key 'token' tidak ada
      token: json['token'], 
      message: json['message'],
      // user: json['user'],
    );
  }
}