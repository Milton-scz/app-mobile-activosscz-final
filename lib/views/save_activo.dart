import 'package:flutter/material.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';

class SaveActivo extends StatefulWidget {
  final String nombre;
  final String imagePath;

  const SaveActivo({Key? key, required this.imagePath, required this.nombre})
      : super(key: key);

  @override
  _SaveActivoState createState() => _SaveActivoState();
}

class _SaveActivoState extends State<SaveActivo> {
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();

  final Dio _dio = Dio();
  String? _selectedCategoria;
  List<String> categorias = [
    'Electronica',
    'Mobiliario',
    'Oficina',
    'Vehículos',
    'Maquinaria',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    _nombreController.text = widget.nombre;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Activo Fijo"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20),
            Image.file(
              File(widget.imagePath),
              width: 300,
              height: 300,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre del activo fijo',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _descripcionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: _selectedCategoria,
              onChanged: (value) {
                setState(() {
                  _selectedCategoria = value;
                });
              },
              items: categorias.map((String categoria) {
                return DropdownMenuItem<String>(
                  value: categoria,
                  child: Text(categoria),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () {
                _enviarDatos();
              },
              child: Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _enviarDatos() async {
    try {
      await enviarDatosAlEndpoint();
    } catch (e) {
      print('Error al copiar el archivo: $e');
      // Mostrar un toast de error
      Fluttertoast.showToast(
        msg: 'Error al guardar el activo fijo',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> enviarDatosAlEndpoint() async {
    try {
      final response = await _dio.post(
        "https://back-microservicio-mobilexd.fly.dev/add-activo",
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
        data: {
          "nombre": _nombreController,
          "descripcion": _descripcionController,
          "fechaAdquisicion": "12/03/2024",
          "precio": "230",
          "estado": "nuevo",
          "categoria": "Oficina",
          "urlPhoto": widget.imagePath
        },
      );

      final jsonResponse = response.data;

      if (jsonResponse['error'] != null) {
        Fluttertoast.showToast(
          msg: 'Error al subir la imagen',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
      Fluttertoast.showToast(
        msg: 'Imagen subida con éxito',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (error) {
      throw Exception('Error: $error');
    }
  }
}
