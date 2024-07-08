import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SpeedTrackingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SpeedTrackingPage extends StatefulWidget {
  @override
  _SpeedTrackingPageState createState() => _SpeedTrackingPageState();
}

class _SpeedTrackingPageState extends State<SpeedTrackingPage> {
  final LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 0,
  );
  KalmanFilter kalmanFilter = KalmanFilter(q: 0.001, r: 1.0, x: 0.0, p: 1.0);
  double filteredSpeed = 0.0;
  double rawSpeed = 0.0;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  void _startTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Serviço de localização não está habilitado
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }
    Geolocator.getPositionStream(
      locationSettings: locationSettings,

    ).listen((Position position) {
      if (position != null) {
        setState(() {
          rawSpeed = position.speed; // Velocidade em m/s
          filteredSpeed = kalmanFilter.filter(rawSpeed);
        });
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rastreamento de Velocidade'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Velocidade Sem Filtro: ${rawSpeed.toStringAsFixed(2)} m/s',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Text(
              'Velocidade Filtrada: ${filteredSpeed.toStringAsFixed(2)} m/s',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Text(
              'Kalman Filter Parameters:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Estimativa (x): ${kalmanFilter.x.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              'Covariância do Erro de Estimativa (p): ${kalmanFilter.p.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              'Ganho de Kalman (k): ${kalmanFilter.k.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class KalmanFilter {
  double q; // Covariância do ruído do processo
  double r; // Covariância do ruído da medição
  double x; // Valor estimado (velocidade)
  double p; // Covariância do erro de estimativa
  late double k; // Ganho de Kalman

  KalmanFilter({this.q = 0.001, this.r = 1.0, this.x = 0.0, this.p = 1.0}) : k = 0.0;

  double filter(double measurement) {

    p = p + q;
    k = p / (p + r);
    x = x + k * (measurement - x);
    p = (1 - k) * p;

    return x;
  }
}
