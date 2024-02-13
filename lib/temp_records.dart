import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart';

class TemperatureRecordsPage extends StatefulWidget {
  final String plantId;

  TemperatureRecordsPage({required this.plantId});

  @override
  State<TemperatureRecordsPage> createState() => _TemperatureRecordsPageState();
}

class _TemperatureRecordsPageState extends State<TemperatureRecordsPage> {
  final FirestoreService firestoreService = FirestoreService();

  late Future<List<Map<String, dynamic>>> tempRecords;

  @override
  void initState() {
    super.initState();
    tempRecords = fetchTemperatureRecords(widget.plantId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Temperature Records'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: tempRecords,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No humidity records available.'));
          } else {
            List<Map<String, dynamic>> tempRecords = snapshot.data!;

            return ListView.builder(
              itemCount: tempRecords.length,
              itemBuilder: (context, index) {
                String temp = tempRecords[index]['temp'].toString();

                return ListTile(
                  title: Text("Temperature: $temp"),
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchTemperatureRecords(String plantId) async {
    try {
      // Call the method from your FirestoreService to fetch humidity records
      List<Map<String, dynamic>> records = await firestoreService.fetchTemperatureRecords(plantId);
      return records;
    } catch (e) {
      print('Error fetching temp records: $e');
      return [];
    }
  }
}

