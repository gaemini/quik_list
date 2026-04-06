import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_check_app/core/services/auth_service.dart';
import 'package:qr_check_app/core/services/firestore_service.dart';

class MyJoinedListsPage extends StatelessWidget {
  const MyJoinedListsPage({super.key});

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
        appBar: AppBar(title: const Text('내가 참여한 이벤트')),
        body: const Center(child: Text('로그인이 필요합니다')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('내가 참여한 이벤트')),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: firestoreService.getUserJoinedLists(currentUser.uid),
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

            final joinedLists = snapshot.data?.docs ?? [];
            joinedLists.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aJoinedAt = aData['joinedAt'] as Timestamp?;
              final bJoinedAt = bData['joinedAt'] as Timestamp?;
              if (aJoinedAt == null && bJoinedAt == null) return 0;
              if (aJoinedAt == null) return 1;
              if (bJoinedAt == null) return -1;
              return bJoinedAt.compareTo(aJoinedAt);
            });

            if (joinedLists.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_available, size: 80, color: _neutral.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    Text('참여한 이벤트가 없습니다', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _neutral.withOpacity(0.5))),
                    const SizedBox(height: 8),
                    Text('QR 코드를 스캔하여\n이벤트에 참여해보세요', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _neutral.withOpacity(0.4))),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: joinedLists.length,
              itemBuilder: (context, index) {
                final doc = joinedLists[index];
                final data = doc.data() as Map<String, dynamic>;
                final checklistTitle = data['checklistTitle'] ?? '제목 없음';
                final checklistId = data['checklistId'] ?? '';
                final joinedAt = data['joinedAt'] as Timestamp?;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showChecklistInfo(context, checklistTitle, checklistId, joinedAt),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: _secondary, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.check_circle, color: _primary, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(checklistTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _neutral)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 14, color: _neutral.withOpacity(0.4)),
                                    const SizedBox(width: 4),
                                    Text(
                                      joinedAt != null ? _formatDate(joinedAt.toDate()) : '날짜 정보 없음',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _neutral.withOpacity(0.4)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: _neutral.withOpacity(0.3)),
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
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) return '방금 전';
        return '${difference.inMinutes}분 전';
      }
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    }
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  void _showChecklistInfo(BuildContext context, String title, String checklistId, Timestamp? joinedAt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이벤트 정보'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _neutral)),
            const SizedBox(height: 16),
            Row(children: [Icon(Icons.event, size: 20, color: _neutral.withOpacity(0.5)), const SizedBox(width: 8), const Text('참여 완료')]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.access_time, size: 20, color: _neutral.withOpacity(0.5)),
              const SizedBox(width: 8),
              Text(joinedAt != null ? _formatDate(joinedAt.toDate()) : '날짜 정보 없음'),
            ]),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인', style: TextStyle(color: _primary))),
        ],
      ),
    );
  }
}
