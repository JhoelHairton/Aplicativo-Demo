import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';  // Importamos Geolocator

const String MAPBOX_ACCESS_TOKEN = 'pk.eyJ1IjoiZnJhbmt0eHQiLCJhIjoiY20zbmt2djI0MHQ2NjJqcTF3dmphcnJoOSJ9.UJs1cSyS_x9S3nZi70_bcg';  // Define tu token aquí

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Marker> _markers = [];
  List<LatLng> _route = [];
  LatLng? _origin;
  LatLng? _destination;
  LatLng? _currentLocation;
  MapController _mapController = MapController();  // Controlador del mapa

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Obtener la ubicación al inicio
  }

  // Método para obtener la ubicación actual del usuario
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si los servicios de geolocalización están habilitados
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Si no están habilitados, notificar al usuario
      return;
    }

    // Verificar permisos de geolocalización
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Si el permiso es denegado, no podemos acceder a la ubicación
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Si el permiso está permanentemente denegado, no podemos acceder a la ubicación
      return;
    }

    // Obtener la ubicación actual
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      // Centrar el mapa en la ubicación actual
      _mapController.move(_currentLocation!, 13.0);
      // Actualizamos el marcador con la ubicación actual
      _markers = [
        Marker(
          width: 80.0,
          height: 80.0,
          point: _currentLocation!,
          child: const Icon(
            Icons.location_on,
            color: Colors.blue,
            size: 40.0,
          ),
        ),
      ];
    });
  }

  // Función para borrar los marcadores
  void _clearMarkers() {
    setState(() {
      _markers.clear();
      _origin = null;
      _destination = null;
      _route.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa con Ruta Dinámica y Geolocalización'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,  // Asignamos el controlador al mapa
            options: MapOptions(
              center: _currentLocation ?? LatLng(-16.5000, -68.1500), // Usamos la ubicación actual si está disponible
              zoom: 13.0,
              onTap: (tapPosition, point) {
                if (_origin == null) {
                  setState(() {
                    _origin = point;
                    _markers.add(Marker(
                      width: 80.0,
                      height: 80.0,
                      point: point,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40.0),
                    ));
                  });
                } else if (_destination == null) {
                  setState(() {
                    _destination = point;
                    _markers.add(Marker(
                      width: 80.0,
                      height: 80.0,
                      point: point,
                      child: const Icon(Icons.location_on, color: Colors.green, size: 40.0),
                    ));
                    // Llamamos a la función para obtener la ruta
                    _getRoute(_origin!, _destination!);
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token=$MAPBOX_ACCESS_TOKEN',
                additionalOptions: {
                  'id': 'mapbox/streets-v11',
                },
              ),
              MarkerLayer(markers: _markers),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _route,  // Coordenadas de la ruta calculada
                    strokeWidth: 4.0,
                    color: Colors.blue,  // Color de la ruta
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,  // Llama a la función para obtener la ubicación actual
              child: const Icon(Icons.my_location),  // Icono del botón
              backgroundColor: Colors.blue,
            ),
          ),
          Positioned(
            bottom: 100,
            left: 20,
            child: FloatingActionButton(
              onPressed: _clearMarkers,  // Llama a la función para borrar los marcadores
              child: const Icon(Icons.clear),  // Icono para borrar marcadores
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // Método para obtener la ruta usando la API de Mapbox Directions
  Future<void> _getRoute(LatLng origin, LatLng destination) async {
    final url = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?geometries=geojson&access_token=$MAPBOX_ACCESS_TOKEN',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final route = data['routes'][0]['geometry']['coordinates'] as List;
        List<LatLng> routePoints = route.map((point) => LatLng(point[1], point[0])).toList();

        setState(() {
          _route = routePoints;
        });
      } else {
        throw Exception('Failed to load route');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}