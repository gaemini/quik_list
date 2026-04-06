import 'package:flutter/material.dart';
import 'package:qr_check_app/core/services/auth_service.dart';
import 'package:qr_check_app/core/services/firestore_service.dart';

class CreateChecklistPage extends StatefulWidget {
  const CreateChecklistPage({super.key});

  @override
  State<CreateChecklistPage> createState() => _CreateChecklistPageState();
}

class _CreateChecklistPageState extends State<CreateChecklistPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  static const _primary = Color(0xFFFF7300);
  static const _secondary = Color(0xFFFFE5D9);
  static const _neutral = Color(0xFF2C3E50);

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createChecklist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) throw Exception('로그인이 필요합니다');

      final checklistRef = await _firestoreService.createChecklist({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'hostId': currentUser.uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('체크리스트가 생성되었습니다'), backgroundColor: _primary),
        );
        Navigator.of(context).pop(checklistRef.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('체크리스트 생성 실패: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 체크리스트 만들기')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: _primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '이벤트나 행사의 체크리스트를 생성하세요',
                          style: TextStyle(color: _neutral, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: _neutral),
                  decoration: const InputDecoration(
                    labelText: '체크리스트 제목',
                    hintText: '예: 2024 신입생 환영회',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return '제목을 입력해주세요';
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: _neutral),
                  decoration: const InputDecoration(
                    labelText: '설명 (선택사항)',
                    hintText: '체크리스트에 대한 간단한 설명을 입력하세요',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createChecklist,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('체크리스트 생성'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
