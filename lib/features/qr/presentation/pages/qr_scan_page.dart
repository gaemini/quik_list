import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_check_app/core/services/firestore_service.dart';
import 'package:qr_check_app/features/participant/presentation/pages/join_checklist_page.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final MobileScannerController _controller = MobileScannerController();
  final _firestoreService = FirestoreService();

  static const _primary = Color(0xFFFF7300);
  static const _neutral = Color(0xFF2C3E50);

  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);
    await _navigateToJoin(code);
  }

  Future<void> _navigateToJoin(String checklistId) async {
    try {
      final checklistDoc = await _firestoreService.getChecklist(checklistId);

      if (!checklistDoc.exists) {
        if (mounted) {
          _showError('체크리스트를 찾을 수 없습니다');
          setState(() => _isProcessing = false);
        }
        return;
      }

      final checklistData = checklistDoc.data() as Map<String, dynamic>;
      final status = checklistData['status'] ?? 'collecting';

      if (status == 'closed') {
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('마감된 이벤트'),
              content: const Text('이 이벤트는 이미 마감되었습니다.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() => _isProcessing = false);
                  },
                  child: const Text('확인', style: TextStyle(color: _primary)),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => JoinChecklistPage(checklistId: checklistId)),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('오류 발생: $e');
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR 코드 스캔'),
        actions: [
          IconButton(icon: const Icon(Icons.flash_on, color: _primary), onPressed: () => _controller.toggleTorch()),
          IconButton(icon: const Icon(Icons.flip_camera_ios, color: _primary), onPressed: () => _controller.switchCamera()),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Stack(
          children: [
            MobileScanner(controller: _controller, onDetect: _onDetect),
            Center(
              child: Container(
                width: 280, height: 280,
                decoration: BoxDecoration(
                  border: Border.all(color: _primary, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: 0, right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _neutral.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'QR 코드를 화면 중앙에 맞춰주세요',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0, right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () => _showManualInputDialog(),
                  icon: const Icon(Icons.edit),
                  label: const Text('수동으로 ID 입력'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualInputDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('체크리스트 ID 입력'),
        content: TextField(
          controller: controller,
          style: const TextStyle(fontWeight: FontWeight.w600, color: _neutral),
          decoration: const InputDecoration(labelText: '체크리스트 ID', hintText: '호스트로부터 받은 ID를 입력하세요'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('취소', style: TextStyle(color: _neutral.withOpacity(0.7)))),
          ElevatedButton(
            onPressed: () async {
              final id = controller.text.trim();
              if (id.isNotEmpty) {
                Navigator.of(context).pop();
                await _navigateToJoin(id);
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
