import 'package:flutter/material.dart';

const String google_api_key = "AIzaSyAW5-3qbbdlJHSRYd_f_r3VdoCTHkkK2aE";
const Color primaryColor = Colors.green;

double distanceToCost (double meters){ //Constants for distance conversion
  return (metersToMiles(meters) * 0.655); //National Mileage Reimbursement Rate
}

double metersToMiles (double meters){
  return (meters * 0.000621371);
}
