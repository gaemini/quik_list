import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_check_app/core/services/firestore_service.dart';
import 'package:qr_check_app/features/checklist/presentation/pages/final_list_page.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRHostPage extends StatelessWidget {
  final String checklistId;
  final String checklistTitle;

  static const _primary = Color(0xFFFF7300);
  static const _secondary = Color(0xFFFFE5D9);
  static const _neutral = Color(0xFF2C3E50);

  const QRHostPage({
    super.key,
    required this.checklistId,
    required this.checklistTitle,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: _primary,
      appBar: AppBar(
        title: Text(checklistTitle),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildParticipantListSection(firestoreService),
              const SizedBox(height: 16),
              _buildQRCodeSection(),
              const SizedBox(height: 16),
              _buildCloseButton(context, firestoreService),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantListSection(FirestoreService firestoreService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '참여자 확인',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _neutral),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: firestoreService.getJoinedParticipants(checklistId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: _primary),
                  ),
                );
              }

              final participants = snapshot.data?.docs ?? [];

              if (participants.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    '아직 참여한 사람이 없습니다',
                    style: TextStyle(color: _neutral.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                );
              }

              final sortedParticipants = participants.reversed.toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...sortedParticipants.take(10).map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        data['name'] ?? '알 수 없음',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _neutral),
                      ),
                    );
                  }),
                  if (participants.length > 10)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '외 ${participants.length - 10}명',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _neutral.withOpacity(0.5)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '총 ${participants.length}명',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _primary),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: QrImageView(
          data: checklistId,
          version: QrVersions.auto,
          size: 280,
          backgroundColor: Colors.white,
          errorCorrectionLevel: QrErrorCorrectLevel.H,
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context, FirestoreService firestoreService) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showCloseConfirmation(context, firestoreService),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: const Center(
              child: Text(
                '마감하기',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCloseConfirmation(BuildContext context, FirestoreService firestoreService) async {
    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('체크리스트 마감'),
        content: const Text('체크리스트를 마감하시겠습니까?\n\n마감 후에는 새로운 참가자가 참여할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소', style: TextStyle(color: _neutral.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('마감하기'),
          ),
        ],
      ),
    );

    if (shouldClose == true && context.mounted) {
      try {
        await firestoreService.closeChecklist(checklistId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('체크리스트가 마감되었습니다'), backgroundColor: _primary),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => FinalListPage(checklistId: checklistId, checklistTitle: checklistTitle),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('마감 실패: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
