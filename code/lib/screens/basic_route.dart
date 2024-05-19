import 'dart:async';
import 'dart:math' as math;
import 'address_getter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'custom_route.dart';
import 'nearby_gas.dart';
import '../constants.dart';
import 'package:just_bottom_sheet/drag_zone_position.dart';
import 'package:just_bottom_sheet/just_bottom_sheet.dart';
import 'package:just_bottom_sheet/just_bottom_sheet_configuration.dart';
import 'dart:ui';
import 'package:giffy_dialog/giffy_dialog.dart' as giffy;



class BasicRoute extends StatefulWidget {
  const BasicRoute({super.key});

  @override
  State<BasicRoute> createState() => BasicRouteScreenState();
}

class BasicRouteScreenState extends State<BasicRoute> {
  // INITIALIZATIONS

  final scrollController = ScrollController();
  // ignore: prefer_const_constructors
  LatLng startLocation = LatLng(0, 0);
  // ignore: prefer_const_constructors
  LatLng destination = LatLng(0, 0);

  // ignore: prefer_final_fields
  Completer<GoogleMapController> _controller = Completer();

  // ignore: prefer_final_fields
  Set<Marker> _markers = {};
  late geo.Position updatePosition;
  bool locInit = false;
  // ignore: unused_field
  Timer? _timer;

  // ignore: unused_field
  PolylinePoints polylinePoints = PolylinePoints();
  List<LatLng> polylineCoordinates = [];

  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor startLocationIcon = BitmapDescriptor.defaultMarker;

  String totalDistance = '';
  String totalCost = '';
  String perPerson = '';
  int passengers = 1;

