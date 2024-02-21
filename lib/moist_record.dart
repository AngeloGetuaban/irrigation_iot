import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart';

class SoilMoitureRecords extends StatefulWidget {
  final String plantId;

  SoilMoitureRecords({required this.plantId});

  @override
  State<SoilMoitureRecords> createState() => _SoilMoitureRecordsState();
}

class _SoilMoitureRecordsState extends State<SoilMoitureRecords> {
  final FirestoreService firestoreService = FirestoreService();

  late Future<List<Map<String, dynamic>>> moistRecords;

  @override
  void initState() {
    super.initState();
    moistRecords = fetchMoistRecords(widget.plantId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Soil Moisture Records'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: moistRecords,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No humidity records available.'));
          } else {
            List<Map<String, dynamic>> moistRecords = snapshot.data!;

            return ListView.builder(
              itemCount: moistRecords.length,
              itemBuilder: (context, index) {
                String moist = moistRecords[index]['moist'].toString();

                return ListTile(
                  title: Text("Soil Moisture: $moist"),
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchMoistRecords(String plantId) async {
    try {
      // Call the method from your FirestoreService to fetch humidity records
      List<Map<String, dynamic>> records = await firestoreService.fetchMoistRecords(plantId);
      return records;
    } catch (e) {
      print('Error fetching moist records: $e');
      return [];
    }
  }
}


