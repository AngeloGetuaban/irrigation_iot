import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dashboard.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class Plant {
  final String id;
  final double temp;
  final double humi;
  final double moist;
  final int water_state;

  Plant({
    required this.id,
    required this.temp,
    required this.humi,
    required this.moist,
    required this.water_state,
  });
}

class FirestoreService {
  final CollectionReference plantsCollection =
  FirebaseFirestore.instance.collection('plants');

  Stream<List<Plant>> getAllPlants() {
    return plantsCollection.snapshots().map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        var plantData = doc.data() as Map<String, dynamic>?;

        if (plantData != null &&
            plantData['temp'] is String &&
            plantData['humi'] is String &&
            plantData['moist'] is String &&
            plantData['water_state'] != null) {
          return Plant(
            id: doc.id,
            temp: double.tryParse(plantData['temp']) ?? 0.0,
            humi: double.tryParse(plantData['humi']) ?? 0.0,
            moist: double.tryParse(plantData['moist']) ?? 0.0,
            water_state: plantData['water_state'],
          );
        } else {
          return Plant(
            id: '',
            temp: 0.0,
            humi: 0.0,
            moist: 0.0,
            water_state: 0,
          );
        }
      }).toList();
    });
  }

  Future<void> toggleWaterState(String plantId, int currentWaterState) async {
    await plantsCollection.doc(plantId).update({
      'water_state': currentWaterState == 0 ? 1 : 0,
    });
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase Example',
      home: Dashboard(),
    );
  }
}