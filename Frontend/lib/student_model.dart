// 1. Model untuk data yang DIKIRIM ke server (Request)
// Cocok dengan: StudentRegisterRequestDTO.java
class StudentRegisterRequest {
  final String nim;
  final String email;
  final String password;
  // Tambahkan 'name' jika di DTO Java Anda ada field 'name'
  // final String name; 

  StudentRegisterRequest({
    required this.nim,
    required this.email,
    required this.password,
  });

  // Mengubah objek menjadi JSON
  Map<String, dynamic> toJson() {
    return {
      'nim': nim,
      'email': email,
      'password': password,
    };
  }
}

// 2. Model untuk data yang DITERIMA dari server (Response)
// Cocok dengan: StudentResponseDTO.java
class StudentResponse {
  final String? message;
  // Sesuaikan field ini dengan isi StudentResponseDTO Java Anda.
  // Biasanya ada flag sukses/gagal atau data object.
  // Contoh asumsi saya: ada field 'message' dan mungkin 'success' atau 'status'.
  
  StudentResponse({this.message});

  factory StudentResponse.fromJson(Map<String, dynamic> json) {
    return StudentResponse(
      message: json['message'], // Pastikan key JSON-nya sama persis dengan Java
    );
  }
}