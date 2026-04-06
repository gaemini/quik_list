import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_check_app/core/services/auth_service.dart';
import 'package:qr_check_app/core/services/firestore_service.dart';
import 'package:qr_check_app/features/participant/presentation/pages/participant_success_page.dart';

class JoinChecklistPage extends StatefulWidget {
  final String checklistId;

  const JoinChecklistPage({super.key, required this.checklistId});

  @override
  State<JoinChecklistPage> createState() => _JoinChecklistPageState();
}

class _JoinChecklistPageState extends State<JoinChecklistPage> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  static const _primary = Color(0xFFFF7300);
  static const _secondary = Color(0xFFFFE5D9);
  static const _neutral = Color(0xFF2C3E50);

  bool _isLoading = true;
  bool _isJoining = false;
  String? _checklistTitle;
  String? _checklistStatus;
  int _participantCount = 0;
  bool _alreadyJoined = false;

  @override
  void initState() {
    super.initState();
    _loadChecklistData();
  }

  Future<void> _loadChecklistData() async {
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) throw Exception('로그인이 필요합니다');

      final checklistDoc = await _firestoreService.getChecklist(widget.checklistId);
      if (!checklistDoc.exists) throw Exception('체크리스트를 찾을 수 없습니다');

      final checklistData = checklistDoc.data() as Map<String, dynamic>;
      final participantsSnapshot = await _firestoreService.getJoinedParticipants(widget.checklistId).first;
      final hasJoined = await _firestoreService.hasUserJoined(userId: currentUser.uid, checklistId: widget.checklistId);

      setState(() {
        _checklistTitle = checklistData['title'] ?? '제목 없음';
        _checklistStatus = checklistData['status'] ?? 'collecting';
        _participantCount = participantsSnapshot.docs.length;
        _alreadyJoined = hasJoined;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류 발생: $e'), backgroundColor: Colors.red));
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _joinChecklist() async {
    if (_isJoining) return;
    setState(() => _isJoining = true);

    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) throw Exception('로그인이 필요합니다');

      final userProfile = await _firestoreService.getUserProfile(currentUser.uid);
      final userName = userProfile?['name'] ??
          userProfile?['displayName'] ??
          currentUser.displayName ??
          currentUser.email?.split('@')[0] ??
          '사용자';

      await _firestoreService.joinChecklist(userId: currentUser.uid, name: userName, checklistId: widget.checklistId);
      await _firestoreService.saveUserJoinedList(userId: currentUser.uid, checklistId: widget.checklistId, checklistTitle: _checklistTitle ?? '체크리스트');

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ParticipantSuccessPage(checklistTitle: _checklistTitle ?? '체크리스트')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('참여 실패: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('체크리스트 참여')),
        body: const Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    if (_checklistStatus == 'closed') {
      return Scaffold(
        appBar: AppBar(title: const Text('체크리스트 참여')),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 80, color: _neutral.withOpacity(0.3)),
                  const SizedBox(height: 24),
                  const Text('마감된 이벤트', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _neutral)),
                  const SizedBox(height: 12),
                  Text('이 이벤트는 이미 마감되었습니다.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _neutral.withOpacity(0.5)), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('돌아가기')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_alreadyJoined) {
      return Scaffold(
        appBar: AppBar(title: const Text('체크리스트 참여')),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 80, color: _primary),
                  const SizedBox(height: 24),
                  const Text('이미 참여하셨습니다', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _neutral)),
                  const SizedBox(height: 12),
                  Text(_checklistTitle ?? '체크리스트', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _neutral.withOpacity(0.7)), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('체크리스트 참여')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: _secondary, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    const Icon(Icons.event, size: 64, color: _primary),
                    const SizedBox(height: 16),
                    Text(_checklistTitle ?? '체크리스트', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _neutral), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, size: 20, color: _neutral.withOpacity(0.5)),
                        const SizedBox(width: 8),
                        Text('현재 $_participantCount명 참여 중', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _neutral.withOpacity(0.7))),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isJoining ? null : _joinChecklist,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                child: _isJoining
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('참여하기', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 16),
              Text('참여하기 버튼을 누르면 이벤트에 등록됩니다', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _neutral.withOpacity(0.5)), textAlign: TextAlign.center),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
