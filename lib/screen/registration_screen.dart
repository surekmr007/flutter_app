import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/screen/profile_screen.dart';
import 'package:mobile_number/mobile_number.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
    List<SimCard> _simCard = <SimCard>[];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _phoneNumberController = TextEditingController();
  final _smsCodeController = TextEditingController();

  String? _verificationId;
  bool _otpSent = false;
  @override
  void initState() {
    super.initState();
    initMobileNumberState();
  }
  
  Future<void> initMobileNumberState() async {
    if (!await MobileNumber.hasPhonePermission) {
      await MobileNumber.requestPhonePermission;
      return;
    }
    try {
      _simCard = (await MobileNumber.getSimCards)!;
      _showNumberPickerDialog();
    } on PlatformException catch (e) {
      debugPrint("Failed to get mobile number because of '${e.message}'");
    }
    if (!mounted) return;
    setState(() {});
  }
  
  Future<void> _showNumberPickerDialog() async {
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: Theme.of(context).copyWith(dialogBackgroundColor: Colors.white),
          child: AlertDialog(
            title: const Text(
              'Select a mobile number',
              style: TextStyle(color: Colors.black), // Set text color to black
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 100.0),
                child: ListView(
                  children: _simCard.map((SimCard sim) {
                    return ListTile(
                      title: Text(
                        sim.number ?? 'Unknown',
                        style: const TextStyle(
                            color: Colors.black), // Set text color to black
                      ),
                      onTap: () {
                        _phoneNumberController.text = sim.number!;
                        Navigator.of(context).pop();
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  Future<void> _registerUser(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          print("Verification failed: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      print("Phone number registration failed: ${e.toString()}");
    }
  }

  Future<void> _verifyOTP(String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      await _auth.signInWithCredential(credential);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
        ),
      );
    } catch (e) {
      print("OTP verification failed: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (!_otpSent)
              TextFormField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Enter your phone number'),
              ),
            if (_otpSent)
              TextFormField(
                controller: _smsCodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Enter OTP'),
              ),
            ElevatedButton(
              onPressed: () {
                if (!_otpSent) {
                  final phoneNumber = _phoneNumberController.text.trim();
                  if (phoneNumber.isNotEmpty) {
                    _registerUser(phoneNumber);
                  }
                } else {
                  final smsCode = _smsCodeController.text.trim();
                  if (smsCode.isNotEmpty) {
                    _verifyOTP(smsCode);
                  }
                }
              },
              child: Text(_otpSent ? 'Verify OTP' : 'Register with Phone Number'),
            ),
          ],
        ),
      ),
    );
  }
}
