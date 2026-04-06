import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_check_app/core/services/auth_service.dart';
import 'package:qr_check_app/core/services/firestore_service.dart';
import 'package:qr_check_app/features/checklist/presentation/pages/create_checklist_page.dart';
import 'package:qr_check_app/features/checklist/presentation/pages/checklist_detail_page.dart';

class ChecklistsListPage extends StatelessWidget {
  const ChecklistsListPage({super.key});

  static const _primary = Color(0xFFFF7300);
  static const _secondary = Color(0xFFFFE5D9);
  static const _neutral = Color(0xFF2C3E50);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final currentUser = authService.getCurrentUser();

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('내 체크리스트')),
        body: const Center(child: Text('로그인이 필요합니다')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('내 체크리스트')),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: firestoreService.getChecklistsByHost(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text('오류 발생: ${snapshot.error}', textAlign: TextAlign.center),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _primary));
            }

            final checklists = snapshot.data?.docs ?? [];
            checklists.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aCreatedAt = aData['createdAt'] as Timestamp?;
              final bCreatedAt = bData['createdAt'] as Timestamp?;
              if (aCreatedAt == null && bCreatedAt == null) return 0;
              if (aCreatedAt == null) return 1;
              if (bCreatedAt == null) return -1;
              return bCreatedAt.compareTo(aCreatedAt);
            });

            if (checklists.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.checklist, size: 80, color: _neutral.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    Text('아직 체크리스트가 없습니다', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _neutral.withOpacity(0.5))),
                    const SizedBox(height: 8),
                    Text('하단의 버튼을 눌러\n새 체크리스트를 만들어보세요', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _neutral.withOpacity(0.4))),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: checklists.length,
              itemBuilder: (context, index) {
                final checklistDoc = checklists[index];
                final checklistData = checklistDoc.data() as Map<String, dynamic>;
                final title = checklistData['title'] ?? '제목 없음';
                final description = checklistData['description'] ?? '';
                final createdAt = checklistData['createdAt'] as Timestamp?;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChecklistDetailPage(checklistId: checklistDoc.id, checklistTitle: title),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: _secondary, borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.checklist, color: _primary, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _neutral)),
                                    if (description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(description, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _neutral.withOpacity(0.5)), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: _neutral.withOpacity(0.3)),
                            ],
                          ),
                          if (createdAt != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 14, color: _neutral.withOpacity(0.4)),
                                const SizedBox(width: 4),
                                Text(_formatDate(createdAt.toDate()), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _neutral.withOpacity(0.4))),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateChecklistPage()));
        },
        icon: const Icon(Icons.add),
        label: const Text('새 체크리스트', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
