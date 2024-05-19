import '../getLocationGlobal.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:google_maps_webservice/places.dart';
import '../constants.dart';
import '../screens/basic_route.dart';
import '../screens/custom_route.dart';
import 'dart:async';
import 'dart:math' as math;


final _places = GoogleMapsPlaces(apiKey: google_api_key);

class NearbyGasStationsScreen extends StatefulWidget {
  const NearbyGasStationsScreen({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _NearbyGasStationsScreenState createState() => _NearbyGasStationsScreenState();
}

class _NearbyGasStationsScreenState extends State<NearbyGasStationsScreen> {
  late Future<List<PlacesSearchResult>> _placesFuture;

  Future<List<PlacesSearchResult>> _searchPlaces(String query, LatLng location) async {
    final result = await _places.searchNearbyWithRadius(
      Location(lat: location.latitude, lng: location.longitude),
      10000,
      type: "gas station",
      keyword: query,
    );
    if (result.status == "OK") {
      return result.results;
    } else {
      throw Exception(result.errorMessage);
    }
  }



  @override
  void initState() {
    super.initState();
    _placesFuture = _searchPlaces("gas station", LatLng(currentLocation!.latitude!, currentLocation!.longitude!));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: 
        FutureBuilder<List<PlacesSearchResult>>(
          future: _placesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(
                color: primaryColor,
                strokeCap: StrokeCap.round,
              ));
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No gas stations found nearby.'));
            } else {
              return _buildPlacesList(snapshot.data!);
            }
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
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
          if (indexOfItem == 0) {
            // Navigate to FareShare2 screen
            Navigator.push(
              context,
              MaterialPageRoute( builder: (context) => const CustomRoute()),
            );
          } 
          if (indexOfItem == 1) {
            // Navigate to FareShare2 screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BasicRoute()),
            );
          } 
        },
      ),
    );
  }

  Widget _buildPlacesList(List<PlacesSearchResult> places) {
    // Sort places based on distance
    places.sort((a, b) {
      final aLocation = LatLng(a.geometry!.location.lat, a.geometry!.location.lng);
      final bLocation = LatLng(b.geometry!.location.lat, b.geometry!.location.lng);
      final aDistance = _calculateDistance(LatLng(currentLocation!.latitude!, currentLocation!.longitude!), aLocation);
      final bDistance = _calculateDistance(LatLng(currentLocation!.latitude!, currentLocation!.longitude!), bLocation);
      return aDistance.compareTo(bDistance);
    });

    return ListView.builder(
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        final station = place.name;
        final address = place.vicinity;

        // Calculate distance between user's location and gas station
        final gasStationLocation = LatLng(
          place.geometry!.location.lat,
          place.geometry!.location.lng,
        );
        final distance = _calculateDistance(LatLng(currentLocation!.latitude!, currentLocation!.longitude!), gasStationLocation);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ListTile(
                title: Text(station),
                subtitle: Text(address!),
                onTap: () {
                  // Handle the selection of a gas station (if needed)
                  // You can navigate to a detailed screen or perform other actions here
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '${distance.toStringAsFixed(1)} miles',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ],
        );
      },
    );
  }

  double radians(double degrees) {
    return degrees * (math.pi / 180);
  }

  double _calculateDistance(LatLng start, LatLng end) {
    // Using Haversine formula to calculate distance between two coordinates
    const earthRadius = 6371.0; // in kilometers
    final lat1 = radians(start.latitude);
    final lon1 = radians(start.longitude);
    final lat2 = radians(end.latitude);
    final lon2 = radians(end.longitude);
    final dLon = lon2 - lon1;
    final dLat = lat2 - lat1;
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distanceInMeters = earthRadius * c * 1000; // in meters

    // Convert distance from meters to miles
    return (distanceInMeters / 1609.34);
  }
}

  double radians(double degrees) {
    return degrees * (math.pi / 180);
  }





