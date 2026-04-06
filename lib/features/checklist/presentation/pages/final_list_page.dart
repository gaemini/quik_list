import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_check_app/core/services/firestore_service.dart';
import 'package:qr_check_app/core/services/pdf_service.dart';

enum SortMode { name, joinedAt }

class FinalListPage extends StatefulWidget {
  final String checklistId;
  final String checklistTitle;

  const FinalListPage({
    super.key,
    required this.checklistId,
    required this.checklistTitle,
  });

  @override
  State<FinalListPage> createState() => _FinalListPageState();
}

class _FinalListPageState extends State<FinalListPage> {
  final _firestoreService = FirestoreService();
  final _pdfService = PDFService();
  final _searchController = TextEditingController();

  static const _primary = Color(0xFFFF7300);
  static const _secondary = Color(0xFFFFE5D9);
  static const _neutral = Color(0xFF2C3E50);

  SortMode _sortMode = SortMode.name;
  String _searchQuery = '';
  bool _isExporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DocumentSnapshot> _sortParticipants(List<DocumentSnapshot> participants) {
    final sorted = List<DocumentSnapshot>.from(participants);

    switch (_sortMode) {
      case SortMode.name:
        sorted.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          return (aData['name'] ?? '').compareTo(bData['name'] ?? '');
        });
        break;
      case SortMode.joinedAt:
        sorted.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['joinedAt'] as Timestamp?;
          final bTime = bData['joinedAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
        break;
    }
    return sorted;
  }

  List<DocumentSnapshot> _filterParticipants(List<DocumentSnapshot> participants) {
    if (_searchQuery.isEmpty) return participants;
    return participants.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('최종 명단 관리'),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getJoinedParticipants(widget.checklistId),
            builder: (context, snapshot) {
              final participants = snapshot.data?.docs ?? [];
              final sorted = _sortParticipants(_filterParticipants(participants));
              return IconButton(
                icon: _isExporting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _primary))
                    : const Icon(Icons.picture_as_pdf, color: _primary),
                tooltip: 'PDF 내보내기',
                onPressed: participants.isEmpty || _isExporting ? null : () => _exportPDF(sorted),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndSort(),
            _buildAddItemButton(),
            Expanded(child: _buildTableView()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event, color: _primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.checklistTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _neutral)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getJoinedParticipants(widget.checklistId),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return Text('총 $count명', style: const TextStyle(fontSize: 14, color: _primary, fontWeight: FontWeight.bold));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndSort() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(fontWeight: FontWeight.w600, color: _neutral),
            decoration: InputDecoration(
              hintText: '이름 검색',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() { _searchController.clear(); _searchQuery = ''; }))
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('정렬:', style: TextStyle(fontWeight: FontWeight.bold, color: _neutral)),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('이름순'),
                      selected: _sortMode == SortMode.name,
                      selectedColor: _secondary,
                      onSelected: (selected) { if (selected) setState(() => _sortMode = SortMode.name); },
                    ),
                    ChoiceChip(
                      label: const Text('참여 시간순'),
                      selected: _sortMode == SortMode.joinedAt,
                      selectedColor: _secondary,
                      onSelected: (selected) { if (selected) setState(() => _sortMode = SortMode.joinedAt); },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: _showAddItemDialog,
        icon: const Icon(Icons.add),
        label: const Text('체크 항목 추가'),
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
      ),
    );
  }

  Widget _buildTableView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getChecklistItems(widget.checklistId),
      builder: (context, itemsSnapshot) {
        if (itemsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _primary));
        }

        final items = itemsSnapshot.data?.docs ?? [];
        items.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          return (aData['order'] ?? 0).compareTo(bData['order'] ?? 0);
        });

        return StreamBuilder<QuerySnapshot>(
          stream: _firestoreService.getJoinedParticipants(widget.checklistId),
          builder: (context, participantsSnapshot) {
            if (participantsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _primary));
            }

            final participants = participantsSnapshot.data?.docs ?? [];
            final sorted = _sortParticipants(_filterParticipants(participants));

            if (sorted.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: _neutral.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty ? '참가자가 없습니다' : '검색 결과가 없습니다',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _neutral.withOpacity(0.5)),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(child: _buildDataTable(sorted, items)),
            );
          },
        );
      },
    );
  }

  Widget _buildDataTable(List<DocumentSnapshot> participants, List<QueryDocumentSnapshot> items) {
    return DataTable(
      border: TableBorder.all(color: _neutral.withOpacity(0.15), width: 1),
      headingRowColor: WidgetStateProperty.all(_secondary),
      columns: [
        const DataColumn(label: Text('이름', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _neutral))),
        ...items.map((itemDoc) {
          final itemData = itemDoc.data() as Map<String, dynamic>;
          return DataColumn(
            label: Row(
              children: [
                Text(itemData['title'] ?? '항목', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _neutral)),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.close, size: 16, color: _neutral.withOpacity(0.5)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _deleteItem(itemDoc.id, itemData['title'] ?? '항목'),
                ),
              ],
            ),
          );
        }),
      ],
      rows: participants.asMap().entries.map((entry) {
        final participantDoc = entry.value;
        final participantData = participantDoc.data() as Map<String, dynamic>;
        final checks = participantData['checks'] as Map<String, dynamic>? ?? {};

        return DataRow(
          color: WidgetStateProperty.all(entry.key % 2 == 0 ? Colors.white : _secondary.withOpacity(0.2)),
          cells: [
            DataCell(Text(participantData['name'] ?? '알 수 없음', style: const TextStyle(fontWeight: FontWeight.bold, color: _neutral))),
            ...items.map((itemDoc) {
              final isChecked = checks[itemDoc.id] == true;
              return DataCell(
                Center(
                  child: Checkbox(
                    value: isChecked,
                    activeColor: _primary,
                    onChanged: (value) => _toggleCheck(participantDoc.id, itemDoc.id, value ?? false),
                  ),
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }

  Future<void> _showAddItemDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('체크 항목 추가'),
        content: TextField(
          controller: controller,
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: const InputDecoration(labelText: '항목 이름', hintText: '예: 출석, 식사, 기념품'),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('취소', style: TextStyle(color: _neutral.withOpacity(0.7)))),
          ElevatedButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) Navigator.of(context).pop(title);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _firestoreService.createChecklistItem(checklistId: widget.checklistId, title: result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('\'$result\' 항목이 추가되었습니다'), backgroundColor: _primary));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('항목 추가 실패: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _toggleCheck(String participantId, String itemId, bool isChecked) async {
    try {
      await _firestoreService.toggleParticipantCheck(participantId: participantId, itemId: itemId, isChecked: isChecked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('체크 상태 업데이트 실패: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deleteItem(String itemId, String itemTitle) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('항목 삭제'),
        content: Text('\'$itemTitle\' 항목을 삭제하시겠습니까?\n모든 체크 데이터가 삭제됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('취소', style: TextStyle(color: _neutral.withOpacity(0.7)))),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: _neutral),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _firestoreService.deleteChecklistItem(itemId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('\'$itemTitle\' 항목이 삭제되었습니다'), backgroundColor: _primary));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('항목 삭제 실패: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _exportPDF(List<DocumentSnapshot> participants) async {
    setState(() => _isExporting = true);

    try {
      final itemsSnapshot = await _firestoreService.checklistItemsCollection
          .where('checklistId', isEqualTo: widget.checklistId).get();

      final items = itemsSnapshot.docs;
      items.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        return (aData['order'] ?? 0).compareTo(bData['order'] ?? 0);
      });

      final checklistItemsList = items.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, 'title': data['title'] ?? '항목'};
      }).toList();

      final participantDataList = participants.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final joinedAt = data['joinedAt'] as Timestamp?;
        final checks = data['checks'] as Map<String, dynamic>? ?? {};
        return {
          'name': data['name'] ?? '알 수 없음',
          'joinedAtFormatted': joinedAt != null ? _formatTimestamp(joinedAt) : '-',
          'checks': checks,
        };
      }).toList();

      final pdfBytes = await _pdfService.generateParticipantListPDF(
        checklistTitle: widget.checklistTitle,
        participants: participantDataList,
        checklistItems: checklistItemsList.isNotEmpty ? checklistItemsList : null,
      );

      await _pdfService.previewAndShare(pdfBytes, '${widget.checklistTitle}-참가자명단.pdf');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF가 생성되었습니다'), backgroundColor: _primary));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF 생성 실패: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}
