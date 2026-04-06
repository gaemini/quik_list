import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore 데이터베이스를 관리하는 서비스 클래스
/// 체크리스트, 참가자, 체크인 기록 등을 관리
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 컬렉션 참조
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get checklistsCollection => _firestore.collection('checklists');
  CollectionReference get participantsCollection => _firestore.collection('participants');
  CollectionReference get checkinsCollection => _firestore.collection('checkins');

  /// 사용자 생성 또는 업데이트
  /// 
  /// [userId] 사용자 고유 ID (일반적으로 Firebase Auth UID)
  /// [data] 저장할 사용자 데이터
  Future<void> createOrUpdateUser(String userId, Map<String, dynamic> data) async {
    try {
      await usersCollection.doc(userId).set(
        {
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('사용자 정보 저장 실패: $e');
    }
  }

  /// 사용자 프로필 생성
  /// 
  /// [userId] 사용자 고유 ID
  /// [profileData] 프로필 데이터
  Future<void> createUserProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      await usersCollection.doc(userId).set(
        {
          'uid': userId,
          ...profileData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('프로필 생성 실패: $e');
    }
  }

  /// 특정 사용자 정보 조회
  Future<DocumentSnapshot> getUser(String userId) async {
    try {
      return await usersCollection.doc(userId).get();
    } catch (e) {
      throw Exception('사용자 정보 조회 실패: $e');
    }
  }

  /// 사용자 프로필 조회
  /// 
  /// [uid] 사용자 고유 ID
  /// Returns: 사용자 프로필 데이터
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await usersCollection.doc(uid).get();
      if (!doc.exists) {
        return null;
      }
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      throw Exception('프로필 조회 실패: $e');
    }
  }

  /// 체크리스트 생성
  /// 
  /// [data] 체크리스트 데이터
  /// - title: 체크리스트 제목
  /// - description: 체크리스트 설명
  /// - hostId: 생성자 ID
  /// - createdAt: 생성 시간
  Future<DocumentReference> createChecklist(Map<String, dynamic> data) async {
    try {
      return await checklistsCollection.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('체크리스트 생성 실패: $e');
    }
  }

  /// 특정 호스트의 체크리스트 목록 조회
  Stream<QuerySnapshot> getChecklistsByHost(String hostId) {
    return checklistsCollection
        .where('hostId', isEqualTo: hostId)
        .snapshots();
  }

  /// 참가자 생성
  /// 
  /// [data] 참가자 데이터
  /// - name: 참가자 이름
  /// - email: 참가자 이메일
  /// - qrCode: QR 코드 문자열
  /// - checklistId: 소속 체크리스트 ID
  Future<DocumentReference> createParticipant(Map<String, dynamic> data) async {
    try {
      return await participantsCollection.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('참가자 생성 실패: $e');
    }
  }

  /// 특정 체크리스트의 참가자 목록 조회 (모든 상태)
  Stream<QuerySnapshot> getParticipantsByChecklist(String checklistId) {
    return participantsCollection
        .where('checklistId', isEqualTo: checklistId)
        .snapshots();
  }

  /// 특정 체크리스트의 확인된 참가자 목록 조회
  /// status가 "confirmed"인 참가자만 반환
  Stream<QuerySnapshot> getConfirmedParticipants(String checklistId) {
    return participantsCollection
        .where('checklistId', isEqualTo: checklistId)
        .where('status', isEqualTo: 'confirmed')
        .snapshots();
  }

  /// 특정 체크리스트의 대기 중인 참가자 목록 조회
  /// status가 "pending"인 참가자만 반환
  Stream<QuerySnapshot> getPendingParticipants(String checklistId) {
    return participantsCollection
        .where('checklistId', isEqualTo: checklistId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  /// 참가자 ID로 상세 정보 조회
  Future<DocumentSnapshot> getParticipantById(String participantId) async {
    try {
      return await participantsCollection.doc(participantId).get();
    } catch (e) {
      throw Exception('참가자 정보 조회 실패: $e');
    }
  }

  /// QR 코드로 참가자 조회
  Future<QuerySnapshot> getParticipantByQRCode(String qrCode) async {
    try {
      return await participantsCollection
          .where('qrCode', isEqualTo: qrCode)
          .limit(1)
          .get();
    } catch (e) {
      throw Exception('참가자 조회 실패: $e');
    }
  }

  /// 체크인 기록 생성
  /// 
  /// [data] 체크인 데이터
  /// - participantId: 참가자 ID
  /// - checklistId: 체크리스트 ID
  /// - hostId: 체크인 처리한 호스트 ID
  /// - checkedInAt: 체크인 시간
  Future<DocumentReference> createCheckin(Map<String, dynamic> data) async {
    try {
      return await checkinsCollection.add({
        ...data,
        'checkedInAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('체크인 기록 생성 실패: $e');
    }
  }

  /// 특정 체크리스트의 체크인 기록 조회
  Stream<QuerySnapshot> getCheckinsByChecklist(String checklistId) {
    return checkinsCollection
        .where('checklistId', isEqualTo: checklistId)
        .snapshots();
  }

  /// 특정 참가자의 체크인 여부 확인
  Future<bool> isParticipantCheckedIn({
    required String participantId,
    required String checklistId,
  }) async {
    try {
      final snapshot = await checkinsCollection
          .where('participantId', isEqualTo: participantId)
          .where('checklistId', isEqualTo: checklistId)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('체크인 상태 확인 실패: $e');
    }
  }

  /// 참가자 확인 처리 (호스트만 가능)
  /// status를 "confirmed"로 변경하고 confirmedAt 타임스탬프 추가
  Future<void> confirmParticipant(String participantId) async {
    try {
      await participantsCollection.doc(participantId).update({
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('참가자 확인 실패: $e');
    }
  }

  /// 참가자 제거 처리 (호스트만 가능)
  /// status를 "removed"로 변경하고 removedAt 타임스탬프 추가
  Future<void> removeParticipant(String participantId) async {
    try {
      await participantsCollection.doc(participantId).update({
        'status': 'removed',
        'removedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('참가자 제거 실패: $e');
    }
  }
}
