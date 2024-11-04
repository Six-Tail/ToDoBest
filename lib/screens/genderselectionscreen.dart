// GenderSelectionScreen.dart
import 'package:flutter/material.dart';
import '../service/User_Service.dart'; // UserService import
import 'package:firebase_auth/firebase_auth.dart';

class GenderSelectionScreen extends StatefulWidget {
  final String currentGender;

  GenderSelectionScreen({required this.currentGender});

  @override
  _GenderSelectionScreenState createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen> {
  late String selectedGender;
  final UserService _userService = UserService(); // UserService 인스턴스 생성
  final User? _firebaseUser = FirebaseAuth.instance.currentUser; // 현재 사용자 가져오기

  @override
  void initState() {
    super.initState();
    selectedGender = widget.currentGender;
  }

  Future<void> _updateGender() async {
    if (_firebaseUser != null) {
      // Firebase에 성별 업데이트
      await _userService.updateUserInfo(_firebaseUser!.uid, gender: selectedGender);
      Navigator.pop(context, selectedGender); // 선택한 성별을 반환하며 화면 닫기
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ToDoBest계정'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '성별을 알려 주세요.',
              style: TextStyle(fontSize: 16),
            ),
            RadioListTile<String>(
              title: Text('여성'),
              value: '여성',
              groupValue: selectedGender,
              onChanged: (value) {
                setState(() {
                  selectedGender = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: Text('남성'),
              value: '남성',
              groupValue: selectedGender,
              onChanged: (value) {
                setState(() {
                  selectedGender = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: Text('선택안함'),
              value: '선택안함',
              groupValue: selectedGender,
              onChanged: (value) {
                setState(() {
                  selectedGender = value!;
                });
              },
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.yellow, // 버튼 텍스트 색상
                  minimumSize: Size(double.infinity, 50), // 버튼 크기
                ),
                onPressed: _updateGender, // 성별 업데이트 함수 호출
                child: Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}