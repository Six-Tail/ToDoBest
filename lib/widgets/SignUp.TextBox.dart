import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:todobest_home/screen/Login.Screen.dart';
import '../utils/Main.Colors.dart';

class SignUpTextBox extends StatefulWidget {
  const SignUpTextBox({super.key});

  @override
  _SignUpTextBoxState createState() => _SignUpTextBoxState();
}

class _SignUpTextBoxState extends State<SignUpTextBox> {
  final _authentication = FirebaseAuth.instance;
  bool isSignupScreen = true;
  bool _obscureText = true;
  final _formKey = GlobalKey<FormState>();

  String userName = '';
  String userEmail = '';
  String userPassword = '';
  String confirmPassword = '';

  bool isEmailValid = false;
  bool isPasswordValid = false;
  bool isConfirmPasswordValid = false;
  bool isNameValid = false;

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();

  bool _tryValidation() {
    final isValid = _formKey.currentState!.validate();
    if (isValid) {
      _formKey.currentState!.save();
    }
    return isValid;
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration(
      {required String hintText,
        required Icon prefixIcon,
        required bool isValid}) {
    return InputDecoration(
      prefixIcon: prefixIcon,
      hintText: hintText,
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          width: 4.0,
          color: isValid ? Colors.green : Colors.grey,
        ),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          width: 4.0,
          color: isValid ? Colors.green : Colors.black,
        ),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(
          width: 4.0,
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(
          width: 4.0,
          color: Colors.red,
        ),
      ),
      suffixIcon: isValid ? const Icon(Icons.check, color: Colors.green) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 이메일 텍스트 박스
              SizedBox(
                height: 70, // Fixed height for consistency
                child: TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  key: const ValueKey(2),
                  focusNode: _emailFocusNode,
                  validator: (value) {
                    if (value!.isEmpty || !value.contains('@')) {
                      setState(() {
                        isEmailValid = false;
                      });
                      return '올바른 이메일 주소를 입력하세요.';
                    }
                    setState(() {
                      isEmailValid = true;
                    });
                    return null;
                  },
                  onSaved: (value) {
                    userEmail = value!;
                  },
                  onChanged: (value) {
                    setState(() {
                      userEmail = value;
                      isEmailValid = value.isNotEmpty && value.contains('@');
                    });
                  },
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_passwordFocusNode);
                  },
                  decoration: _buildInputDecoration(
                    hintText: '이메일',
                    prefixIcon: const Icon(Icons.email),
                    isValid: isEmailValid,
                  ),
                ),
              ),
              const SizedBox(height: 10.0),
              // 비밀번호 텍스트 박스
              SizedBox(
                height: 70, // Fixed height for consistency
                child: TextFormField(
                  key: const ValueKey(3),
                  focusNode: _passwordFocusNode,
                  validator: (value) {
                    if (value!.isEmpty || value.length < 6) {
                      setState(() {
                        isPasswordValid = false;
                      });
                      return '비밀번호는 6자 이상이어야 합니다.';
                    }
                    setState(() {
                      isPasswordValid = true;
                    });
                    return null;
                  },
                  onSaved: (value) {
                    userPassword = value!;
                  },
                  onChanged: (value) {
                    setState(() {
                      userPassword = value;
                      isPasswordValid = value.isNotEmpty && value.length >= 6;
                    });
                  },
                  onFieldSubmitted: (_) {
                    FocusScope.of(context)
                        .requestFocus(_confirmPasswordFocusNode);
                  },
                  obscureText: _obscureText,
                  decoration: _buildInputDecoration(
                    hintText: '비밀번호',
                    prefixIcon: const Icon(Icons.vpn_key),
                    isValid: isPasswordValid,
                  ).copyWith(
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                              _obscureText ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10.0),
              // 비밀번호 확인 텍스트 박스
              SizedBox(
                height: 70, // Fixed height for consistency
                child: TextFormField(
                  key: const ValueKey(4),
                  focusNode: _confirmPasswordFocusNode,
                  validator: (value) {
                    if (value!.isEmpty || value != userPassword) {
                      setState(() {
                        isConfirmPasswordValid = false;
                      });
                      return '비밀번호가 일치하지 않습니다.';
                    }
                    setState(() {
                      isConfirmPasswordValid = true;
                    });
                    return null;
                  },
                  onSaved: (value) {
                    confirmPassword = value!;
                  },
                  onChanged: (value) {
                    setState(() {
                      confirmPassword = value;
                      isConfirmPasswordValid =
                          value.isNotEmpty && value == userPassword;
                    });
                  },
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_nameFocusNode);
                  },
                  obscureText: _obscureText,
                  decoration: _buildInputDecoration(
                    hintText: '비밀번호 확인',
                    prefixIcon: const Icon(Icons.vpn_key),
                    isValid: isConfirmPasswordValid,
                  ),
                ),
              ),
              const SizedBox(height: 10.0),
              // 닉네임 텍스트 박스
              SizedBox(
                height: 70, // Fixed height for consistency
                child: TextFormField(
                  key: const ValueKey(1),
                  focusNode: _nameFocusNode,
                  validator: (value) {
                    if (value!.isEmpty || value.length < 2) {
                      setState(() {
                        isNameValid = false;
                      });
                      return '닉네임은 2자 이상이어야 합니다.';
                    }
                    setState(() {
                      isNameValid = true;
                    });
                    return null;
                  },
                  onSaved: (value) {
                    userName = value!;
                  },
                  onChanged: (value) {
                    setState(() {
                      userName = value;
                      isNameValid = value.isNotEmpty && value.length >= 2;
                    });
                  },
                  decoration: _buildInputDecoration(
                    hintText: '닉네임',
                    prefixIcon: const Icon(Icons.person),
                    isValid: isNameValid,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.06),
              GestureDetector(
                onTap: () async {
                  if (isSignupScreen && _tryValidation()) {
                    try {
                      final newUser = await _authentication
                          .createUserWithEmailAndPassword(
                        email: userEmail,
                        password: userPassword,
                      );

                      if (newUser.user != null) {
                        Get.to(() => const LoginScreen());
                      }
                    } catch (e) {
                      if (kDebugMode) {
                        print(e);
                      }
                    }
                  }
                },
                child: Container(
                  alignment: Alignment.center,
                  height: screenHeight * 0.068,
                  width: screenWidth * 0.8,
                  decoration: ShapeDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment(0.98, -0.18),
                      end: Alignment(-0.98, 0.18),
                      colors: [
                        Color(0xFFFBDD94),
                        Color(0xFFFDB082),
                        Color(0xFFE05C41)
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(33),
                    ),
                  ),
                  child: Text(
                    '새로운 계정 만들기',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: MainColors.mainColor,
                      fontSize: screenHeight * 0.022,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.25,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
