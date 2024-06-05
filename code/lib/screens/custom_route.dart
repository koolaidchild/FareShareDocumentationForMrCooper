import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants.dart';
import 'basic_route.dart';
import 'nearby_gas.dart';
import '../getLocationGlobal.dart';
import 'package:giffy_dialog/giffy_dialog.dart' as giffy;
import 'package:lite_rolling_switch/lite_rolling_switch.dart';


class CustomRoute extends StatefulWidget{
  
  const CustomRoute ({super.key});
  
  @override
  State<CustomRoute> createState() => CustomRoutePageState();
}

class CustomRoutePageState extends State<CustomRoute> {

  //INITILIZATIONS

  // ignore: prefer_final_fields
  Completer<GoogleMapController> _controller = Completer();

  List<LatLng> polylineCoordinates = [];
  // ignore: unused_field
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  Timer? _timer;
  bool isTracking = false;
  bool headingChoice = true;
  int passengers = 1;
  String totalCost = "\$${0.00}";
  String perPerson = "\$${0.00}";
  String totalDistance = "${0}";
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;
  int _secondsPassed = 0;
  String formalTimer = "0:00";


  //CREATION OF FUNCTIONS

  void addCustomIconuser(){
    BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(), "assets/car.png")
      .then(
        (icon) {
          setState(() {
            currentLocationIcon = icon;
          });
        }
      );
  }

  String _formatTimer(int secondsPassed) {
    Duration duration = Duration(seconds: secondsPassed);
    if (duration.inHours > 0) {
      return '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    } else {
      return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    }
  }

  void _showGiffyDialog(BuildContext context) {
      showDialog(
      context: context,
      builder: (BuildContext context) {
        return giffy.GiffyDialog.image(
          Image.network(
            "https://cdn.dribbble.com/users/4358240/screenshots/14825308/media/84f51703b2bfc69f7e8bb066897e26e0.gif",
            height: 200,
            fit: BoxFit.cover,
          ),
          title: const Text(
            'Your trip is complete!',
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Total cost: $totalCost \n Price per person: $perPerson \n Total distance traveled: $totalDistance \n Time elapsed: $formalTimer',
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context, 'OK');
                  formalTimer = "0:00";
                },
                child: const Text('OK'),
              ),
            ),
          ],
        );
      },
    );
  }



  void _startTracking() {
    isTracking = true;
  }

  void _stopTracking() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Enter number of passengers'),
              content: TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    // Update passengers when the value changes
                    passengers = int.tryParse(value) ?? 1;
                  });
                },
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Perform any action needed with the entered value
                    isTracking = false;
                    polylineCoordinates = [];
                    _secondsPassed = 0;
                    Navigator.of(context).pop();
                    _showGiffyDialog(context);
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addLocationToPolyline() async {
    geo.Position position = await geo.Geolocator.getCurrentPosition(
      desiredAccuracy: geo.LocationAccuracy.best,
    );

    setState(() {
      LatLng newPosition = LatLng(position.latitude, position.longitude);
      if(isTracking == true){
        polylineCoordinates.add(newPosition);
      }
      double userBearing = position.heading; 
      _updatePolylineAndMarker(newPosition, userBearing);

    });
  }

  void _updatePolylineAndMarker(LatLng newPosition, double userBearing) {
    if(isTracking == true){
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          color: primaryColor,
          points: polylineCoordinates,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap
        ),
      };
      if(headingChoice){
        _updateCameraPositionWithBearing(userBearing);
      }
    }
    _updateMarkerPosition(newPosition);
  }

  
  void _updateCameraPositionWithBearing(double userBearing) async {
    GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
          zoom: 15,
          tilt: 50,
          bearing: userBearing
        ),
      ),
    );
  }

  void _updateMarkerPosition(LatLng newPosition) {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == "currentLocation");
      _markers.add(
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: newPosition,
          icon: currentLocationIcon,
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    });
  }


  double calculateDistance(List<LatLng> polyline) {
    double totalDistance = 0;
    for (int i = 0; i < polyline.length; i++) {
      if (i < polyline.length - 1) { // skip the last index
        totalDistance += getStraightLineDistance(
            polyline[i + 1].latitude,
            polyline[i + 1].longitude,
            polyline[i].latitude,
            polyline[i].longitude);
      }
    }
    return totalDistance;
  }

  double getStraightLineDistance(lat1, lon1, lat2, lon2) {
    var R = 6371; // Radius of the earth in km
    var dLat = deg2rad(lat2 - lat1);
    var dLon = deg2rad(lon2 - lon1);
    var a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(deg2rad(lat1)) *
            math.cos(deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    var c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    var d = R * c; // Distance in km
    return d * 1000; //in m
  }

  dynamic deg2rad(deg) {
    return deg * (math.pi / 180);
  }


  //DECLARING STATE
  
  @override
  void initState(){
    addCustomIconuser();
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
          icon: currentLocationIcon,
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      };
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _addLocationToPolyline();
        if(isTracking){
          _secondsPassed++;
          formalTimer = _formatTimer(_secondsPassed);
          totalDistance = "${(metersToMiles(calculateDistance(polylineCoordinates))).toStringAsFixed(2)} miles";
          totalCost = "\$${distanceToCost(calculateDistance(polylineCoordinates)).toStringAsFixed(2)}";
          perPerson = "\$${(distanceToCost(calculateDistance(polylineCoordinates))/passengers).toStringAsFixed(2)}";
        }
    });    
    super.initState();
  }

  @override
  Widget build (BuildContext context){
    return Scaffold( // AppBar
      body: (locInit == false) ? const 
        Center(child: CircularProgressIndicator(
          color: primaryColor,
          strokeCap: StrokeCap.round,
        )) :
        Center(
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: 
                CameraPosition(target: LatLng(currentLocation!.latitude!, currentLocation!.longitude!), zoom: 18, tilt: 50),
              mapType: MapType.normal,
              compassEnabled: false,
              myLocationEnabled: false,
              onMapCreated: (GoogleMapController controller) async{
                _controller.complete(controller);
                String style = await DefaultAssetBundle.of(context).loadString('assets/map_style.json');
                controller.setMapStyle(style);
              },
              zoomControlsEnabled: false,
              polylines: {
                Polyline(
                  polylineId: const PolylineId("route"),
                  points: polylineCoordinates,
                  width: 5,
                  color: primaryColor,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                )
              },
              markers: _markers
            ),
            Visibility(
              visible: isTracking != true, // Replace 'condition' with your actual condition
              child: Positioned(
                bottom: MediaQuery.of(context).size.height * 0.09, // Adjust the position as needed
                left: MediaQuery.of(context).size.width * 0.25,
                right: MediaQuery.of(context).size.width * 0.25,
                child: FloatingActionButton(
                  onPressed: () async{
                    _startTracking();
                  },
                  foregroundColor: primaryColor,
                  backgroundColor: Colors.green,
                  elevation: 30,
                  child: const Text("Start Route", style: TextStyle(color: Colors.white), ),
                ),
              ),
            ), 
            Visibility(
              visible: isTracking, // Replace 'condition' with your actual condition
              child: Positioned(
                bottom: MediaQuery.of(context).size.height * 0.09, // Adjust the position as needed
                left: MediaQuery.of(context).size.width * 0.25,
                right: MediaQuery.of(context).size.width * 0.25,
                child: FloatingActionButton(
                  onPressed: () async{
                    _stopTracking();
                  },
                  foregroundColor: primaryColor,
                  backgroundColor: const Color.fromARGB(255, 157, 17, 7),
                  elevation: 30,
                  child: Text("End Route - $formalTimer", style: const TextStyle(color: Colors.white), ),
                ),
              ),
            ),
            Visibility(
              visible: isTracking,
              child:
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.1,
                  left: MediaQuery.of(context).size.width * 0.07,
                  child: 
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.2,
                    child: 
                      LiteRollingSwitch(
                        value: true,
                        width: MediaQuery.of(context).size.width * 0.2,
                        textOn: '',
                        textOff: '',
                        textOnColor: Colors.white,
                        colorOn: Colors.green,
                        colorOff: Colors.grey,
                        iconOn: Icons.navigation,
                        iconOff: Icons.highlight_off,
                        animationDuration: const Duration(milliseconds: 300),
                        onChanged: (bool state) {
                          if(headingChoice == true){
                            setState(() {
                              headingChoice = false;

                            });
                          }
                          else{
                            setState(() {
                              headingChoice = true;
                            });
                          }
                        },
                        onDoubleTap: () {},
                        onSwipe: () {},
                        onTap: () {},
                      ),
                  ),
                ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: primaryColor,
        items: const [
          BottomNavigationBarItem(
            label: "Custom Route",
            icon: Icon(Icons.star_border_purple500_rounded),
          ),
          BottomNavigationBarItem(
            label: "Basic Route",
            icon: Icon(Icons.swap_calls),
          ),
          BottomNavigationBarItem(
            label: "Gas Locations",
            icon: Icon(Icons.local_gas_station_outlined),
          ),
          
        ],
        onTap: (int indexOfItem) {
          if (indexOfItem == 1 && _controller.isCompleted) {
            // Navigate to fareshare2 screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BasicRoute()),
            );
          } 

          if (indexOfItem == 2 && _controller.isCompleted) {
            // Navigate to fareshare2 screen
            Navigator.push(
              context,
              MaterialPageRoute( builder: (context) => const NearbyGasStationsScreen()),
            );
          } 

          else {
            // Do nothing or add any other functionality for the second button
          }
        },
      ),
    );// Scaffold  
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}