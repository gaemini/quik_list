import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Firebase Authentication을 관리하는 서비스 클래스
/// 회원가입, 로그인, 로그아웃, 현재 사용자 조회 기능 제공
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// 현재 로그인된 사용자 조회
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// 인증 상태 변경을 실시간으로 감지하는 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 이메일과 비밀번호로 회원가입
  /// 
  /// [email] 사용자 이메일
  /// [password] 사용자 비밀번호 (최소 6자)
  /// 
  /// Returns: 생성된 사용자의 UserCredential
  /// Throws: FirebaseAuthException - 회원가입 실패 시
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// 이메일과 비밀번호로 로그인
  /// 
  /// [email] 사용자 이메일
  /// [password] 사용자 비밀번호
  /// 
  /// Returns: 로그인한 사용자의 UserCredential
  /// Throws: FirebaseAuthException - 로그인 실패 시
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// 현재 사용자 로그아웃
  /// 
  /// Throws: FirebaseAuthException - 로그아웃 실패 시
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Google 계정으로 로그인
  /// 
  /// Returns: 로그인한 사용자의 UserCredential
  /// Throws: Exception - 로그인 실패 시
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google 로그인이 취소되었습니다.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Google 로그인 실패: $e');
    }
  }

  /// Apple 계정으로 로그인 (iOS 전용)
  /// 
  /// Returns: 로그인한 사용자의 UserCredential
  /// Throws: Exception - 로그인 실패 시
  Future<UserCredential> signInWithApple() async {
    if (!Platform.isIOS) {
      throw Exception('Apple 로그인은 iOS에서만 사용 가능합니다.');
    }

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oAuthProvider = OAuthProvider('apple.com');
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      return await _auth.signInWithCredential(credential);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw Exception('Apple 로그인이 취소되었습니다.');
      }
      throw Exception('Apple 로그인 실패: ${e.message}');
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Apple 로그인 실패: $e');
    }
  }

  /// 사용자 프로필이 완성되었는지 확인
  /// 
  /// [uid] 사용자 고유 ID
  /// Returns: 프로필 존재 여부
  Future<bool> isProfileComplete(String uid) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('users').doc(uid).get();
      
      if (!doc.exists) {
        return false;
      }
      
      final data = doc.data();
      if (data == null) return false;
      
      // 필수 필드 확인
      return data.containsKey('name') &&
             data.containsKey('major') &&
             data.containsKey('grade') &&
             data.containsKey('phone') &&
             data.containsKey('nationality') &&
             data['name'] != null &&
             data['major'] != null &&
             data['grade'] != null &&
             data['phone'] != null &&
             data['nationality'] != null;
    } catch (e) {
      return false;
    }
  }

  /// FirebaseAuthException을 처리하여 한글 메시지 반환
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return '비밀번호가 너무 약합니다. 최소 6자 이상 입력해주세요.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'invalid-email':
        return '유효하지 않은 이메일 형식입니다.';
      case 'user-not-found':
        return '등록되지 않은 사용자입니다.';
      case 'wrong-password':
        return '비밀번호가 올바르지 않습니다.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'too-many-requests':
        return '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
      case 'operation-not-allowed':
        return '이메일/비밀번호 로그인이 활성화되지 않았습니다.';
      default:
        return '인증 오류가 발생했습니다: ${e.message}';
    }
  }
}
