import 'package:flutter/material.dart';

class ParticipantSuccessPage extends StatelessWidget {
  final String checklistTitle;

  static const _primary = Color(0xFFFF7300);
  static const _secondary = Color(0xFFFFE5D9);
  static const _neutral = Color(0xFF2C3E50);

  const ParticipantSuccessPage({super.key, required this.checklistTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 600),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 120, height: 120,
                      decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                      child: const Icon(Icons.check, size: 80, color: Colors.white),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text('참여가 완료되었습니다!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _neutral), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: _secondary, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Text(checklistTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _neutral), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('이벤트에 성공적으로 등록되었습니다', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _neutral.withOpacity(0.5)), textAlign: TextAlign.center),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('확인', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
