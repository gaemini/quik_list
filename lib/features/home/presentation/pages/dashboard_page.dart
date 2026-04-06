import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_check_app/core/services/auth_service.dart';
import 'package:qr_check_app/core/services/firestore_service.dart';
import 'package:qr_check_app/features/checklist/presentation/pages/checklist_detail_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const _primary = Color(0xFFFF7300);
  static const _secondary = Color(0xFFFFE5D9);
  static const _neutral = Color(0xFF2C3E50);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final currentUser = authService.getCurrentUser();

    return Scaffold(
      appBar: AppBar(title: const Text('QR 체크인')),
      body: SafeArea(
        child: currentUser == null
            ? const Center(child: Text('로그인이 필요합니다'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, title: '내 체크리스트', icon: Icons.list_alt),
                    const SizedBox(height: 12),
                    _buildMyChecklists(firestoreService, currentUser.uid),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, title: '내가 참여한 체크리스트', icon: Icons.event_available),
                    const SizedBox(height: 12),
                    _buildJoinedChecklists(firestoreService, currentUser.uid),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, required IconData icon}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _secondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }

  Widget _buildMyChecklists(FirestoreService firestoreService, String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getChecklistsByHost(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: _primary)),
          );
        }
        if (snapshot.hasError) return _buildEmptyCard('오류가 발생했습니다');

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

        if (checklists.isEmpty) return _buildEmptyCard('아직 생성한 체크리스트가 없습니다');

        return Column(
          children: checklists.take(3).map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildChecklistCard(
              context,
              checklistId: doc.id,
              title: data['title'] ?? '제목 없음',
              status: data['status'] ?? 'collecting',
              timestamp: data['createdAt'] as Timestamp?,
              isHost: true,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildJoinedChecklists(FirestoreService firestoreService, String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getUserJoinedLists(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: _primary)),
          );
        }
        if (snapshot.hasError) return _buildEmptyCard('오류가 발생했습니다');

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

        if (joinedLists.isEmpty) return _buildEmptyCard('아직 참여한 체크리스트가 없습니다');

        return Column(
          children: joinedLists.take(3).map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildChecklistCard(
              context,
              checklistId: data['checklistId'] ?? '',
              title: data['checklistTitle'] ?? '제목 없음',
              status: 'joined',
              timestamp: data['joinedAt'] as Timestamp?,
              isHost: false,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildChecklistCard(
    BuildContext context, {
    required String checklistId,
    required String title,
    required String status,
    required Timestamp? timestamp,
    required bool isHost,
  }) {
    final statusInfo = _getStatusInfo(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isHost
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChecklistDetailPage(
                      checklistId: checklistId,
                      checklistTitle: title,
                    ),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _neutral),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (statusInfo['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusInfo['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: statusInfo['color'] as Color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (timestamp != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatTimestamp(timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _neutral.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isHost)
                Icon(Icons.arrow_forward_ios, color: _neutral.withOpacity(0.3), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _secondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(color: _neutral.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'collecting':
        return {'label': '진행 중', 'color': _primary};
      case 'closed':
        return {'label': '마감됨', 'color': _neutral};
      case 'joined':
        return {'label': '참여 완료', 'color': _primary};
      default:
        return {'label': '알 수 없음', 'color': _neutral};
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) return '방금 전';
        return '${difference.inMinutes}분 전';
      }
      return '${difference.inHours}시간 전';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    }
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
  }
}
