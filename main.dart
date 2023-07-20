import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _selectedColor = 'Proceso 1';
  String _documento = '';

@override
  void initState() {
    super.initState();
    _selectedColor = 'Proceso 1';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Firma Consentimientos Informados'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<String>(
                value: _selectedColor,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedColor = newValue!;
                  });
                },
                items: <String>['Proceso 1', 'Proceso 2', 'Proceso 3']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                onChanged: (value) {
                  setState(() {
                    _documento = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Número de Documento',
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      MyCustomPainter.points.add(details.localPosition);
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      MyCustomPainter.points.add(details.localPosition);
                    });
                  },
                  onPanEnd: (details) {
                    setState(() {
                      MyCustomPainter.points.add(null);
                    });
                  },
                  child: RepaintBoundary(
                    key: _containerKey,
                    child: CustomPaint(
                      size: const Size(double.infinity, double.infinity),
                      painter: MyCustomPainter(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  uploadImage();
                },
                child: const Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  GlobalKey _containerKey = GlobalKey();
  ui.Image? capturedImage;

  Future<ui.Image> captureImage() async {
    RenderRepaintBoundary boundary = _containerKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    return image;
  }

  Future<void> uploadImage() async {
    ui.Image image = await captureImage();
    await uploadImageToFirebaseStorage(image);
  }

// Function to upload drawn image to Firebase Storage
  Future<void> uploadImageToFirebaseStorage(ui.Image image) async {
    // Convert the drawn image to bytes
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final Uint8List pngBytes = byteData.buffer.asUint8List();

    // Create a reference to the Firebase Storage location
    final firebase_storage.Reference storageRef = firebase_storage
        .FirebaseStorage.instance
        .ref()
        .child('${DateTime.now()}.png');

    // Upload the PNG bytes to Firebase Storage
    await storageRef.putData(pngBytes);
    final String downloadURL = await storageRef.getDownloadURL();

    print('Image uploaded to Firebase Storage.');
    print(downloadURL);
    print('mierda');
    print(_selectedColor);
    if(_selectedColor=='Proceso 1'){
      _selectedColor='1';
    }
    if(_selectedColor=='Proceso 2'){
      _selectedColor='2';
    }
    if(_selectedColor=='Proceso 3'){
      _selectedColor='3';
    }
    // Data to send in the body of the request
  final Map<String, String> requestData = {
    'documento': _documento,
    'consentimiento': _selectedColor,
    'firma':downloadURL
  };

// Call the Google Cloud Function using http.post
  final response = await http.post(
    Uri.parse('https://us-central1-sismedicorafaelrivera.cloudfunctions.net/registerDataX4'),
    body: requestData,
  );

  }
}

class MyCustomPainter extends CustomPainter {
  static List<Offset?> points = [];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
