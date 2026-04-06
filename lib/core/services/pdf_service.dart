import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

/// PDF 생성 및 공유 서비스
/// 한글 폰트 지원, 체크리스트 항목 포함
class PDFService {
  // 캐시된 폰트
  static pw.Font? _cachedFont;

  /// 한글 폰트 로드
  Future<pw.Font> _loadKoreanFont() async {
    if (_cachedFont != null) {
      return _cachedFont!;
    }

    try {
      final fontData = await rootBundle.load('assets/fonts/NotoSansKR-Regular.ttf');
      _cachedFont = pw.Font.ttf(fontData);
      return _cachedFont!;
    } catch (e) {
      throw Exception('폰트 로드 실패: $e');
    }
  }

  /// 체크리스트 항목이 포함된 참가자 리스트를 PDF로 생성
  /// 
  /// [checklistTitle] 체크리스트 제목
  /// [participants] 참가자 리스트 (name, checks 포함)
  /// [checklistItems] 체크리스트 항목 리스트 (id, title)
  Future<Uint8List> generateParticipantListPDF({
    required String checklistTitle,
    required List<Map<String, dynamic>> participants,
    List<Map<String, dynamic>>? checklistItems,
  }) async {
    final pdf = pw.Document();
    final font = await _loadKoreanFont();

    // 현재 날짜
    final now = DateTime.now();
    final dateString = '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';

    // 체크리스트 항목이 있는지 확인
    final hasChecklistItems = checklistItems != null && checklistItems.isNotEmpty;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: font,
        ),
        build: (context) {
          return [
            // 제목
            pw.Text(
              checklistTitle,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                font: font,
              ),
            ),
            pw.SizedBox(height: 8),
            
            // 날짜
            pw.Text(
              '날짜: $dateString',
              style: pw.TextStyle(
                fontSize: 14,
                color: PdfColors.grey700,
                font: font,
              ),
            ),
            pw.SizedBox(height: 4),
            
            // 총 참가자 수
            pw.Text(
              '총 참가자: ${participants.length}명',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
                font: font,
              ),
            ),
            pw.SizedBox(height: 24),
            
            // 테이블
            if (hasChecklistItems)
              _buildChecklistTable(participants, checklistItems, font)
            else
              _buildSimpleTable(participants, font),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// 체크리스트 항목이 포함된 테이블 생성
  pw.Widget _buildChecklistTable(
    List<Map<String, dynamic>> participants,
    List<Map<String, dynamic>> checklistItems,
    pw.Font font,
  ) {
    // 컬럼 너비 설정
    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(40), // 번호
      1: const pw.FlexColumnWidth(2), // 이름
    };
    
    // 체크리스트 항목 컬럼 너비
    for (int i = 0; i < checklistItems.length; i++) {
      columnWidths[i + 2] = const pw.FlexColumnWidth(1);
    }

    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey400,
        width: 1,
      ),
      columnWidths: columnWidths,
      children: [
        // 헤더 행
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          children: [
            _buildTableCell('번호', font, isHeader: true),
            _buildTableCell('이름', font, isHeader: true),
            ...checklistItems.map((item) {
              final title = item['title'] ?? '항목';
              return _buildTableCell(title, font, isHeader: true);
            }),
          ],
        ),
        
        // 데이터 행
        ...participants.asMap().entries.map((entry) {
          final index = entry.key;
          final participant = entry.value;
          final name = participant['name'] ?? '알 수 없음';
          final checks = participant['checks'] as Map<String, dynamic>? ?? {};

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index % 2 == 0 ? PdfColors.white : PdfColors.grey100,
            ),
            children: [
              _buildTableCell('${index + 1}', font, align: pw.Alignment.center),
              _buildTableCell(name, font),
              ...checklistItems.map((item) {
                final itemId = item['id'];
                final isChecked = checks[itemId] == true;
                return _buildCheckboxCell(isChecked, font);
              }),
            ],
          );
        }),
      ],
    );
  }

  /// 간단한 참가자 목록 테이블 (체크리스트 항목 없음)
  pw.Widget _buildSimpleTable(
    List<Map<String, dynamic>> participants,
    pw.Font font,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey400,
        width: 1,
      ),
      columnWidths: const {
        0: pw.FixedColumnWidth(60),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
      },
      children: [
        // 헤더 행
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          children: [
            _buildTableCell('번호', font, isHeader: true),
            _buildTableCell('이름', font, isHeader: true),
            _buildTableCell('참여 시간', font, isHeader: true),
          ],
        ),
        
        // 데이터 행
        ...participants.asMap().entries.map((entry) {
          final index = entry.key;
          final participant = entry.value;
          final name = participant['name'] ?? '알 수 없음';
          final joinedAt = participant['joinedAtFormatted'] ?? '-';

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index % 2 == 0 ? PdfColors.white : PdfColors.grey100,
            ),
            children: [
              _buildTableCell('${index + 1}', font, align: pw.Alignment.center),
              _buildTableCell(name, font),
              _buildTableCell(joinedAt, font, align: pw.Alignment.center),
            ],
          );
        }),
      ],
    );
  }

  /// 테이블 셀 생성
  pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
    pw.Alignment? align,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Align(
        alignment: align ?? pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: isHeader ? 12 : 11,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            font: font,
          ),
        ),
      ),
    );
  }

  /// 체크박스 셀 생성 (✔ 또는 ✖)
  pw.Widget _buildCheckboxCell(bool isChecked, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Center(
        child: pw.Text(
          isChecked ? '✔' : '✖',
          style: pw.TextStyle(
            fontSize: 14,
            color: isChecked ? PdfColors.green700 : PdfColors.red700,
            fontWeight: pw.FontWeight.bold,
            font: font,
          ),
        ),
      ),
    );
  }

  /// PDF를 공유하기 (프린트 또는 저장)
  /// 
  /// [pdfBytes] PDF 바이트 데이터
  /// [filename] 파일명
  Future<void> sharePDF(Uint8List pdfBytes, String filename) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: filename,
    );
  }

  /// PDF 미리보기
  /// 
  /// [pdfBytes] PDF 바이트 데이터
  Future<void> previewPDF(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
    );
  }

  /// PDF를 로컬에 저장
  /// 
  /// [pdfBytes] PDF 바이트 데이터
  /// [filename] 파일명
  /// Returns: 저장된 파일 경로
  Future<String> savePDFLocally(Uint8List pdfBytes, String filename) async {
    try {
      // 앱의 문서 디렉토리 가져오기
      final directory = await getApplicationDocumentsDirectory();
      
      // 파일 경로 생성
      final filePath = '${directory.path}/$filename';
      
      // 파일 쓰기
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      
      return filePath;
    } catch (e) {
      throw Exception('PDF 저장 실패: $e');
    }
  }

  /// 미리보기 후 저장/공유 선택
  /// 
  /// [pdfBytes] PDF 바이트 데이터
  /// [filename] 파일명
  Future<void> previewAndShare(Uint8List pdfBytes, String filename) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: filename,
    );
  }
}
