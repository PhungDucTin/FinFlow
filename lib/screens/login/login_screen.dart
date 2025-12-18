import 'package:flutter/material.dart';
import 'package:finflow/configs/constants.dart';
import 'package:finflow/services/auth_service.dart';
import 'package:finflow/screens/auth/sign_up_screen.dart';
import 'package:finflow/screens/auth/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String _currentLanguage = 'vi';

  // Đa ngôn ngữ
  final Map<String, Map<String, String>> _translations = {
    'vi': {
      'tagline': 'Quản lý chi tiêu cá nhân',
      'email': 'Email',
      'password': 'Mật khẩu',
      'forgotPassword': 'Quên mật khẩu', // Bỏ dấu ? cho gọn
      'signUp': 'Đăng ký',
      'login': 'Đăng nhập',
      'language': 'Tiếng Việt',
      'or': 'Hoặc',
    },
    'en': {
      'tagline': 'Personal Expense Management',
      'email': 'Email',
      'password': 'Password',
      'forgotPassword': 'Forgot Password',
      'signUp': 'Sign Up',
      'login': 'Login',
      'language': 'English',
      'or': 'Or',
    },
  };

  String get _t => _currentLanguage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleLanguage() {
    setState(() => _currentLanguage = _currentLanguage == 'vi' ? 'en' : 'vi');
  }

  @override
  Widget build(BuildContext context) {
    // Màu nền xanh mint nhạt giống mẫu (Rất quan trọng)
    const backgroundColor = Color(0xFFE0F2F1); 
    // Màu input field (xanh nhạt hơn nền một xíu hoặc trắng pha xanh)
    const inputFillColor = Colors.white; 

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center( // Căn giữa toàn màn hình
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. LOGO & TÊN APP
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    // Gradient cho logo đẹp hơn
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: const Icon(Icons.savings_outlined, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'FinFlow',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004D40), // Màu chữ đậm hơn primary chút cho rõ
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _translations[_t]!['tagline']!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.teal[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),

                // 2. FORM NHẬP LIỆU (Style mới: Filled Input)
                _buildModernInput(
                  controller: _emailController,
                  hint: _translations[_t]!['email']!,
                  icon: Icons.email,
                  fillColor: inputFillColor,
                ),
                const SizedBox(height: 16),
                _buildModernInput(
                  controller: _passwordController,
                  hint: _translations[_t]!['password']!,
                  icon: Icons.lock,
                  fillColor: inputFillColor,
                  isPassword: true,
                ),

                // 3. QUÊN MẬT KHẨU & ĐĂNG KÝ
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                        child: Text(
                          _translations[_t]!['forgotPassword']!,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
                        child: Text(
                          _translations[_t]!['signUp']!,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. NÚT ĐĂNG NHẬP (Solid Button)
                SizedBox(
                  width: double.infinity,
                  height: 55, // Nút cao hơn để dễ bấm
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, // Nền đặc
                      foregroundColor: Colors.white, // Chữ trắng
                      elevation: 5, // Đổ bóng
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _translations[_t]!['login']!,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 30),

                // 5. PHẦN SOCIAL LOGIN (Hoặc Google/Apple)
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[400])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _translations[_t]!['or']!,
                        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[400])),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildSocialButton(Icons.g_mobiledata, "Google", Colors.red)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSocialButton(Icons.apple, "Apple", Colors.black)),
                  ],
                ),

                const SizedBox(height: 30),

                // 6. NGÔN NGỮ (Tối giản)
                TextButton.icon(
                  onPressed: _toggleLanguage,
                  icon: const Icon(Icons.language, size: 20),
                  label: Text(_translations[_t]!['language']!),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget ô nhập liệu chuẩn Style mẫu
  Widget _buildModernInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color fillColor,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(icon, color: AppColors.primary),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none, // Bỏ viền mặc định
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // Widget nút Social
  Widget _buildSocialButton(IconData icon, String text, Color color) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}