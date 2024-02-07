import 'package:flutter/material.dart';
import 'main.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final FirestoreService firestoreService = FirestoreService();

  Color getTempColor(double temp) {
    if (temp >= 20.0 && temp <= 36.0) {
      return Colors.green;
    } else if (temp < 19.0) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  Color getHumiColor(double humi) {
    if (humi >= 60.0 && humi <= 80.0) {
      return Colors.green;
    } else if (humi < 60.0) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  Color getMoistColor(double moist) {
    if (moist >= 21.0 && moist <= 59.0) {
      return Colors.green;
    } else if (moist < 21.0) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  String getStatus(double temp, double humi, double moist) {
    Color tempColor = getTempColor(temp);
    Color humiColor = getHumiColor(humi);
    Color moistColor = getMoistColor(moist);

    if (tempColor == Colors.green &&
        humiColor == Colors.green &&
        moistColor == Colors.green) {
      return 'NORMAL';
    } else if (tempColor == Colors.red ||
        humiColor == Colors.red ||
        moistColor == Colors.red) {
      return 'BAD';
    } else if (tempColor == Colors.blue ||
        humiColor == Colors.blue ||
        moistColor == Colors.blue) {
      return 'LOW';
    } else {
      return 'BAD';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // You can handle refreshing logic here if needed
        },
        child: StreamBuilder<List<Plant>>(
          stream: firestoreService.getAllPlants(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              List<Plant> plants = snapshot.data ?? [];

              return Column(
                children: plants.map((plant) {
                  return Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Card(
                              color: getTempColor(plant.temp),
                              child: Container(
                                height: 50,
                                width: 180,
                                child: Center(
                                  child: Text(
                                    'Status: ${getStatus(plant.temp, plant.humi, plant.moist)}',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),
                            ),
                            Card(
                              color: plant.water_state == 1 ? Colors.indigo : Colors.orangeAccent,
                              child: Container(
                                height: 50,
                                width: 180,
                                child: Center(
                                  child: Text(
                                    'Current Water State: ${plant.water_state == 0 ? "OFF" : "ON"}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: plant.water_state == 1 ? Colors.white : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Card(
                              color: getTempColor(plant.temp),
                              child: Container(
                                height: 200,
                                width: 180,
                                child: Center(
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 40.0,
                                        ),
                                        Text(
                                          'Temperature',
                                          style: TextStyle(fontSize: 20),
                                        ),
                                        Text(
                                          '${plant.temp}°C',
                                          style: TextStyle(fontSize: 55),
                                        ),
                                      ],
                                    )
                                ),
                              ),
                            ),
                            Card(
                              color: getHumiColor(plant.humi),
                              child: Container(
                                height: 200,
                                width: 180,
                                child: Center(
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 40.0,
                                        ),
                                        Text(
                                          'Humidity',
                                          style: TextStyle(fontSize: 20),
                                        ),
                                        Text(
                                          '${plant.humi}%',
                                          style: TextStyle(fontSize: 55),
                                        ),
                                      ],
                                    )
                                ),
                              ),
                            )
                          ],
                        ),
                        Card(
                          color: getMoistColor(plant.moist),
                          child: Container(
                            height: 200,
                            width: 370,
                            child: Center(
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 40.0,
                                    ),
                                    Text(
                                      'Soil Moisture',
                                      style: TextStyle(fontSize: 26),
                                    ),
                                    Text(
                                      '${plant.moist}%',
                                      style: TextStyle(fontSize: 80),
                                    ),
                                  ],
                                )
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Handle the button press, toggle the water state
                            firestoreService.toggleWaterState(plant.id, plant.water_state);
                          },
                          child: Text(
                            plant.water_state == 0 ? 'TURN ON WATER' : 'TURN OFF WATER',
                            style: TextStyle(fontSize: 30, color: plant.water_state == 0 ? Colors.black : Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: plant.water_state == 0 ? Colors.orangeAccent : Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }
          },
        ),
      ),
    );
  }
}
