import 'package:flutter/material.dart';
import 'package:qr_check_app/features/checklist/presentation/pages/create_checklist_page.dart';
import 'package:qr_check_app/features/qr/presentation/pages/qr_scan_page.dart';

class ScanActionModal extends StatelessWidget {
  const ScanActionModal({super.key});

  static const _primary = Color(0xFFFF7300);
  static const _secondary = Color(0xFFFFE5D9);
  static const _neutral = Color(0xFF2C3E50);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _neutral.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '역할을 선택하세요',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '호스트로 시작하거나 참가자로 참여할 수 있습니다',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _neutral.withOpacity(0.5)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildOptionCard(
              context,
              icon: Icons.add_circle_outline,
              title: '호스트로 시작',
              description: '새로운 체크리스트를 만들고 참가자를 관리합니다',
              bgColor: _primary,
              iconBgColor: Colors.white.withOpacity(0.2),
              iconColor: Colors.white,
              textColor: Colors.white,
              descColor: Colors.white70,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateChecklistPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context,
              icon: Icons.qr_code_scanner,
              title: '참여자로 참여',
              description: 'QR 코드를 스캔하여 이벤트에 참여합니다',
              bgColor: _neutral,
              iconBgColor: Colors.white.withOpacity(0.2),
              iconColor: Colors.white,
              textColor: Colors.white,
              descColor: Colors.white70,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QrScanPage()),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color bgColor,
    required Color iconBgColor,
    required Color iconColor,
    required Color textColor,
    required Color descColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 4),
                    Text(description, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: descColor)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: textColor.withOpacity(0.5), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
