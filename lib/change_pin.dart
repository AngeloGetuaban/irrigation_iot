import 'package:flutter/material.dart';
import 'main.dart';

class ChangePinPage extends StatefulWidget {
  @override
  _ChangePinPageState createState() => _ChangePinPageState();
}

class _ChangePinPageState extends State<ChangePinPage> {
  final FirestoreService firestoreService = FirestoreService();
  TextEditingController newPinController = TextEditingController();
  TextEditingController confirmPinController = TextEditingController();

  void updatePinInFirestore(String newPin) async {
    await firestoreService.updateNewPinInFirestore(confirmPinController.text);
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void changePin() {
    String newPin = newPinController.text;
    String confirmPin = confirmPinController.text;

    if (newPin == confirmPin) {
      // The new pin and confirm pin match, update in Firestore
      updatePinInFirestore(newPin);
      Navigator.of(context).pop();
      showSnackBar('Pin successfully updated, Please enter your pin!');
    } else {
      // The new pin and confirm pin do not match
      showSnackBar('Pin does not match. Please try again!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Pin'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: newPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Enter New Pin',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Pin',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: changePin,
              child: Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
