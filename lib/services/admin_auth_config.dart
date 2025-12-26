class AdminAuthConfig {
  static const String adminEmail = "admin@ump.ac.ma";
  static const String adminPassword = "admin123";

  static bool isAdmin(String email, String password) {
    return email == adminEmail && password == adminPassword;
  }
}
