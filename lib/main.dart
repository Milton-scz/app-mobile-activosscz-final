import 'package:flutter/material.dart';
import 'package:activos_fijos/views/camera_view.dart';
import 'package:get/get.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home:
          CameraView(), // Asegúrate de que tu vista inicial esté configurada aquí
    );
  }
}
