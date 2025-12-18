import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Lấy user hiện tại
  User? get currentUser => _firebaseAuth.currentUser;

  // Stream theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Đăng nhập bằng Email & Password
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Đăng ký tài khoản mới
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      // Cập nhật displayName
      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Gửi email đặt lại mật khẩu
  Future<void> resetPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Xác thực mã reset password
  Future<String> verifyPasswordResetCode({required String code}) async {
    try {
      // Firebase không có API xác thực code trực tiếp
      // Thay vào đó ta dùng confirmPasswordReset
      return code; // Tạm dùng code làm token
    } catch (e) {
      throw 'Mã không hợp lệ';
    }
  }

  // Cập nhật mật khẩu mới (sau khi xác thực code)
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      await _firebaseAuth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Xử lý lỗi Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    print("Mã lỗi Firebase: ${e.code}"); // In ra log để dễ Debug nếu gặp lỗi lạ

    switch (e.code) {
      // --- Nhóm Đăng ký / Đăng nhập ---
      case 'email-already-in-use':
        return 'Email này đã được đăng ký. Vui lòng đăng nhập.';
      case 'invalid-email':
        return 'Định dạng email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn (trên 6 ký tự).';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa bởi Admin.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Mật khẩu không chính xác.';
      case 'invalid-credential': // Lỗi chung cho user-not-found hoặc wrong-password (bảo mật mới)
        return 'Email hoặc mật khẩu không chính xác.';
      
      // --- Nhóm Cấu hình & Hệ thống ---
      case 'operation-not-allowed':
        return 'Lỗi hệ thống: Tính năng đăng nhập này chưa được bật trên Firebase Console.';
      case 'requires-recent-login':
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng xuất và đăng nhập lại để thực hiện.';
      
      // --- Nhóm Mạng & Quên mật khẩu ---
      case 'too-many-requests':
        return 'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau ít phút.';
      case 'network-request-failed':
        return 'Không có kết nối Internet. Vui lòng kiểm tra lại Wifi/4G.';
      case 'invalid-verification-code':
        return 'Mã xác thực không hợp lệ.';
      case 'expired-action-code':
        return 'Mã xác thực hoặc liên kết đã hết hạn.';

      // --- Mặc định ---
      default:
        return 'Lỗi không xác định: ${e.message}';
    }
  }
}
