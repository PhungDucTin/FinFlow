import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Client ID từ Firebase Console (Web Client ID)
  // Bạn cần lấy từ: Firebase Console > Authentication > Sign-in method > Google > Web SDK configuration
  // Hoặc: Google Cloud Console > APIs & Services > Credentials > OAuth 2.0 Client IDs (Web client)
  // TODO: Thay thế bằng Web Client ID từ Firebase project mới của bạn
  // Ví dụ: '835620235882-xxxxxxxxxxxxx.apps.googleusercontent.com'
  static const String _webClientId = '287157964374-4log7egirecln1307f2mtgvgnhpjkp7r.apps.googleusercontent.com'; // Cần cập nhật Web Client ID từ Firebase Console

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

  /// Đăng nhập với Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Kiểm tra Web Client ID trên web
      if (kIsWeb && _webClientId.isEmpty) {
        throw 'Web Client ID chưa được cấu hình. Vui lòng:\n'
            '1. Vào Firebase Console > Authentication > Sign-in method > Google\n'
            '2. Copy Web Client ID từ phần "Web SDK configuration"\n'
            '3. Cập nhật _webClientId trong lib/services/auth_service.dart\n'
            'Hoặc vào: Google Cloud Console > APIs & Services > Credentials > OAuth 2.0 Client IDs (Web client)';
      }

      // Khởi tạo GoogleSignIn với clientId (cho web) hoặc để null (cho mobile - tự động lấy từ google-services.json)
      // Chỉ request scope 'email' để tránh cần People API (nếu chưa bật)
      final GoogleSignIn googleSignIn = kIsWeb
          ? GoogleSignIn(
              clientId: _webClientId,
              scopes: ['email'], // Chỉ cần email, không cần profile để tránh People API
            )
          : GoogleSignIn(
              scopes: ['email'], // Chỉ cần email, không cần profile để tránh People API
            );

      // 1. Mở màn hình chọn tài khoản Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // Người dùng bấm Hủy
        throw 'Đăng nhập Google đã bị hủy.';
      }

      // 2. Lấy token xác thực từ Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Tạo credential cho Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Đăng nhập Firebase bằng credential
      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      // 5. Cập nhật displayName và photoURL từ Google nếu có (tùy chọn)
      if (userCredential.user != null && googleUser.displayName != null) {
        await userCredential.user?.updateDisplayName(googleUser.displayName);
        if (googleUser.photoUrl != null) {
          await userCredential.user?.updatePhotoURL(googleUser.photoUrl);
        }
        await userCredential.user?.reload();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Xử lý lỗi People API một cách thân thiện
      final errorString = e.toString();
      if (errorString.contains('People API') || errorString.contains('SERVICE_DISABLED')) {
        throw 'People API chưa được bật. Vui lòng bật tại:\nhttps://console.developers.google.com/apis/api/people.googleapis.com/overview?project=finflow-4c0ea\n\nHoặc xem hướng dẫn trong file GOOGLE_SIGNIN_SETUP.md';
      }
      throw 'Không thể đăng nhập bằng Google: $e';
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

  Future<void> updateDisplayName(String newName) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updateDisplayName(newName);
        await user.reload();
      }
    } catch (e) {
      throw 'Không thể cập nhật tên: $e';
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
