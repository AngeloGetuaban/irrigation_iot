import 'dart:async';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'main.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final FirestoreService firestoreService = FirestoreService();
  bool isLoading = false;
  int waterDuration = 3; // default value, can be changed based on user input

  void showNotification(String message) {
    Future.delayed(Duration.zero, () {
      Flushbar(
        title: "Plant Notification",
        message: message,
        duration: Duration(seconds: 3),
      )..show(context);
    });
  }

  void openWaterDurationOverlay() async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Water Duration'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Enter duration in seconds'),
            onChanged: (value) {
              // Validate input and update water duration
              setState(() {
                waterDuration = int.tryParse(value) ?? waterDuration;
              });
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(waterDuration);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      // User saved the water duration, you can use this value in your Timer
      print('Water Duration set to: $result seconds');
      // Update your Timer with the new water duration value
    }
  }


  void toggleWaterState(Plant plant) {
    // If water_state is 0, set it to 1; if 1, set it to 0
    int newWaterState = plant.water_state == 0 ? 1 : 0;
    firestoreService.toggleWaterState(plant.id, newWaterState);
  }

  // Function to show loading widget for 3 seconds
  void showLoading(Plant plant) {
    setState(() {
      isLoading = true;
    });

    Timer(Duration(seconds: waterDuration), () async {
      // Wait for 1 second before hiding loading and updating button text
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        isLoading = false;
      });

      // Update the button text and water_state in Firestore
      toggleWaterState(plant);
    });
  }

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

              plants.forEach((plant) {
                Color tempColor = getTempColor(plant.temp);
                Color humiColor = getHumiColor(plant.humi);
                Color moistColor = getMoistColor(plant.moist);

                if (tempColor == Colors.blue) {
                  showNotification("Your plant is cold, temperature is dropping");
                } else if (tempColor == Colors.red) {
                  showNotification("Your plant is in danger, temperature is rising");
                }

                if (humiColor == Colors.blue) {
                  showNotification("Your plant is in danger, humidity is dropping");
                } else if (humiColor == Colors.red) {
                  showNotification("Your plant is in danger, humidity is rising");
                }

                if (moistColor == Colors.blue) {
                  showNotification("Your plant  is dry, water it now!");
                } else if (moistColor == Colors.red) {
                  showNotification("Your plant is too wet, stop watering!");
                }
              });
              return SingleChildScrollView(
                child: Column(
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
                                  width: MediaQuery
                                      .of(context)
                                      .size
                                      .width * 0.44,
                                  child: Center(
                                    child: Text(
                                      'Status: ${getStatus(
                                          plant.temp, plant.humi, plant.moist)}',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                              ),
                              Card(
                                color: plant.water_state == 1
                                    ? Colors.indigo
                                    : Colors.orangeAccent,
                                child: Container(
                                  height: 50,
                                  width: MediaQuery
                                      .of(context)
                                      .size
                                      .width * 0.44,
                                  child: Center(
                                    child: Text(
                                      'Current Water State: ${plant.water_state ==
                                          0 ? "OFF" : "ON"}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: plant.water_state == 1 ? Colors
                                            .white : null,
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
                                  width: MediaQuery
                                      .of(context)
                                      .size
                                      .width * 0.44,
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
                                            style: TextStyle(fontSize: 40),
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
                                  width: MediaQuery
                                      .of(context)
                                      .size
                                      .width * 0.44,
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
                                            style: TextStyle(fontSize: 40),
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
                          SizedBox(
                            height: 16.0,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: isLoading
                                  ? Colors.indigo // Set the color for disabled state
                                  : plant.water_state == 0
                                  ? Colors.orangeAccent
                                  : Colors.indigo,
                              borderRadius: BorderRadius.circular(8.0), // Adjust the radius as needed
                            ),
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null // Button is disabled when isLoading is true
                                  : () {
                                firestoreService.toggleWaterState(plant.id, plant.water_state);
                                // Toggle water state
                                // Show loading widget
                                showLoading(plant);
                              },
                              child: Text(
                                isLoading
                                    ? 'Loading...'
                                    : plant.water_state == 0
                                    ? 'TURN ON WATER'
                                    : 'TURN OFF WATER',
                                style: TextStyle(
                                  fontSize: 30,
                                  color: plant.water_state == 0 ? Colors.black : Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.transparent, // Set this to transparent
                                elevation: 0, // No elevation when inside a container with decoration
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 16.0,
                          ),
                          // Loading widget with text
                          Visibility(
                            visible: isLoading,
                            child: Column(
                              children: [
                                LinearProgressIndicator(
                                  backgroundColor: Colors.grey,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue),
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  'Watering for ${waterDuration} seconds',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            }
          },
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
        child: Align(
          alignment: Alignment.bottomRight,
          child: FloatingActionButton(
            onPressed: openWaterDurationOverlay,
            tooltip: 'Set Water Duration',
            child: Icon(Icons.timer),
          ),
        ),
      ),
    );
  }
}
