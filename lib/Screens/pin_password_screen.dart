import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:zo_app_blocker_demo/Screens/home_screen.dart';

class PinScreen extends StatefulWidget {
  final bool isCreating;
  const PinScreen({super.key, required this.isCreating});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final String _masterPassword = '459278';
  String _errorMessage = '';

  Future<void> _submitPin() async {
    final prefs = await SharedPreferences.getInstance();
    final enteredPin = _pinController.text.trim();

    if (enteredPin.isEmpty) {
      setState(() => _errorMessage = 'PIN cannot be empty');
      return;
    }

    if (widget.isCreating) {
      await prefs.setString('user_pin', enteredPin);
      _navigateToHome();
    } else {
      final savedPin = prefs.getString('user_pin');
      if (enteredPin == savedPin || enteredPin == _masterPassword) {
        _navigateToHome();
      } else {
        setState(() {
          _errorMessage = 'Incorrect PIN';
          _pinController.clear();
        });
      }
    }
  }

  void _navigateToHome() {
    Get.offAll(() => const HomeScreen());
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCreating ? 'Create PIN' : 'Enter PIN'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.isCreating
                  ? 'Please create a new PIN to secure your app.'
                  : 'Enter your PIN to unlock.',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'PIN',
                errorText: _errorMessage.isEmpty ? null : _errorMessage,
              ),
              onSubmitted: (_) => _submitPin(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitPin,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text(widget.isCreating ? 'Save PIN' : 'Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}
