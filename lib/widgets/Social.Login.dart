import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import 추가
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todobest_home/Router.dart';
import 'package:uni_links2/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialLogin extends StatefulWidget {
  const SocialLogin({super.key});

  @override
  State<SocialLogin> createState() => _SocialLoginState();
}

class _SocialLoginState extends State<SocialLogin> {
  StreamSubscription<String?>? _linkSubscription;
  bool isLoginAttempt = false;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
    if (isLoggedIn) {
      navigatorToMainPage();
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final iconSize = screenWidth * 0.14;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                await signInWithGoogle();
              },
              child: SocialIcon(
                assetName: 'assets/images/google.svg',
                iconSize: iconSize,
              ),
            ),
            GestureDetector(
              onTap: () async {
                await signInWithKakao();
              },
              child: SocialIcon(
                assetName: 'assets/images/kakao.svg',
                iconSize: iconSize,
              ),
            ),
            GestureDetector(
              onTap: () async {
                await signInWithNaver();
              },
              child: SocialIcon(
                assetName: 'assets/images/naver.svg',
                iconSize: iconSize,
              ),
            ),
          ],
        ),
        SizedBox(height: screenHeight * 0.03),
        const Text(
          '간편 로그인',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black26,
            fontSize: 13,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
            height: 1,
            letterSpacing: 0.25,
          ),
        ),
      ],
    );
  }

  void navigatorToMainPage() {
    Get.off(() => RouterPage());
  }

  Future<void> signInWithNaver() async {
    setState(() {
      isLoginAttempt = true;
    });
    String clientID = '3zEWgueywUQAaMf0tcK7';
    String redirectUri =
        'https://us-central1-to-do-best-72308.cloudfunctions.net/naverLoginCallback';
    String state = base64Url.encode(List<int>.generate(16, (_) => Random().nextInt(255)));
    Uri url = Uri.parse(
        'https://nid.naver.com/oauth2.0/authorize?response_type=code&client_id=$clientID&redirect_uri=$redirectUri&state=$state');

    if (kDebugMode) {
      print("네이버 로그인 요청: $url");
    }

    await launchUrl(url);
    await initUniLinks();
  }

  Future<void> initUniLinks() async {
    final initialLink = await getInitialLink();
    if (initialLink != null) _handleDeepLink(initialLink);
    _linkSubscription = linkStream.listen((String? link) {
      if (isLoginAttempt) {
        _handleDeepLink(link!);
      }
    }, onError: (err) {
      if (kDebugMode) {
        print("딥링크 수신 오류: $err");
      }
    });
  }

  Future<void> _handleDeepLink(String link) async {
    if (kDebugMode) {
      print("딥링크 수신: $link");
    }
    final Uri uri = Uri.parse(link);
    if (uri.authority == 'login-callback') {
      String? firebaseToken = uri.queryParameters['firebaseToken'];
      String? name = uri.queryParameters['name'];
      String? profileImage = uri.queryParameters['profileImage'];

      await firebase_auth.FirebaseAuth.instance.signInWithCustomToken(firebaseToken!).then((value) async {
        final firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updateDisplayName(name);
          await user.updatePhotoURL(profileImage);

          await saveUserToFirestore(user.uid, name, profileImage); // Firestore에 사용자 정보 저장

          if (kDebugMode) {
            print("네이버 로그인 성공: ${user.email}, UID: ${user.uid}");
          }
          await _saveLoginState();
          navigatorToMainPage();
        }
      }).onError((error, stackTrace) {
        if (kDebugMode) {
          print("네이버 로그인 실패: $error");
        }
        setState(() {
          isLoginAttempt = false;
        });
      });
    }
  }

  Future<void> saveUserToFirestore(String uid, String? name, String? profileImage) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      await userRef.set({
        'userName': name ?? '',
        'userImage': profileImage ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        print("사용자 정보가 Firestore에 저장되었습니다.");
      }
    } else {
      if (kDebugMode) {
        print("Firestore에 이미 사용자 정보가 존재합니다.");
      }
    }
  }

  Future<void> signInWithKakao() async {
    setState(() {
      isLoginAttempt = true;
    });

    if (await kakao.isKakaoTalkInstalled()) {
      try {
        await kakao.UserApi.instance.loginWithKakaoTalk().then((value) async {
          await _handleSuccessfulLogin(value);
        });
      } catch (error) {
        setState(() {
          isLoginAttempt = false;
        });
      }
    } else {
      try {
        kakao.OAuthToken token = await kakao.UserApi.instance.loginWithKakaoAccount();
        await _handleSuccessfulLogin(token);
      } catch (error) {
        setState(() {
          isLoginAttempt = false;
        });
      }
    }

    try {
      kakao.User user = await kakao.UserApi.instance.me();
      firebase_auth.User? currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        if (user.kakaoAccount?.email != null) {
          await currentUser.verifyBeforeUpdateEmail(user.kakaoAccount!.email!);
        }
        if (user.kakaoAccount?.profile?.nickname != null) {
          await currentUser.updateDisplayName(user.kakaoAccount!.profile!.nickname!);
        }
        if (user.kakaoAccount?.profile?.profileImageUrl != null) {
          await currentUser.updatePhotoURL(user.kakaoAccount!.profile!.profileImageUrl);
        }
        await saveUserToFirestore(
          currentUser.uid,
          user.kakaoAccount?.profile?.nickname,
          user.kakaoAccount?.profile?.profileImageUrl,
        );
        if (kDebugMode) {
          print('Firebase 사용자 프로필 업데이트 및 Firestore에 저장 완료');
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('사용자 정보 요청 또는 Firebase 프로필 업데이트 실패: $error');
      }
    }

    initUniLinks();
  }

  Future<void> _handleSuccessfulLogin(kakao.OAuthToken token) async {
    try {
      var provider = firebase_auth.OAuthProvider('oidc.todobest');
      var credential = provider.credential(
        idToken: token.idToken,
        accessToken: token.accessToken,
      );

      await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
      await _saveLoginState();

      final firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await saveUserToFirestore(user.uid, user.displayName, user.photoURL);
        if (kDebugMode) {
          print('카카오 계정 Firestore 저장 성공');
        }
      }
      navigatorToMainPage();
    } catch (error) {
      setState(() {
        isLoginAttempt = false;
      });
    }
  }

  Future<void> signInWithGoogle() async {
    setState(() {
      isLoginAttempt = true;
    });
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
      if (googleAuth == null) {
        setState(() {
          isLoginAttempt = false;
        });
        return;
      }
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
      await _saveLoginState();

      final firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await saveUserToFirestore(user.uid, user.displayName, user.photoURL);
        if (kDebugMode) {
          print('Google Firestore 저장 성공');
        }
      }
      navigatorToMainPage();
    } catch (error) {
      if (kDebugMode) {
        print('Google 로그인 실패 $error');
      }
    }
  }

  Future<void> _saveLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await firebase_auth.FirebaseAuth.instance.signOut();
  }
}

