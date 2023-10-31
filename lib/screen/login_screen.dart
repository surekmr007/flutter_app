import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/screen/profile_screen.dart';
import 'package:mobile_number/mobile_number.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  List<SimCard> _simCard = <SimCard>[];
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  String? _verificationId;
  bool _otpSent = false;
  bool _resendButtonEnabled = false;

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
              style: TextStyle(color: Colors.black),
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
                        style: const TextStyle(color: Colors.black),
                      ),
                      onTap: () {
                        _mobileController.text = sim.number!;
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
            _resendButtonEnabled = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _resendButtonEnabled = true;
          });
        },
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
        title: const Text('Login Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Enter your mobile number',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your mobile number';
                  }
                  return null;
                },
              ),
              if (_otpSent)
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Enter the OTP',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the OTP';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10,),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    if (!_otpSent) {
                      _registerUser(_mobileController.text);
                    } else {
                      _verifyOTP(_otpController.text);
                    }
                  }
                },
                
                child: Text(_otpSent ? 'Verify OTP' : 'Login'),
              ),
              if (_otpSent)
                ElevatedButton(
                  onPressed: _resendButtonEnabled
                      ? () async {
                          if (_formKey.currentState!.validate()) {
                            _registerUser(_mobileController.text);
                          }
                        }
                      : null,
                  child: const Text('Resend OTP'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
