import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart';

class HumidityRecordsPage extends StatefulWidget {
  final String plantId;

  HumidityRecordsPage({required this.plantId});

  @override
  State<HumidityRecordsPage> createState() => _HumidityRecordsPageState();
}

class _HumidityRecordsPageState extends State<HumidityRecordsPage> {
  final FirestoreService firestoreService = FirestoreService();

  late Future<List<Map<String, dynamic>>> humiRecords;

  @override
  void initState() {
    super.initState();
    humiRecords = fetchHumidityRecords(widget.plantId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Humidity Records'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: humiRecords,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No humidity records available.'));
          } else {
            List<Map<String, dynamic>> humiRecords = snapshot.data!;

            return ListView.builder(
              itemCount: humiRecords.length,
              itemBuilder: (context, index) {
                String humidity = humiRecords[index]['humidity'].toString();

                return ListTile(
                  title: Text("Humidity: $humidity"),
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchHumidityRecords(String plantId) async {
    try {
      // Call the method from your FirestoreService to fetch humidity records
      List<Map<String, dynamic>> records = await firestoreService.fetchHumidityRecords(plantId);
      return records;
    } catch (e) {
      print('Error fetching humidity records: $e');
      return [];
    }
  }
}
