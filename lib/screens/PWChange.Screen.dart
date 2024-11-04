import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PWChangeScreen extends StatefulWidget {
  @override
  _PWChangeScreenState createState() => _PWChangeScreenState();
}

class _PWChangeScreenState extends State<PWChangeScreen> {
  final _auth = FirebaseAuth.instance;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // 비밀번호 변경 함수
  Future<void> _changePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        User? user = _auth.currentUser;

        // 현재 비밀번호 확인을 위한 재인증
        final cred = EmailAuthProvider.credential(
          email: user?.email ?? "",
          password: _currentPasswordController.text,
        );
        await user?.reauthenticateWithCredential(cred);

        // 새 비밀번호 업데이트
        if (_newPasswordController.text == _confirmNewPasswordController.text) {
          await user?.updatePassword(_newPasswordController.text);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("비밀번호가 성공적으로 변경되었습니다.")),
          );
          Navigator.pop(context); // 화면 종료
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("새 비밀번호가 일치하지 않습니다.")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("비밀번호 변경 실패: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('비밀번호 변경'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: '현재 비밀번호'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '현재 비밀번호를 입력하세요';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: '새 비밀번호'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '새 비밀번호를 입력하세요';
                  } else if (value.length < 6) {
                    return '비밀번호는 최소 6자 이상이어야 합니다';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _confirmNewPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: '새 비밀번호 확인'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '새 비밀번호를 다시 입력하세요';
                  } else if (value != _newPasswordController.text) {
                    return '새 비밀번호가 일치하지 않습니다';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _changePassword,
                child: Text('비밀번호 변경'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}