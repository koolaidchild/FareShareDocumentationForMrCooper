import 'dart:async';
import 'package:flutter/material.dart';
import '../constants.dart';
import 'package:google_place/google_place.dart'as places;
import 'package:google_maps_flutter/google_maps_flutter.dart';



class AddressGetter extends StatefulWidget {

  final Function(LatLng?, LatLng?) onAddressSelected;

  const AddressGetter({super.key, required this.onAddressSelected});

  @override
  // ignore: library_private_types_in_public_api
  _AddressGetterState createState() => _AddressGetterState();
}

class _AddressGetterState extends State<AddressGetter> {

  TextEditingController startTextController = TextEditingController();
  TextEditingController endTextController = TextEditingController();
  LatLng? startPosition;
  LatLng? endPosition;
  late FocusNode startFocusNode;
  late FocusNode endFocusNode;
  Timer? _debounce;
  late places.GooglePlace googlePlace;
  List<places.AutocompletePrediction> predictions = [];
  bool isStartLocationDropdownOpen = false;
  bool isEndLocationDropdownOpen = false;
  
  

  void openStartLocationDropdown() {
    setState(() {
      isStartLocationDropdownOpen = true;
      isEndLocationDropdownOpen = false;
    });
  }

  void openEndLocationDropdown() {
    setState(() {
      isStartLocationDropdownOpen = false;
      isEndLocationDropdownOpen = true;
    });
  }

  void autoCompleteSearch (String value) async{
    var result = await googlePlace.autocomplete.get(value);
    if (result != null && result.predictions != null && mounted){
      setState(() {
        predictions = result.predictions!;
      });
    }
  }

  Future<LatLng?> getLatLng(String placeId) async {
    final details = await googlePlace.details.get(placeId);
    if (details != null && details.result != null) {
      final geometry = details.result!.geometry;
      if (geometry != null && geometry.location != null) {
        final location = geometry.location!;
        return LatLng(location.lat!, location.lng!);
      }
    }
    return null;
  }

   @override
  void initState(){
    googlePlace = places.GooglePlace(google_api_key);
    startFocusNode = FocusNode();
    endFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose(){
    super.dispose();
    startFocusNode.dispose();
    endFocusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).size.height * 0.05,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        cursorColor: Colors.green,
                        controller: startTextController,
                        autofocus: false,
                        focusNode: startFocusNode,
                        decoration: const InputDecoration(
                          labelText: 'Starting Point',
                          filled: true,
                          fillColor: Color.fromARGB(255, 249, 241, 241),
                        ),
                        onChanged: (value){
                          openStartLocationDropdown();
                          if(_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce = Timer(const Duration(milliseconds: 1000), () {
                            if(value.isNotEmpty){
                              autoCompleteSearch(value);
                            }
                            else{
                              setState(() {
                                predictions = [];
                                startPosition = null;
                              });
                            }
                          });
                        },
                      ),
                      if (isStartLocationDropdownOpen)
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: predictions.length,
                            itemBuilder: (context, index){
                              return ListTile(
                                iconColor: Colors.green,
                                textColor: Colors.green,
                                tileColor: Colors.white,
                                selectedTileColor: Colors.grey,
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: Icon(
                                    Icons.pin_drop_rounded,
                                    color: Colors.white,
                                  )
                          
                                ),
                                title: Text(predictions[index].description.toString()),
                                onTap: () async {
                                  isStartLocationDropdownOpen = false;
                                  final placeId = predictions[index].placeId!;
                                  final coordinates = await getLatLng(placeId);
                                  if(coordinates != null){
                                    setState(() {
                                      startPosition = coordinates;
                                      startTextController.text = predictions[index].description.toString();
                                      predictions = [];

                                    });
                                  }
                                },
                              );
                            },
                          ),  
                        )        
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: endTextController,
                        autofocus: false,
                        enabled: startTextController.text.isNotEmpty && startPosition != null,
                        focusNode: endFocusNode,
                        decoration: const InputDecoration(
                          labelText: 'Destination',
                          filled: true,
                          fillColor: Color.fromARGB(255, 249, 241, 241),

                        ),
                        onChanged: (value){
                          openEndLocationDropdown();
                          if(_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce = Timer(const Duration(milliseconds: 1000), () {
                            if(value.isNotEmpty){
                              autoCompleteSearch(value);
                            }
                            else{
                              setState(() {
                                predictions = [];
                                endPosition = null;
                              });
                            }
                          });
                        },
                      ),
                      if (isEndLocationDropdownOpen)
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: predictions.length,
                            itemBuilder: (context, index){
                              return ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(
                                    Icons.pin_drop_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(predictions[index].description.toString()),
                                onTap: () async {
                                  isEndLocationDropdownOpen = false;
                                  final placeId = predictions[index].placeId!;
                                  final coordinates = await getLatLng(placeId);
                                  if(coordinates != null){
                                    setState(() {
                                      endPosition = coordinates;
                                      endTextController.text = predictions[index].description.toString();
                                    });
                                  }
                                },
                              );
                            },
                          ),
                        )
                    ],
                  )
                ),
              ],
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height / 2.5, // Adjust the position as needed
            left: 0,
            right: 0,
            child: Visibility(
              visible: ((startFocusNode.hasFocus == false) && (endFocusNode.hasFocus == false) && (isStartLocationDropdownOpen == false) && (isEndLocationDropdownOpen == false)),
              child: Center(
                child: FloatingActionButton(
                  onPressed: () {
                    // Navigate back to BasicRoute and pass data
                    widget.onAddressSelected(startPosition, endPosition);
                    // Close the bottom sheet
                    Navigator.pop(context);
                    
                  },
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  elevation: 30,
                  child: const Text('Go!'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
