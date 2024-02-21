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
  final int water_duration;

  Plant({
    required this.id,
    required this.temp,
    required this.humi,
    required this.moist,
    required this.water_state,
    required this.water_duration
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
            water_duration: plantData['water_duration']
          );
        } else {
          return Plant(
            id: '',
            temp: 0.0,
            humi: 0.0,
            moist: 0.0,
            water_state: 0,
            water_duration: 0,
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
  Future<void> recordWateringEvent(String plantId, String dateTime, int waterDuration) async {
    try {
      // Get the current date and time
      DateTime now = DateTime.now();
      String formattedDateTime = "${now.toLocal()}".split(' ')[0] +
          " ${now.hour}:${now.minute}:${now.second}";

      // Update the Firestore document with the recorded humidity information
      await plantsCollection.doc(plantId).update({
        'time_record': FieldValue.arrayUnion([
          {'water_record': "${dateTime}, for $waterDuration seconds"}
        ])
      });
    } catch (e) {
      print('Error saving humidity record: $e');
    }
  }
  Future<List<Map<String, dynamic>>> fetchWaterRecords(String plantId) async {
    try {
      // Get the reference to the plant document
      DocumentSnapshot<Map<String, dynamic>> plantSnapshot =
      await plantsCollection.doc(plantId).get() as DocumentSnapshot<Map<String, dynamic>>;

      // Get the humidity events array
      List<dynamic>? waterEvents = plantSnapshot.data()?['time_record'];

      // Return the array, or an empty list if it's null
      if (waterEvents != null) {
        List<Map<String, dynamic>> waterRecords =
        List<Map<String, dynamic>>.from(waterEvents);
        return waterRecords;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching water records: $e');
      return [];
    }
  }
  Future<List<Map<String, dynamic>>> fetchHumidityRecords(String plantId) async {
    try {
      // Get the reference to the plant document
      DocumentSnapshot<Map<String, dynamic>> plantSnapshot =
      await plantsCollection.doc(plantId).get() as DocumentSnapshot<Map<String, dynamic>>;

      // Get the humidity events array
      List<dynamic>? humiEvents = plantSnapshot.data()?['humi_record'];

      // Return the array, or an empty list if it's null
      if (humiEvents != null) {
        List<Map<String, dynamic>> humidityRecords =
        List<Map<String, dynamic>>.from(humiEvents);
        return humidityRecords;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching humidity records: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchTemperatureRecords(String plantId) async {
    try {
      // Get the reference to the plant document
      DocumentSnapshot<Map<String, dynamic>> plantSnapshot =
      await plantsCollection.doc(plantId).get() as DocumentSnapshot<Map<String, dynamic>>;

      // Get the humidity events array
      List<dynamic>? tempEvents = plantSnapshot.data()?['temp_record'];

      // Return the array, or an empty list if it's null
      if (tempEvents != null) {
        List<Map<String, dynamic>> temperatureRecords =
        List<Map<String, dynamic>>.from(tempEvents);
        return temperatureRecords;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching temp records: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchMoistRecords(String plantId) async {
    try {
      // Get the reference to the plant document
      DocumentSnapshot<Map<String, dynamic>> plantSnapshot =
      await plantsCollection.doc(plantId).get() as DocumentSnapshot<Map<String, dynamic>>;

      // Get the humidity events array
      List<dynamic>? moistEvents = plantSnapshot.data()?['moist_record'];

      // Return the array, or an empty list if it's null
      if (moistEvents != null) {
        List<Map<String, dynamic>> moistRecords =
        List<Map<String, dynamic>>.from(moistEvents);
        return moistRecords;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching temp records: $e');
      return [];
    }
  }
  Future<void> saveHumidityRecord(String plantId, double humidity) async {
    try {
      // Get the current date and time
      DateTime now = DateTime.now();
      String formattedDateTime = "${now.toLocal()}".split(' ')[0] +
          " ${now.hour}:${now.minute}:${now.second}";

      // Update the Firestore document with the recorded humidity information
      await plantsCollection.doc(plantId).update({
        'humi_record': FieldValue.arrayUnion([
          {'humidity': "${humidity}%, Recorded on $formattedDateTime"}
        ])
      });
    } catch (e) {
      print('Error saving humidity record: $e');
    }
  }

  Future<void> saveTemperatureRecord(String plantId, double temp) async {
    try {
      // Get the current date and time
      DateTime now = DateTime.now();
      String formattedDateTime = "${now.toLocal()}".split(' ')[0] +
          " ${now.hour}:${now.minute}:${now.second}";
      await plantsCollection.doc(plantId).update({
        'temp_record': FieldValue.arrayUnion([
          {'temp': "${temp}°C, Recorded on $formattedDateTime"}
        ])
      });
    } catch (e) {
      print('Error saving temp record: $e');
    }
  }
  Future<void> updateWaterDurationInFirestore(int newWaterDuration) async {
    await FirebaseFirestore.instance
        .collection('plants')
        .doc("Lpwoehp7wjCoQcbRUNo1")
        .update({'water_duration': newWaterDuration});
  }
  Future<void> updatePhoneNumberInFirestore(String phoneNumber) async {
    await FirebaseFirestore.instance
        .collection('plants')
        .doc("Lpwoehp7wjCoQcbRUNo1")
        .update({'phone_number': phoneNumber});
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