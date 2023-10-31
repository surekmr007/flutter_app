import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
                width: 250, height: 250, image: AssetImage('assets/icon.png')),
            SizedBox(
              height: 18,
            ),
            Text('Welcome to the Page..'),
          ],
        ),
      ),
    );
  }
}
