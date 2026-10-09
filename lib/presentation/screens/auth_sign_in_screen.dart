import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Màn hình Đăng nhập tích hợp Firebase Authentication
/// Hỗ trợ: Google Sign-In, Email/Password (Đăng nhập & Đăng ký), Anonymous (Khách) & GitHub
class AuthSignInScreen extends StatefulWidget {
  const AuthSignInScreen({super.key});

  @override
  State<AuthSignInScreen> createState() => _AuthSignInScreenState();
}

class _AuthSignInScreenState extends State<AuthSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
        if (loading) _errorMessage = null;
      });
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found' => 'Không tìm thấy tài khoản với email này.',
      'wrong-password' => 'Mật khẩu không chính xác. Vui lòng thử lại.',
      'email-already-in-use' => 'Email này đã được đăng ký tài khoản trước đó.',
      'invalid-email' => 'Địa chỉ email không đúng định dạng.',
      'weak-password' => 'Mật khẩu quá ngắn. Vui lòng nhập tối thiểu 6 ký tự.',
      'network-request-failed' => 'Lỗi kết nối mạng. Vui lòng kiểm tra lại đường truyền.',
      'popup-closed-by-user' => 'Cửa sổ đăng nhập đã bị đóng trước khi hoàn tất.',
      _ => e.message ?? 'Đã xảy ra lỗi khi xác thực (${e.code}).',
    };
  }

  /// 1. Đăng nhập / Đăng ký qua Email & Password
  Future<void> _submitEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;
    _setLoading(true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isSignUp) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMessage = _mapFirebaseError(e));
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Lỗi không xác định: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 2. Đăng nhập với Google
  Future<void> _signInWithGoogle() async {
    _setLoading(true);

    try {
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');

      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        await FirebaseAuth.instance.signInWithProvider(provider);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMessage = _mapFirebaseError(e));
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Không thể đăng nhập Google: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 3. Đăng nhập nhanh (Anonymous / Trải nghiệm ngay)
  Future<void> _signInAnonymously() async {
    _setLoading(true);

    try {
      await FirebaseAuth.instance.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMessage = _mapFirebaseError(e));
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Lỗi đăng nhập nhanh: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 4. Đăng nhập với GitHub
  Future<void> _signInWithGitHub() async {
    _setLoading(true);

    try {
      final provider = GithubAuthProvider();
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        await FirebaseAuth.instance.signInWithProvider(provider);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMessage = _mapFirebaseError(e));
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Không thể đăng nhập GitHub: $e');
    } finally {
      _setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppTheme.border, width: 1.5),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo & Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 42,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Study Document Manager',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isSignUp
                            ? 'Tạo tài khoản sinh viên mới để lưu trữ dữ liệu'
                            : 'Đăng nhập để đồng bộ và truy cập tài liệu học tập',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Thông báo lỗi nếu có
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppTheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppTheme.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Ô nhập Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email sinh viên',
                          hintText: 'sinhvien@school.edu.vn',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập email.';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Email không hợp lệ.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Ô nhập Mật khẩu
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          hintText: 'Tối thiểu 6 ký tự',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu.';
                          }
                          if (value.length < 6) {
                            return 'Mật khẩu phải từ 6 ký tự trở lên.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Nút Đăng nhập / Đăng ký Email
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _submitEmailPassword,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isSignUp ? 'Đăng ký tài khoản' : 'Đăng nhập',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Chuyển đổi giữa Đăng nhập và Đăng ký
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() {
                                  _isSignUp = !_isSignUp;
                                  _errorMessage = null;
                                }),
                        child: Text(
                          _isSignUp
                              ? 'Đã có tài khoản? Đăng nhập ngay'
                              : 'Chưa có tài khoản? Tạo tài khoản mới',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Đường kẻ ngang "HOẶC"
                      const Row(
                        children: [
                          Expanded(child: Divider(color: AppTheme.border)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'HOẶC',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: AppTheme.border)),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Nút Đăng nhập với Google
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: Image.network(
                            'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                            width: 20,
                            height: 20,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.g_mobiledata_rounded,
                              size: 24,
                              color: Color(0xFFEA4335),
                            ),
                          ),
                          label: const Text(
                            'Tiếp tục với Google',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Hàng chứa 2 nút phụ: GitHub & Khách (Anonymous)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isLoading ? null : _signInWithGitHub,
                              icon: const Icon(Icons.code_rounded, size: 18),
                              label: const Text(
                                'GitHub',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isLoading ? null : _signInAnonymously,
                              icon: const Icon(Icons.flash_on_rounded, size: 18, color: Colors.amber),
                              label: const Text(
                                'Dùng ngay',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
