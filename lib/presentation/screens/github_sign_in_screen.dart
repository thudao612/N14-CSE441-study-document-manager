import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GithubSignInScreen extends StatefulWidget {
  const GithubSignInScreen({super.key});

  @override
  State<GithubSignInScreen> createState() => _GithubSignInScreenState();
}

class _GithubSignInScreenState extends State<GithubSignInScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithGitHub() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = GithubAuthProvider();

      await FirebaseAuth.instance.signInWithPopup(provider);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = '${e.code}: ${e.message ?? 'Đăng nhập thất bại.'}';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Không thể đăng nhập: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu_book, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      'Study Document Manager',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Đăng nhập bằng GitHub để truy cập tài liệu học tập.',
                      textAlign: TextAlign.center,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _signInWithGitHub,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.code),
                        label: Text(
                          _isLoading
                              ? 'Đang đăng nhập...'
                              : 'Đăng nhập bằng GitHub',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
