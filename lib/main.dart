import 'package:flutter/material.dart';
import 'package:gototo/screens/map_screen.dart';

void main() => runApp(const MyApp());

const String MAPBOX_ACCESS_TOKEN = 'pk.eyJ1IjoiZnJhbmt0eHQiLCJhIjoiY20zbmt2djI0MHQ2NjJqcTF3dmphcnJoOSJ9.UJs1cSyS_x9S3nZi70_bcg'; // Reemplaza con tu token

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapa con Marcadores',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const MapScreen(), // Se asegura de que el mapa sea la pantalla principal
    );
  }
}