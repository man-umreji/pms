import 'package:flutter/material.dart';

class SubmitFirstLogin extends StatefulWidget {
  const SubmitFirstLogin({super.key, String? token, String? userId, String? email});

  @override
  State<SubmitFirstLogin> createState() => _SubmitFirstLoginState();
}

class _SubmitFirstLoginState extends State<SubmitFirstLogin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("data"),
      ),
    );
  }
}
