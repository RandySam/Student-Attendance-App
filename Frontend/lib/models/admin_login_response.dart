class AdminLoginResponse {
  final String? token; // <-- TAMBAHKAN TANDA TANYA (?)
  final String? message; // Tambahkan field lain jika ada (opsional)

  AdminLoginResponse({
    this.token, // <-- Hapus 'required'
    this.message,
  });

  factory AdminLoginResponse.fromJson(Map<String, dynamic> json) {
    return AdminLoginResponse(
      token: json['token'], // <-- Sekarang aman jika null
      message: json['message'], // <-- Sekarang aman jika null
    );
  }
}