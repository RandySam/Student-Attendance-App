class StudentResponseDTO {
  // 'success' dan 'message' harus sesuai dengan DTO di back-end Anda
  final bool success;
  final String? message; 

  StudentResponseDTO({
    required this.success,
    required this.message,
  });

  // Factory constructor untuk mengubah JSON menjadi objek
  factory StudentResponseDTO.fromJson(Map<String, dynamic> json) {
    return StudentResponseDTO(
      success: json['success'] ?? false, // Beri default 'false' jika null
      message: json['message'] ?? "", // Ini aman jika null
    );
  }
}