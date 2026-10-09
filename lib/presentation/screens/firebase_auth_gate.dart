import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../controllers/document_controller.dart';
import 'document_home_screen.dart';
import 'github_sign_in_screen.dart';

class FirebaseAuthGate extends StatefulWidget {
  final DocumentController controller;

  const FirebaseAuthGate({
    super.key,
    required this.controller,
  });

  @override
  State<FirebaseAuthGate> createState() => _FirebaseAuthGateState();
}

class _FirebaseAuthGateState extends State<FirebaseAuthGate> {
  String? _initializedUid;
  Future<void>? _initialization;

  void _scheduleInitialization(String uid) {
    _initializedUid = uid;
    _initialization = null;

    // Chờ giao diện dựng xong mới khởi tạo Controller.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initializedUid != uid) return;

      final future = widget.controller.init();

      if (!mounted || _initializedUid != uid) return;

      setState(() {
        _initialization = future;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authSnapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Không thể kiểm tra trạng thái đăng nhập: '
                '${authSnapshot.error}',
              ),
            ),
          );
        }

        final user = authSnapshot.data;

        if (user == null) {
          _initializedUid = null;
          _initialization = null;

          return const GithubSignInScreen();
        }

        if (_initializedUid != user.uid) {
          _scheduleInitialization(user.uid);

          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final initialization = _initialization;

        if (initialization == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return FutureBuilder<void>(
          future: initialization,
          builder: (context, loadSnapshot) {
            if (loadSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (loadSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text(
                    'Không thể tải dữ liệu: ${loadSnapshot.error}',
                  ),
                ),
              );
            }

            return const DocumentHomeScreen();
          },
        );
      },
    );
  }
}
