import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
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
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final FirebaseAuth _auth = FirebaseAuth.instance;
                    final User? user = _auth.currentUser;
                    if (user != null &&
                        user.phoneNumber == _mobileController.text) {
                      Navigator.of(context).pushReplacementNamed('/profile');
                    } else {
                      Navigator.of(context).pushReplacementNamed('/register');
                    }
                  }
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
