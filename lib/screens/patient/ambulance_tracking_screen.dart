import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/ambulance.dart';

class AmbulanceTrackingScreen extends StatefulWidget {
  final Ambulance ambulance;
  final VoidCallback onCancel;

  const AmbulanceTrackingScreen({
    Key? key,
    required this.ambulance,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<AmbulanceTrackingScreen> createState() => _AmbulanceTrackingScreenState();
}

class _AmbulanceTrackingScreenState extends State<AmbulanceTrackingScreen> {
  LatLng? _patientLocation;
  late LatLng _ambulanceLocation;
  final MapController _mapController = MapController();
  StreamSubscription<DocumentSnapshot>? _ambulanceSubscription;
  Timer? _mockDriverTimer;

  @override
  void initState() {
    super.initState();
    _ambulanceLocation = LatLng(widget.ambulance.latitude, widget.ambulance.longitude);
    _determinePosition();
    _listenToAmbulance();
    _startMockDriver();
  }

  @override
  void dispose() {
    _ambulanceSubscription?.cancel();
    _mockDriverTimer?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _patientLocation = LatLng(position.latitude, position.longitude);
        });
        
        // If ambulance location is 0,0 (mock data), set it near patient
        if (_ambulanceLocation.latitude == 0 && _ambulanceLocation.longitude == 0) {
          setState(() {
            _ambulanceLocation = LatLng(
              position.latitude + 0.015,
              position.longitude + 0.015,
            );
          });
        }
        
        _fitBounds();
      }
    } catch (e) {
      debugPrint("Error getting location: \$e");
    }
  }

  void _fitBounds() {
    if (_patientLocation != null) {
      if (_ambulanceLocation.latitude == _patientLocation!.latitude &&
          _ambulanceLocation.longitude == _patientLocation!.longitude) {
        _mapController.move(_patientLocation!, 15.0);
        return;
      }
      final bounds = LatLngBounds.fromPoints([_ambulanceLocation, _patientLocation!]);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );
    }
  }

  void _listenToAmbulance() {
    // Listen to real-time updates from the Firebase database
    _ambulanceSubscription = FirebaseFirestore.instance
        .collection('ambulances')
        .doc(widget.ambulance.id)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _ambulanceLocation = LatLng(
            (data['latitude'] as num).toDouble(),
            (data['longitude'] as num).toDouble(),
          );
        });
      }
    });
  }

  void _startMockDriver() {
    _mockDriverTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_patientLocation == null || !mounted) return;
      
      final double latDiff = _patientLocation!.latitude - _ambulanceLocation.latitude;
      final double lngDiff = _patientLocation!.longitude - _ambulanceLocation.longitude;
      
      // Stop moving if very close
      if (latDiff.abs() < 0.0001 && lngDiff.abs() < 0.0001) {
        timer.cancel();
        return;
      }
      
      FirebaseFirestore.instance
        .collection('ambulances')
        .doc(widget.ambulance.id)
        .update({
          'latitude': _ambulanceLocation.latitude + (latDiff * 0.05),
          'longitude': _ambulanceLocation.longitude + (lngDiff * 0.05),
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _ambulanceLocation,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sehat_sathi',
              ),
              if (_patientLocation != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_ambulanceLocation, _patientLocation!],
                      color: Colors.blueAccent.withOpacity(0.5),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _ambulanceLocation,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.airport_shuttle,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                  if (_patientLocation != null)
                    Marker(
                      point: _patientLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vehicle ${widget.ambulance.vehicleNumber} is on the way.',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              widget.onCancel();
                            },
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                               ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Calling driver...')),
                              );
                            },
                            icon: const Icon(Icons.call),
                            label: const Text('Call'),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
