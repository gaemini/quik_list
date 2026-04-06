import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_check_app/core/services/firestore_service.dart';
import 'package:qr_check_app/features/qr/presentation/pages/qr_host_page.dart';
import 'package:qr_check_app/features/checklist/presentation/pages/final_list_page.dart';

class ChecklistDetailPage extends StatelessWidget {
  final String checklistId;
  final String checklistTitle;

  static const _primary = Color(0xFFFF7300);
  static const _secondary = Color(0xFFFFE5D9);
  static const _neutral = Color(0xFF2C3E50);

  const ChecklistDetailPage({
    super.key,
    required this.checklistId,
    required this.checklistTitle,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<DocumentSnapshot>(
      stream: firestoreService.checklistsCollection.doc(checklistId).snapshots(),
      builder: (context, checklistSnapshot) {
        if (checklistSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(checklistTitle)),
            body: const Center(child: CircularProgressIndicator(color: _primary)),
          );
        }

        if (!checklistSnapshot.hasData || !checklistSnapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: Text(checklistTitle)),
            body: const Center(child: Text('체크리스트를 찾을 수 없습니다')),
          );
        }

        final checklistData = checklistSnapshot.data!.data() as Map<String, dynamic>;
        final status = checklistData['status'] ?? 'collecting';
        final isClosed = status == 'closed';

        return Scaffold(
          appBar: AppBar(
            title: Text(checklistTitle),
            actions: [
              if (isClosed)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _neutral,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '마감됨',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isClosed ? _neutral : _primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isClosed ? Icons.check_circle : Icons.checklist,
                          size: 32,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                checklistTitle,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isClosed ? '이벤트가 종료되었습니다' : '참가자 수집 중',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('참가자 현황', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),

                  StreamBuilder<QuerySnapshot>(
                    stream: firestoreService.getJoinedParticipants(checklistId),
                    builder: (context, snapshot) {
                      final participants = snapshot.data?.docs ?? [];
                      return _buildActionCard(
                        context,
                        icon: Icons.people,
                        title: '참가자 목록',
                        description: '참여한 사람들을 확인하세요',
                        count: participants.length,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FinalListPage(
                                checklistId: checklistId,
                                checklistTitle: checklistTitle,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  Text(
                    isClosed ? '최종 관리' : 'QR 코드 & 실시간 모니터링',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),

                  if (isClosed)
                    _buildActionCard(
                      context,
                      icon: Icons.assessment,
                      title: '최종 명단 관리',
                      description: '정렬 및 PDF 내보내기',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FinalListPage(
                              checklistId: checklistId,
                              checklistTitle: checklistTitle,
                            ),
                          ),
                        );
                      },
                    )
                  else
                    _buildActionCard(
                      context,
                      icon: Icons.qr_code_2,
                      title: '실시간 참가자 모니터링',
                      description: 'QR 코드 표시 및 참가자 실시간 확인',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => QRHostPage(
                              checklistId: checklistId,
                              checklistTitle: checklistTitle,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    int? count,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _neutral)),
                        if (count != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _neutral.withOpacity(0.5)),
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
  }
}
