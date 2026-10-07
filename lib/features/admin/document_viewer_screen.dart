import 'package:flutter/material.dart';

import '../../core/theme/role_theme.dart';

/// Shows the documents attached to one verification request.
/// Text-only refs for now — file URLs land later.
class DocumentViewerScreen extends StatelessWidget {
  final String title;
  final List<String> refs;

  const DocumentViewerScreen({
    super.key,
    required this.title,
    required this.refs,
  });

  @override
  Widget build(BuildContext context) {
    const theme = RoleTheme.admin;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.appBarBackground,
        foregroundColor: theme.appBarForeground,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: refs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No documents attached',
                  style: TextStyle(color: theme.textMuted),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: refs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _DocTile(ref: refs[i], theme: theme),
            ),
    );
  }
}

class _DocTile extends StatelessWidget {
  final String ref;
  final RoleTheme theme;
  const _DocTile({required this.ref, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.description_outlined,
              size: 18,
              color: theme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Document ref',
                  style: TextStyle(fontSize: 11, color: theme.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  ref,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
