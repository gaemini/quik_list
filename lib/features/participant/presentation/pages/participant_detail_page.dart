import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_check_app/core/services/firestore_service.dart';

class ParticipantDetailPage extends StatefulWidget {
  final DocumentSnapshot participant;

  const ParticipantDetailPage({super.key, required this.participant});

  @override
  State<ParticipantDetailPage> createState() => _ParticipantDetailPageState();
}

class _ParticipantDetailPageState extends State<ParticipantDetailPage> {
  final _firestoreService = FirestoreService();
  
  static const _primary = Color(0xFFFF7300);
  static const _secondary = Color(0xFFFFE5D9);
  static const _neutral = Color(0xFF2C3E50);

  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final participantData = widget.participant.data() as Map<String, dynamic>;
      final userId = participantData['userId'] as String?;
      
      if (userId != null) {
        final profile = await _firestoreService.getUserProfile(userId);
        if (mounted) {
          setState(() {
            _userProfile = profile;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final participantData = widget.participant.data() as Map<String, dynamic>;
    final name = participantData['name'] ?? '알 수 없음';
    final joinedAt = participantData['joinedAt'] as Timestamp?;
    
    // users 컬렉션에서 가져온 상세 정보
    final major = _userProfile?['major'] ?? '-';
    final grade = _userProfile?['grade'] ?? '-';
    final phone = _userProfile?['phone'] ?? '-';
    final nationality = _userProfile?['nationality'] ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('참가자 상세정보'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: _primary),
            tooltip: '정보 복사',
            onPressed: () => _copyToClipboard(context, name, major, grade, phone, nationality),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _primary),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _secondary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: _primary.withOpacity(0.2),
                            child: const Icon(Icons.person, size: 40, color: _primary),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _neutral,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (joinedAt != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '참여: ${_formatTimestamp(joinedAt)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _neutral.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildInfoCard(
                      context,
                      icon: Icons.school_outlined,
                      label: '전공',
                      value: major,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      icon: Icons.stairs_outlined,
                      label: '학년',
                      value: grade,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      icon: Icons.phone_outlined,
                      label: '전화번호',
                      value: phone,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      icon: Icons.public_outlined,
                      label: '국적',
                      value: nationality,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Widget? actionButton,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _neutral.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _neutral,
                    ),
                  ),
                ],
              ),
            ),
            if (actionButton != null) actionButton,
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _copyToClipboard(BuildContext context, String name, String major, String grade, String phone, String nationality) {
    final text = '''
이름: $name
전공: $major
학년: $grade
전화번호: $phone
국적: $nationality
''';
    
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('정보가 클립보드에 복사되었습니다'),
        backgroundColor: _primary,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
