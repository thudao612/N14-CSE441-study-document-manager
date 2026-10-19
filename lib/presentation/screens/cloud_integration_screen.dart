import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/document_permission.dart';
import '../controllers/cloud_session_controller.dart';
import '../theme/app_theme.dart';

class CloudIntegrationScreen extends StatelessWidget {
  const CloudIntegrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CloudSessionController>();
    final user = session.currentUser;

    final permissionRows = [
      DocumentPermission(
        documentId: 'doc-001',
        userId: 'user-001',
        grantedBy: 'demo-owner',
        level: PermissionLevel.owner,
        grantedAt: DateTime.now(),
      ),
      DocumentPermission(
        documentId: 'doc-001',
        userId: 'user-002',
        grantedBy: 'demo-owner',
        level: PermissionLevel.editor,
        grantedAt: DateTime.now(),
      ),
      DocumentPermission(
        documentId: 'doc-001',
        userId: 'user-003',
        grantedBy: 'demo-owner',
        level: PermissionLevel.viewer,
        grantedAt: DateTime.now(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Integration'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Google + Firebase + Supabase',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  _StatusRow(
                    label: 'Firebase Auth',
                    value: session.authService.isFirebaseReady ? 'Ready' : 'Demo mode',
                    color: session.authService.isFirebaseReady ? AppTheme.secondary : AppTheme.accent,
                  ),
                  const SizedBox(height: 8),
                  _StatusRow(
                    label: 'Supabase',
                    value: session.isSupabaseReady ? 'Connected' : 'Configuration pending',
                    color: session.isSupabaseReady ? AppTheme.secondary : AppTheme.error,
                  ),
                  const SizedBox(height: 12),
                  if (user != null)
                    Text('Signed in as: ${user.fullName} (${user.email})')
                  else
                    const Text('Not signed in'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await session.signInWithGoogle();
                          },
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('Google Sign In'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await session.signOut();
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Sign out'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Access permissions matrix',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ...permissionRows.map((permission) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(child: Text('User ${permission.userId}')),
                            Expanded(child: Text(permission.levelLabel)),
                            Expanded(
                              child: Text(
                                permission.documentId,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Supabase schema ready',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'profiles, documents, document_permissions tables with RLS policies are provided in supabase_schema.sql.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ],
      );
  }
}
