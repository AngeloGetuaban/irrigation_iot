import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart';

class WaterRecordsPage extends StatefulWidget {
  final String plantId;

  WaterRecordsPage({required this.plantId});

  @override
  _WaterRecordsPageState createState() => _WaterRecordsPageState();
}

class _WaterRecordsPageState extends State<WaterRecordsPage> {
  final FirestoreService firestoreService = FirestoreService();

  late Future<List<Map<String, dynamic>>> waterRecords;

  @override
  void initState() {
    super.initState();
    waterRecords = fetchWaterRecords(widget.plantId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Water Records'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: waterRecords,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No water records available.'));
          } else {
            List<Map<String, dynamic>> waterRecords = snapshot.data!;

            return ListView.builder(
              itemCount: waterRecords.length,
              itemBuilder: (context, index) {
                String water_record = waterRecords[index]['water_record'].toString();

                return ListTile(
                  title: Text("Watered on $water_record"),
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchWaterRecords(String plantId) async {
    try {
      // Call the method from your FirestoreService to fetch humidity records
      List<Map<String, dynamic>> records = await firestoreService.fetchWaterRecords(plantId);
      return records;
    } catch (e) {
      print('Error fetching water records: $e');
      return [];
    }
  }
}

