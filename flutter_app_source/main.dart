import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

void main() {
  runApp(const TravelEarnApp());
}

class TravelEarnApp extends StatelessWidget {
  const TravelEarnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel & Earn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      home: const TrackerPage(),
    );
  }
}

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  bool _isTracking = false;
  double _totalDistance = 0.0;
  double _currentSpeed = 0.0;
  double _coins = 0.0;
  
  // 0.1 coin per meter
  static const double _coinRate = 0.1;

  StreamSubscription<Position>? _positionStream;
  Position? _lastPosition;

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      _stopTracking();
    } else {
      await _startTracking();
    }
  }

  Future<void> _startTracking() async {
    // 1. Check Permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) _showSnackBar('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) _showSnackBar('Location permissions are denied');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) _showSnackBar('Location permissions are permanently denied.');
      return;
    }

    // 2. Start Stream
    setState(() {
      _isTracking = true;
      _lastPosition = null; // Reset segment start
    });

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation, // High accuracy
      distanceFilter: 2, // Minimum distance (meters) to trigger update
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _updateMetrics(position);
    });
  }

  void _stopTracking() {
    _positionStream?.cancel();
    setState(() {
      _isTracking = false;
      _currentSpeed = 0.0; // Reset speed when stopped
    });
  }

  void _updateMetrics(Position position) {
    if (_lastPosition != null) {
      // Calculate distance from last point
      double distanceInMeters = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      // Simple noise filter: erratic jumps larger than reasonble speed (e.g. 100m in 1 sec) could be filtered
      // For now, reliance on accuracy: bestForNavigation handles most of this.
      
      _totalDistance += distanceInMeters;
      _coins = _totalDistance * _coinRate;
    }

    setState(() {
      _currentSpeed = position.speed; // Speed is in m/s
      _lastPosition = position;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: const Text('Travel & Earn'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Coin Display (Hero Section)
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withOpacity(0.1),
                border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, size: 50, color: Colors.amber),
                  const SizedBox(height: 10),
                  Text(
                    _coins.toStringAsFixed(2),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                  const Text('COINS EARNED', style: TextStyle(color: Colors.amberAccent, letterSpacing: 2)),
                ],
              ),
            ),
            const Spacer(),
            
            // Metrics Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMetricCard(
                  'DISTANCE', 
                  '${_totalDistance.toStringAsFixed(1)} m', 
                  Icons.map,
                  Colors.blueAccent
                ),
                _buildMetricCard(
                  'SPEED', 
                  '${(_currentSpeed * 3.6).toStringAsFixed(1)} km/h', // Convert m/s to km/h
                  Icons.speed,
                  Colors.greenAccent
                ),
              ],
            ),
            const Spacer(),

            // Control Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _toggleTracking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTracking ? Colors.red.shade800 : Colors.teal.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 10,
                  ),
                  icon: Icon(_isTracking ? Icons.stop_circle_outlined : Icons.play_circle_outline, size: 30),
                  label: Text(
                    _isTracking ? 'STOP TRACKING' : 'START TRACKING', 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ),
            ),
            
            // Status Indicator
            if (_isTracking)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('GPS Active - Tracking...', style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 15),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 5),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade400, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
