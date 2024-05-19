// ignore: file_names
import 'package:location/location.dart';

LocationData? currentLocation;
bool locInit = false;

void getCurrentLocation () async {
  Location location = Location();

  //GoogleMapController googleMapController = await _controller.future;

  location.getLocation().then((location){
    currentLocation = location;
    locInit = true;
  });

  location.onLocationChanged.listen(
    (newLoc) {
      currentLocation = newLoc;
    }
  );
}


