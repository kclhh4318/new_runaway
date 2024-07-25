import 'package:flutter/material.dart';
import 'package:new_runaway/features/stats/screens/stats_screen.dart';
import 'package:new_runaway/services/auth_service.dart';
import 'package:new_runaway/utils/logger.dart';

class LoginSignupContent extends StatefulWidget {
  const LoginSignupContent({Key? key}) : super(key: key);

  @override
  _LoginSignupContentState createState() => _LoginSignupContentState();
}

class _LoginSignupContentState extends State<LoginSignupContent> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Runaway",
                  style: TextStyle(
                    fontSize: 55,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Giants',
                    fontStyle: FontStyle.italic, // Inline 스타일 적용
                    color: Colors.white, // 텍스트 색상 설정
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  _isLogin ? "로그인" : "회원가입",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                    hintText: "아이디",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSaved: (value) => _username = value ?? '',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '아이디를 입력해주세요';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                    hintText: "패스워드",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSaved: (value) => _password = value ?? '',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '패스워드를 입력해주세요';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isLogin ? "로그인" : "회원가입"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(
                    _isLogin ? "회원가입하기" : "로그인하기",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Map<String, dynamic> result;
      if (_isLogin) {
        result = await _authService.login(_username, _password);
      } else {
        result = await _authService.register(_username, _password);
      }

      logger.info('Auth result: $result');

      if (result['success']) {
        if (_isLogin) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => StatsScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('회원가입에 성공했습니다! 로그인을 시도해보세요.')),
          );
          setState(() {
            _isLogin = true; // 회원가입 후 로그인 모드로 전환
          });
        }
      } else {
        String errorMessage;
        if (_isLogin) {
          errorMessage = '아이디 또는 비밀번호가 잘못 되었습니다. 아이디와 비밀번호를 정확히 입력해 주세요.';
        } else {
          errorMessage = '회원가입에 실패했습니다. 다시 시도해 주세요.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }
}

/*void _submit() {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();
    // 로그인 또는 회원가입 로직 구현 (서버 연동 전까지는 생략)
    print('Username: $_username, Password: $_password, Mode: ${_isLogin ? "Login" : "Sign Up"}');
    // 메인화면으로 이동
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => StatsScreen()),
    );
  }
}*/

/*
void _submit() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();

    Map<String, dynamic> result;
    if (_isLogin) {
      result = await _authService.login(_username, _password);
    } else {
      result = await _authService.register(_username, _password);
    }

    logger.info('Auth result: $result');

    if (result['success']) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => StatsScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'An error occurred')),
      );
    }
  }
}*/