class SocialIcon extends StatelessWidget {
  final String assetName;
  final double iconSize;

  const SocialIcon({
    required this.assetName,
    required this.iconSize,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      width: iconSize,
      height: iconSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 2),
            blurRadius: 0.6,
          ),
        ],
      ),
      child: SvgPicture.asset(
        assetName,
        fit: BoxFit.cover,
      ),
    );
  }
}

/*
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 추가된 부분
import 'package:todobest_home/Router.dart';
import 'package:uni_links2/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialLogin extends StatefulWidget {
  const SocialLogin({super.key});

  @override
  State<SocialLogin> createState() => _SocialLoginState();
}

class _SocialLoginState extends State<SocialLogin> {
  StreamSubscription<String?>? _linkSubscription;
  bool isLoginAttempt = false; // 로그인 시도 여부
  bool isLoggedIn = false; // 로그인 상태 여부

  @override
  void initState() {
    super.initState();
    checkLoginStatus(); // 앱 시작 시 로그인 상태 확인
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
    if (isLoggedIn) {
      navigatorToMainPage(); // 이미 로그인된 경우 메인 페이지로 이동
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final iconSize = screenWidth * 0.14; // 아이콘 크기 조정

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                await signInWithGoogle();
              },
              child: SocialIcon(
                assetName: 'assets/images/google.svg',
                iconSize: iconSize,
              ),
            ),
            GestureDetector(
              onTap: () async {
                await signInWithKakao();
              },
              child: SocialIcon(
                assetName: 'assets/images/kakao.svg',
                iconSize: iconSize,
              ),
            ),
            GestureDetector(
              onTap: () async {
                await signInWithNaver();
                // Naver 로그인 기능 추가
                if (kDebugMode) {
                  print('naver');
                }
              },
              child: SocialIcon(
                assetName: 'assets/images/naver.svg',
                iconSize: iconSize,
              ),
            ),
          ],
        ),
        SizedBox(height: screenHeight * 0.03),
        const Text(
          '간편 로그인',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black26,
            fontSize: 13,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w700,
            height: 1,
            letterSpacing: 0.25,
          ),
        ),
      ],
    );
  }

  void navigatorToMainPage() {
    Get.off(() => RouterPage());
  }

  Future<void> signInWithNaver() async {
    setState(() {
      isLoginAttempt = true; // 로그인 시도 상태를 true로 설정
    });
    String clientID = '3zEWgueywUQAaMf0tcK7';
    String redirectUri =
        'https://us-central1-to-do-best-72308.cloudfunctions.net/naverLoginCallback';
    String state =
    base64Url.encode(List<int>.generate(16, (_) => Random().nextInt(255)));
    Uri url = Uri.parse(
        'https://nid.naver.com/oauth2.0/authorize?response_type=code&client_id=$clientID&redirect_uri=$redirectUri&state=$state');
    if (kDebugMode) {
      print("네이버 로그인 열기 & 클라우드 함수 호출");
    }
    await launchUrl(url);
    initUniLinks();
  }

  Future<void> initUniLinks() async {
    final initialLink = await getInitialLink();
    if (initialLink != null) _handleDeepLink(initialLink);
    _linkSubscription = linkStream.listen((String? link) {
      if (isLoginAttempt) {
        // 로그인 시도가 활성화되어 있는 경우 딥링크 처리
        _handleDeepLink(link!);
      }
    }, onError: (err, stacktrace) {
      if (kDebugMode) {
        print("딥링크 에러 $err\n$stacktrace");
      }
    });
  }

  Future<void> _handleDeepLink(String link) async {
    if (kDebugMode) {
      print("딥링크 열기 $link");
    }
    final Uri uri = Uri.parse(link);
    if (uri.authority == 'login-callback') {
      String? firebaseToken = uri.queryParameters['firebaseToken'];
      String? name = uri.queryParameters['name'];
      String? email = uri.queryParameters['email'];
      String? profileImage = uri.queryParameters['profileImage'];

      if (kDebugMode) {
        print("name $name");
        print("email $email");
        print("profileImage $profileImage");
      }

      try {
        final auth = FirebaseAuth.instance;

        // 이메일 중복 체크 및 처리
        final signInMethods = await auth.fetchSignInMethodsForEmail(email!);
        if (signInMethods.isNotEmpty) {
          // 이메일이 이미 Firebase에 존재하는 경우
          if (kDebugMode) {
            print("이미 존재하는 이메일입니다. 기존 계정과 연결합니다.");
          }

          final userCredential = await auth.signInWithCredential(
            EmailAuthProvider.credential(email: email, password: '비밀번호'), // 기존 계정의 비밀번호를 알아야 합니다.
          );

          if (userCredential.user != null) {
            if (kDebugMode) {
              print("기존 계정으로 로그인 성공");
              print("사용자 UID: ${userCredential.user!.uid}");
            }
          }
        } else {
          // 이메일이 존재하지 않는 경우
          await auth.signInWithCustomToken(firebaseToken!).then((value) {
            final user = auth.currentUser;
            if (user != null && kDebugMode) {
              if (kDebugMode) {
                print("네이버 로그인 성공");
                print("사용자 UID: ${user.uid}");
                print("사용자 이메일: ${user.email ?? '이메일 없음'}");
                print("사용자 이름: ${user.displayName ?? name ?? '이름 없음'}");
              }
            }
          });
        }
        navigatorToMainPage();
        setState(() {
          isLoginAttempt = false; // 로그인 시도 상태 초기화
        });
      } catch (error) {
        if (kDebugMode) {
          print("네이버 로그인 실패 $error");
        }
        setState(() {
          isLoginAttempt = false; // 로그인 시도 상태 초기화
        });
      }
    }
  }


  Future<void> signInWithKakao() async {
    setState(() {
      isLoginAttempt = true; // 로그인 시도 상태를 true로 설정
    });

    if (await isKakaoTalkInstalled()) {
      try {
        await UserApi.instance.loginWithKakaoTalk().then((value) async {
          await _handleSuccessfulLogin(value); // 성공적인 로그인 처리
        });
      } catch (error) {
        if (kDebugMode) {
          print('카카오톡으로 로그인 실패 $error');
        }
        if (error is PlatformException && error.code == 'CANCELED') {
          setState(() {
            isLoginAttempt = false; // 로그인 시도 상태를 초기화
          });
          return;
        }

        try {
          await UserApi.instance.loginWithKakaoAccount().then((value) async {
            await _handleSuccessfulLogin(value); // 성공적인 로그인 처리
          });
        } catch (error) {
          if (kDebugMode) {
            print('카카오계정으로 로그인 실패 $error');
          }
          setState(() {
            isLoginAttempt = false; // 로그인 시도 상태를 초기화
          });
        }
      }
    } else {
      try {
        OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
        await _handleSuccessfulLogin(token); // 성공적인 로그인 처리
      } catch (error) {
        if (kDebugMode) {
          print('카카오계정으로 로그인 실패 $error');
        }
        setState(() {
          isLoginAttempt = false; // 로그인 시도 상태를 초기화
        });
      }
    }
    initUniLinks();
  }

  Future<void> _handleSuccessfulLogin(OAuthToken token) async {
    try {
      // 로그인 상태를 SharedPreferences에 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      var provider = OAuthProvider('oidc.todobest');
      var credential = provider.credential(
        idToken: token.idToken,
        accessToken: token.accessToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null && kDebugMode) {
        if (kDebugMode) {
          print('카카오 계정 로그인 성공');
          print('사용자 UID: ${user.uid}');
          print('사용자 이메일: ${user.email ?? "이메일 없음"}');
          print('사용자 이름: ${user.displayName ?? "이름 없음"}');
        }
      }

      navigatorToMainPage();
      setState(() {
        isLoginAttempt = false; // 로그인 시도 상태를 초기화
      });
    } catch (error) {
      if (kDebugMode) {
        print('카카오 계정 로그인 실패 $error');
      }
      setState(() {
        isLoginAttempt = false; // 로그인 시도 상태를 초기화
      });
    }
  }

  Future<void> signInWithGoogle() async {
    setState(() {
      isLoginAttempt = true; // 로그인 시도 상태를 true로 설정
    });
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      if (googleAuth == null) {
        setState(() {
          isLoginAttempt = false; // 로그인 시도 상태를 초기화
        });
        return;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null && kDebugMode) {
        if (kDebugMode) {
          print('Google 로그인 성공');
          print('사용자 UID: ${user.uid}');
          print('사용자 이메일: ${user.email ?? "이메일 없음"}');
          print('사용자 이름: ${user.displayName ?? "이름 없음"}');
        }
      }

      navigatorToMainPage();
    } catch (error) {
      if (kDebugMode) {
        print('Google 로그인 실패 $error');
      }
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // 로그인 상태 초기화
    await FirebaseAuth.instance.signOut(); // Firebase에서 로그아웃
    // 필요시 Kakao에서도 로그아웃 처리
  }
}

class SocialIcon extends StatelessWidget {
  final String assetName;
  final double iconSize;

  const SocialIcon({
    required this.assetName,
    required this.iconSize,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      width: iconSize,
      height: iconSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 2),
            blurRadius: 0.6,
          ),
        ],
      ),
      child: SvgPicture.asset(
        assetName,
        fit: BoxFit.cover,
      ),
    );
  }
}
*/