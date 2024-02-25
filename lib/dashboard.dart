import 'dart:async';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:iot_alpha/humi_record.dart';
import 'package:iot_alpha/moist_record.dart';
import 'package:iot_alpha/pin_page.dart';
import 'package:iot_alpha/temp_records.dart';
import 'package:iot_alpha/water_record.dart';
import 'change_pin.dart';
import 'main.dart';

class Dashboard extends StatefulWidget {
  final String newPinValue;

  Dashboard({required this.newPinValue});
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final FirestoreService firestoreService = FirestoreService();
  bool isLoading = false;
  int? waterDuration; // default value, can be changed based on user input
  List<Plant> plants = [];
  TextEditingController phoneNumberController = TextEditingController(); // New controller for phone numbe
  void showNotification(String message) {
    Future.delayed(Duration.zero, () {
      Flushbar(
        title: "Plant Notification",
        message: message,
        duration: Duration(seconds: 3),
      )..show(context);
    });
  }
  void openPhoneNumberOverlay() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Phone Number'),
          content: TextField(
            controller: phoneNumberController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: 'Enter your phone number'),
            onChanged: (value) {
              // Validate and format the phone number
              if (value.isNotEmpty && !value.startsWith('+63')) {
                // Add '+63' to the beginning of the phone number
                phoneNumberController.text = '+63$value';
                // Move the cursor to the end of the text
                phoneNumberController.selection = TextSelection.fromPosition(
                  TextPosition(offset: phoneNumberController.text.length),
                );
              }
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                // Check if the phone number is valid before updating Firestore
                if (isValidPhoneNumber(phoneNumberController.text)) {
                  await firestoreService.updatePhoneNumberInFirestore(phoneNumberController.text);
                  Navigator.of(context).pop();
                } else {
                  print('Invalid phone number');
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

// Function to validate the phone number format
  bool isValidPhoneNumber(String phoneNumber) {
    // Check if the phone number starts with '+63' and has at least 10 digits
    return phoneNumber.startsWith('+63') && phoneNumber.length >= 12;
  }

  void openWaterDurationOverlay() async {
    int newWaterDuration = waterDuration!; // Store the current value to compare later
    String plantId = "";
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
                newWaterDuration = int.tryParse(value) ?? newWaterDuration;
              });
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                // Update waterDuration only if the value has changed
                if (newWaterDuration != waterDuration) {
                  setState(() {
                    waterDuration = newWaterDuration;
                  });

                  // Update the 'water_duration' field in Firestore
                  await firestoreService.updateWaterDurationInFirestore(newWaterDuration);
                }

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

  void recordWateringEvent(String plantId, int waterDuration) {
    // Get the current date and time
    DateTime now = DateTime.now();
    String formattedDateTime = "${now.toLocal()}".split(' ')[0] + " ${now.hour}:${now.minute}:${now.second}";

    // Update the Firestore document with the recorded information
    firestoreService.recordWateringEvent(plantId, formattedDateTime, waterDuration);
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

    Timer(Duration(seconds: waterDuration!), () async {
      // Wait for 1 second before hiding loading and updating button text
      await Future.delayed(Duration(seconds: 1));

      setState(() {
        isLoading = false;
      });

      // Update the button text and water_state in Firestore
      toggleWaterState(plant);

      // Record the watering event
      recordWateringEvent(plant.id, waterDuration!);
    });
  }

  Color getTempColor(double temp) {
    if (temp >= 18.0 && temp <= 25.0) {
      return Colors.green;
    } else if (temp < 18.0) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  Color getHumiColor(double humi) {
    if (humi >= 50.0 && humi <= 75.0) {
      return Colors.green;
    } else if (humi < 50.0) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  Color getMoistColor(double moist) {
    if (moist > 10.0) {
      return Colors.green;
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
  void checkPinAndNavigate() async {
    bool shouldNavigate = await firestoreService.checkPinAndNavigate();
    print(shouldNavigate);


    if (!shouldNavigate) {
      // If shouldNavigate is false, navigate to PinPage
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => PinPage()),
            (
            route) => false, // This will remove all the routes below the pushed route
      );
    }
  }
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
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              showSnackBar('Successfully logged out');
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => PinPage()),
                    (
                    route) => false, // This will remove all the routes below the pushed route
              );
            }
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Records',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text('Water Records'),
              onTap: () {
                // Check if there is at least one plant in the list
                if (plants.isNotEmpty) {
                  // Use the plant ID of the first plant for demonstration
                  String plantId = plants[0].id;

                  // Navigate to Water Records screen
                  Navigator.pop(context); // Close the drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WaterRecordsPage(plantId: plantId)),
                  );
                }
              },
            ),
            ListTile(
              title: Text('Humidity Records'),
              onTap: () {
                // Check if there is at least one plant in the list
                if (plants.isNotEmpty) {
                  // Use the plant ID of the first plant for demonstration
                  String plantId = plants[0].id;

                  // Navigate to Water Records screen
                  Navigator.pop(context); // Close the drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HumidityRecordsPage(plantId: plantId)),
                  );
                }
              },
            ),
            ListTile(
              title: Text('Temperature Records'),
              onTap: () {
                // Check if there is at least one plant in the list
                if (plants.isNotEmpty) {
                  // Use the plant ID of the first plant for demonstration
                  String plantId = plants[0].id;

                  // Navigate to Water Records screen
                  Navigator.pop(context); // Close the drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TemperatureRecordsPage(plantId: plantId)),
                  );
                }
              },
            ),
            ListTile(
              title: Text('Soil Moisture Records'),
              onTap: () {
                // Check if there is at least one plant in the list
                if (plants.isNotEmpty) {
                  // Use the plant ID of the first plant for demonstration
                  String plantId = plants[0].id;

                  // Navigate to Water Records screen
                  Navigator.pop(context); // Close the drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SoilMoitureRecords(plantId: plantId)),
                  );
                }
              },
            ),
            ListTile(
              title: Text('Change Pin'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangePinPage()),
                );
              },
            ),
          ],
        ),
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
              plants = snapshot.data ?? [];

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
                waterDuration = plant.water_duration;
                checkPinAndNavigate();
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
                                backgroundColor: Colors.transparent, // Set this to transparent
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: openWaterDurationOverlay,
              tooltip: 'Set Water Duration',
              child: Icon(Icons.timer),
            ),
            SizedBox(height: 16.0),
            FloatingActionButton(
              onPressed: openPhoneNumberOverlay,
              tooltip: 'Set Phone Number',
              child: Icon(Icons.phone),
            ),
          ],
        ),
      ),
    );
  }
}