  void getPassengers() {
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
  void _showGiffyDialog(BuildContext context) {

      totalDistance = "${(metersToMiles(calculateDistance(polylineCoordinates))).toStringAsFixed(2)} miles";
      totalCost = "\$${distanceToCost(calculateDistance(polylineCoordinates)).toStringAsFixed(2)}";
      perPerson = "\$${(distanceToCost(calculateDistance(polylineCoordinates))/passengers).toStringAsFixed(2)}";
      
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
            'Your trip is calculated!',
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Total cost: $totalCost \n Price per person: $perPerson \n Total distance: $totalDistance',
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context, 'OK');
                },
                child: const Text('OK'),
              ),
            ),
          ],
        );
      },
    );
  }

  void updateInputPositions(LatLng newStart, LatLng newEnd) {
    setState(() {
      startLocation = newStart;
      destination = newEnd;
    });
    addPolyline(); // Update the polyline when positions change
  }

  void handleAddressSelection(LatLng? startPosition, LatLng? endPosition) {
    if (startPosition != null && endPosition != null) {
      setState(() {
        // Update the state with the selected start and end positions
        startLocation = startPosition;
        destination = endPosition;
        // Optionally, you can call methods to update markers, polylines, etc.
        updateInputPositions(startLocation, destination);
        initializeMarkers();
      });
    }
  }

  void initializeMarkers() {
    _markers.removeWhere((marker) =>
        marker.markerId.value == "startLocation" ||
        marker.markerId.value == "destination");

    _markers.add(
      Marker(
        markerId: const MarkerId("startLocation"),
        position: startLocation,
        icon: startLocationIcon,
        infoWindow: const InfoWindow(title: 'Start Location'),
      ),
    );
    _markers.add(
      Marker(
        markerId: const MarkerId("destination"),
        position: destination,
        icon: destinationIcon,
        infoWindow: const InfoWindow(title: 'Destination'),
      ),
    );
  }

  void _updateMarkerPosition() async {
    updatePosition = await geo.Geolocator.getCurrentPosition(
      desiredAccuracy: geo.LocationAccuracy.best,
    );
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == "currentLocation");
      _markers.add(
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: LatLng(updatePosition.latitude, updatePosition.longitude),
          icon: currentLocationIcon,
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    });
    locInit = true;
  }

  void addPolyline() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      google_api_key,
      PointLatLng(startLocation.latitude, startLocation.longitude),
      PointLatLng(destination.latitude, destination.longitude),
      travelMode: TravelMode.driving,
      optimizeWaypoints: false
    );

    if (result.points.isNotEmpty) {
      setState(() {
        polylineCoordinates.clear(); // Clear existing coordinates
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
      });  
    }
    getPassengers();
  }

  Future<void> addCustomIconstart() async{
    BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(), "assets/red.png")
      .then(
        (icon) {
          setState(() {
            startLocationIcon = icon;
          });
        }
      );
    
  }

  Future<void> addCustomIconuser() async{
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

  Future<void> addCustomIconend() async{
    BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(), "assets/green.png")
      .then(
        (icon) {
          setState(() {
            destinationIcon = icon;
          });
        }
      );
  }

  LatLng getMidpoint(LatLng pos1, LatLng pos2){
    LatLng middlepoint = LatLng((pos1.latitude + pos2.latitude)/2, (pos1.longitude + pos2.longitude)/2);
    return (middlepoint);
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
    Future.wait([
      addCustomIconuser(),
      addCustomIconend(),
      addCustomIconstart(),
    ]).then((_) {
      initializeMarkers();
      _updateMarkerPosition();
    });
    _timer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      _updateMarkerPosition();
    });
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: locInit == false ? const 
        Center(child: CircularProgressIndicator(
          color: primaryColor,
          strokeCap: StrokeCap.round,
        )) :
        SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children : [
              GoogleMap(
                initialCameraPosition: 
                  CameraPosition(target: LatLng(updatePosition.latitude, updatePosition.longitude), zoom: 15),
                mapType: MapType.normal,
                compassEnabled: false,
                myLocationButtonEnabled: false,
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
                    color: primaryColor,
                    width: 5,
                    endCap: Cap.roundCap,
                    startCap:Cap.roundCap,
                  ),
                },
                markers: _markers
              ),
              Positioned(
                bottom: MediaQuery.of(context).size.height * 0.09, // Adjust the position as needed
                left: MediaQuery.of(context).size.width * 0.25,
                right: MediaQuery.of(context).size.width * 0.25,
                child: FloatingActionButton(
                  onPressed: () async{
                    await showJustBottomSheet(
                      context: context,
                      dragZoneConfiguration: JustBottomSheetDragZoneConfiguration(
                        dragZonePosition: DragZonePosition.outside,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            height: 4,
                            width: 30,
                            color: Theme.of(context).brightness == Brightness.light
                                ? Colors.grey[300]
                                : Colors.white,
                          ),
                        ),
                      ),
                      configuration: JustBottomSheetPageConfiguration(
                        height: MediaQuery.of(context).size.height,
                        builder: (context) {
                          return AddressGetter(
                            onAddressSelected: handleAddressSelection,
                          );
                        },
                        scrollController: scrollController,
                        closeOnScroll: true,
                        cornerRadius: 16,
                        backgroundColor: Theme.of(context).canvasColor.withOpacity(0.5),
                        backgroundImageFilter: ImageFilter.blur(
                          sigmaX: 30,
                          sigmaY: 30,
                        ),
                      ),
                    );
                  },
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  elevation: 30,
                  child: const Icon(Icons.directions_rounded),
                ),
              ),      
            ],
          )
        ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: primaryColor,
        items: const [
          BottomNavigationBarItem(
            label: 'Custom Route',
            icon: Icon(Icons.star_border_purple500_rounded),
          ),
          BottomNavigationBarItem(
            label: 'Basic Route',
            icon: Icon(Icons.swap_calls),
          ),
          BottomNavigationBarItem(
            label: "Gas Locations",
            icon: Icon(Icons.local_gas_station_outlined),
          ),
        ],
        onTap: (int indexOfItem) {
          if (indexOfItem == 0  && _controller.isCompleted) {
            // Navigate to FareShare2 screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => (const CustomRoute())),
            );
          } else {
            // Do nothing or add any other functionality for the second button
          }

          if (indexOfItem == 2  && _controller.isCompleted) {
            // Navigate to FareShare2 screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NearbyGasStationsScreen()),
            );
          } else {
            // Do nothing or add any other functionality for the second button
          }
        },
        
      ),
    );
  }
}
