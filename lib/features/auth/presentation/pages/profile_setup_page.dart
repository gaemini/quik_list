import 'package:flutter/material.dart';
import 'package:qr_check_app/core/data/country_data.dart';
import 'package:qr_check_app/core/services/auth_service.dart';
import 'package:qr_check_app/core/services/firestore_service.dart';
import 'package:qr_check_app/features/home/presentation/pages/home_page.dart';

/// 첫 로그인 후 프로필 입력 페이지
class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  final _nameController = TextEditingController();
  final _majorController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedGrade;
  String? _selectedNationalityCode;
  bool _isLoading = false;

  final List<String> _grades = ['1학년', '2학년', '3학년', '4학년', '대학원생'];

  @override
  void dispose() {
    _nameController.dispose();
    _majorController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// 프로필 저장 처리
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGrade == null) {
      _showError('학년을 선택해주세요');
      return;
    }

    if (_selectedNationalityCode == null) {
      _showError('국적을 선택해주세요');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        throw Exception('로그인 정보를 찾을 수 없습니다');
      }

      // Provider 확인
      String provider = 'email';
      if (user.providerData.isNotEmpty) {
        final providerId = user.providerData.first.providerId;
        if (providerId.contains('google')) {
          provider = 'google';
        } else if (providerId.contains('apple')) {
          provider = 'apple';
        }
      }

      final profileData = {
        'email': user.email ?? '',
        'name': _nameController.text.trim(),
        'major': _majorController.text.trim(),
        'grade': _selectedGrade!,
        'phone': _phoneController.text.trim(),
        'nationality': _selectedNationalityCode!,
        'provider': provider,
      };

      await _firestoreService.createUserProfile(user.uid, profileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필이 저장되었습니다!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showNationalityPicker() {
    final locale = Localizations.localeOf(context).languageCode;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _NationalityPickerSheet(
            scrollController: scrollController,
            locale: locale,
            selectedCode: _selectedNationalityCode,
            onSelect: (code) {
              setState(() => _selectedNationalityCode = code);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  String _getSelectedNationalityName() {
    if (_selectedNationalityCode == null) return '';
    
    final locale = Localizations.localeOf(context).languageCode;
    final country = CountryData.countries.firstWhere(
      (c) => c.code == _selectedNationalityCode,
    );
    return country.getName(locale);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('프로필 설정'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '프로필 정보를 입력해주세요',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '서비스 이용을 위해 필수 정보가 필요합니다',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // 이름
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: '이름 *',
                    hintText: '홍길동',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '이름을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 전공
                TextFormField(
                  controller: _majorController,
                  decoration: InputDecoration(
                    labelText: '전공 *',
                    hintText: '컴퓨터공학',
                    prefixIcon: const Icon(Icons.school_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '전공을 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 학년
                DropdownButtonFormField<String>(
                  value: _selectedGrade,
                  decoration: InputDecoration(
                    labelText: '학년 *',
                    prefixIcon: const Icon(Icons.stairs_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _grades.map((grade) {
                    return DropdownMenuItem(
                      value: grade,
                      child: Text(grade),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGrade = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return '학년을 선택해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 전화번호
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: '전화번호 *',
                    hintText: '010-1234-5678',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '전화번호를 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 국적
                InkWell(
                  onTap: _showNationalityPicker,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: '국적 *',
                      prefixIcon: const Icon(Icons.public_outlined),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _selectedNationalityCode == null
                          ? '국적을 선택하세요'
                          : _getSelectedNationalityName(),
                      style: TextStyle(
                        color: _selectedNationalityCode == null
                            ? Colors.grey[600]
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 제출 버튼
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '프로필 저장하고 시작하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                Text(
                  '* 표시된 항목은 필수 입력 항목입니다',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 국적 선택 Bottom Sheet
class _NationalityPickerSheet extends StatefulWidget {
  final ScrollController scrollController;
  final String locale;
  final String? selectedCode;
  final Function(String) onSelect;

  const _NationalityPickerSheet({
    required this.scrollController,
    required this.locale,
    required this.selectedCode,
    required this.onSelect,
  });

  @override
  State<_NationalityPickerSheet> createState() => _NationalityPickerSheetState();
}

class _NationalityPickerSheetState extends State<_NationalityPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<CountryData> _filteredCountries = CountryData.countries;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = CountryData.countries;
      } else {
        _filteredCountries = CountryData.countries.where((country) {
          final name = country.getName(widget.locale).toLowerCase();
          final code = country.code.toLowerCase();
          final searchQuery = query.toLowerCase();
          return name.contains(searchQuery) || code.contains(searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 16),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // 제목
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            '국적 선택',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 16),

        // 검색 필드
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '국가 검색',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: _filterCountries,
          ),
        ),
        const SizedBox(height: 16),

        // 국가 목록
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: _filteredCountries.length,
            itemBuilder: (context, index) {
              final country = _filteredCountries[index];
              final isSelected = country.code == widget.selectedCode;

              return ListTile(
                leading: Text(
                  country.code,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                title: Text(
                  country.getName(widget.locale),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
                onTap: () => widget.onSelect(country.code),
              );
            },
          ),
        ),
      ],
    );
  }
}
