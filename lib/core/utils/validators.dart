class Validators {
  static String? email(String? val) {
    if (val == null || val.trim().isEmpty) return 'Email wajib diisi';
    if (!val.contains('@')) return 'Format email tidak valid';
    return null;
  }

  static String? password(String? val) {
    if (val == null || val.isEmpty) return 'Password wajib diisi';
    if (val.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  static String? required(String? val, String fieldName) {
    if (val == null || val.trim().isEmpty) return '$fieldName wajib diisi';
    return null;
  }
}
