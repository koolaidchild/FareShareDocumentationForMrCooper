import 'dart:async';
import '../getLocationGlobal.dart';
import 'package:flutter/material.dart';
import 'custom_route.dart'; 


class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _loadData();
  }

  Future<void> _loadData() async {
  // Simulate loading data, e.g., getting location or initializing map
    getCurrentLocation();
    while (locInit != true) {
      await Future.delayed(const Duration(milliseconds: 250)); // Adjust the duration as needed
    }
  // ignore: use_build_context_synchronously
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CustomRoute()),);
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: Tween(begin: 0.0, end: 2.5).animate(_rotationController),
              child: Image.asset(
                'assets/fareshareLogo.png',
                width: 200,
                height: 200,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Loading...'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }
}