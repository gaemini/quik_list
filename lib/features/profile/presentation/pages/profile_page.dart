import 'package:flutter/material.dart';
import 'package:qr_check_app/core/services/auth_service.dart';
import 'package:qr_check_app/core/services/firestore_service.dart';
import 'package:qr_check_app/features/auth/presentation/pages/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  static const _primary = Color(0xFFFF7300);
  static const _secondary = Color(0xFFFFE5D9);
  static const _neutral = Color(0xFF2C3E50);

  bool _isEditing = false;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _majorController = TextEditingController();
  final _gradeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _majorController.dispose();
    _gradeController.dispose();
    _phoneController.dispose();
    _nationalityController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) return;

    try {
      final profile = await _firestoreService.getUserProfile(currentUser.uid);
      if (profile != null && mounted) {
        setState(() {
          _nameController.text = profile['name'] ?? '';
          _majorController.text = profile['major'] ?? '';
          _gradeController.text = profile['grade'] ?? '';
          _phoneController.text = profile['phone'] ?? '';
          _nationalityController.text = profile['nationality'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 로드 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      await _firestoreService.createOrUpdateUser(currentUser.uid, {
        'name': _nameController.text.trim(),
        'major': _majorController.text.trim(),
        'grade': _gradeController.text.trim(),
        'phone': _phoneController.text.trim(),
        'nationality': _nationalityController.text.trim(),
      });

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 업데이트되었습니다'), backgroundColor: _primary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 저장 실패: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소', style: TextStyle(color: _neutral.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: _neutral),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: _primary),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SafeArea(
        child: currentUser == null
            ? const Center(child: Text('로그인이 필요합니다'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: _secondary,
                        child: const Icon(Icons.person, size: 50, color: _primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentUser.email ?? '이메일 없음',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _neutral.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 24),

                      _buildTextField(controller: _nameController, label: '이름', icon: Icons.person_outline, enabled: _isEditing, validator: (value) {
                        if (value == null || value.trim().isEmpty) return '이름을 입력하세요';
                        return null;
                      }),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _majorController, label: '전공', icon: Icons.school_outlined, enabled: _isEditing),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _gradeController, label: '학년', icon: Icons.grade_outlined, enabled: _isEditing),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _phoneController, label: '전화번호', icon: Icons.phone_outlined, enabled: _isEditing, keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _nationalityController, label: '국적', icon: Icons.flag_outlined, enabled: _isEditing),
                      const SizedBox(height: 24),

                      if (_isEditing) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : () {
                                  setState(() => _isEditing = false);
                                  _loadUserProfile();
                                },
                                child: const Text('취소'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveProfile,
                                child: _isLoading
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('저장'),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _handleLogout,
                            icon: const Icon(Icons.logout),
                            label: const Text('로그아웃'),
                            style: ElevatedButton.styleFrom(backgroundColor: _neutral),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w600, color: _neutral),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primary),
        filled: true,
        fillColor: enabled ? _secondary.withOpacity(0.3) : _secondary.withOpacity(0.15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 2)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
