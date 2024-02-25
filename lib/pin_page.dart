import 'package:flutter/material.dart';
import 'main.dart';

class PinPage extends StatefulWidget {
  const PinPage({super.key});

  @override
  _PinPageState createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  TextEditingController pinController = TextEditingController();
  final String documentId = "Lpwoehp7wjCoQcbRUNo1"; // Replace with your actual document ID

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text(
                'Welcome to                   Smart Irrigation System Dashboard',
                style: TextStyle(fontSize: 35),
                textAlign: TextAlign.center,
              ),
            ),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Please enter your PIN',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Call the function to compare and update PIN
                compareAndCopyPin(pinController.text, context);
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  void compareAndCopyPin(String userEnteredPin, BuildContext context) async {
    String newPinValue = await FirestoreService().getNewPinValue(documentId);

    if (userEnteredPin == newPinValue) {
      await FirestoreService()
          .updatePrevPinAndNavigate(documentId, newPinValue, context);
      showSnackBar('Succesfully logged in!');
    } else {
      showSnackBar('Incorrect Pin, Please Try Again');
    }
  }
}
