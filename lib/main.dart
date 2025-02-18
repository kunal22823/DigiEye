import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  MyApp({required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: CameraScreen(cameras: cameras),
    );
  }
}

int totalCurrencyValue = 0;

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  CameraScreen({required this.cameras});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  final FlutterTts _flutterTts = FlutterTts();  // FlutterTts instance

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.cameras.first,
      ResolutionPreset.high,
    );

    try {
      await _cameraController?.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
      print("Camera initialized successfully.");
      await _flutterTts.speak("Welcome to DigiEye");

    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _captureImage() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      final XFile image = await _cameraController!.takePicture();
      print("Image captured: ${image.path}");
      await _flutterTts.speak("Image Captured");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayScreen(imagePath: image.path),
        ),
      );
    } else {
      print("Camera not initialized.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          width: double.infinity, // Makes the container occupy full width
          height: 60, // Set the height of the background behind the text
          alignment: Alignment.center, // Align text vertically
          color: Colors.black, // Background color for the text
          child: Text(
            "Digi-Eye",
            style: TextStyle(
              fontFamily: 'Roboto', // Custom font (change to your preferred font)
              fontSize: 26, // Adjust font size as needed
              fontWeight: FontWeight.bold, // You can adjust the weight
              color: Colors.white, // Text color
            ),
          ),
        ),
        backgroundColor: Colors.transparent, // Make the app bar background transparent
        elevation: 0, // Remove elevation to keep it clean
      ),
      body: _isCameraInitialized
          ? CameraPreview(_cameraController!)
          : Center(child: CircularProgressIndicator()),
      floatingActionButton: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact(); // Vibrates when button is tapped
          _captureImage(); // Trigger image capture
        }, // Trigger image capture
        child: Container(
          width: 100, // Width of the circular button
          height: 100, // Height of the circular button
          decoration: BoxDecoration(
            color: Colors.green, // Background color of the capture button
            shape: BoxShape.circle, // Makes the button circular
          ),
          child: Icon(
            Icons.camera_alt, // Camera icon
            size: 50, // Icon size
            color: Colors.black, // Icon color
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      backgroundColor: Colors.black, // Background color for the body
    );
  }
}

class DisplayScreen extends StatefulWidget {
  final String imagePath;

  DisplayScreen({required this.imagePath});

  @override
  _DisplayScreenState createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  String _result = '';
  final FlutterTts _flutterTts = FlutterTts();
  Interpreter? _interpreter;
  List<String>? _labels;

  @override
  void initState() {
    super.initState();
    _loadModelAndLabels();
  }

  Future<void> _loadModelAndLabels() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      _labels = await _loadLabels('assets/labels.txt');
      print("Model and labels loaded successfully.");
      print("Labels: $_labels");
      await _detectCurrency();
    } catch (e) {
      setState(() {
        _result = "Error loading model or labels: $e";
      });
      print("Error loading model or labels: $e");
    }
  }

  Future<List<String>> _loadLabels(String filePath) async {
    String labelsString = await rootBundle.loadString(filePath);
    return labelsString.split('\n').where((label) => label.isNotEmpty).toList();
  }

  Future<void> _detectCurrency() async {
    final img.Image image = img.decodeImage(File(widget.imagePath).readAsBytesSync())!;
    img.Image resizedImage = img.copyResize(image, width: 260, height: 260);

    // Convert to Float32 List for TFLite input
    List<List<List<double>>> input = _convertImageToTensor(resizedImage);

    var output = List.filled(1, List.filled(_labels!.length, 0.0));
    _interpreter!.run([input], output);

    int detectedIndex = output[0].indexWhere((val) => val == output[0].reduce((a, b) => a > b ? a : b));
    String detectedCurrency = (detectedIndex >= 0 && detectedIndex < _labels!.length)
        ? _labels![detectedIndex]
        : "Unknown";

    print("Detected: $detectedCurrency INR");

    setState(() {
      _result = detectedCurrency;
    });

    _speak(detectedCurrency);

    // Save to Firebase
    try {
      print("Adding detected currency to Firestore: $detectedCurrency");

      await FirebaseFirestore.instance.collection('detections').add({
        'currency': detectedCurrency,
        'timestamp': FieldValue.serverTimestamp(),
      }).then((docRef) {
        print("Successfully added to Firestore with ID: ${docRef.id}");
      });

    } catch (e) {
      print("Error adding to Firestore: $e");
    }

  }


  // Convert image to tensor format
  List<List<List<double>>> _convertImageToTensor(img.Image image) {
    List<List<List<double>>> tensor = List.generate(
        260, (i) => List.generate(260, (j) => List.filled(3, 0.0)));

    for (int y = 0; y < 260; y++) {
      for (int x = 0; x < 260; x++) {
        final pixel = image.getPixel(x, y);
        tensor[y][x][0] = img.getRed(pixel) / 255.0;
        tensor[y][x][1] = img.getGreen(pixel) / 255.0;
        tensor[y][x][2] = img.getBlue(pixel) / 255.0;
      }
    }
    return tensor;
  }

  Future<void> _speak(String text) async {
    print("Speaking: $text rupees detected"); // Debug print

    await _flutterTts.setLanguage("en-IN");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak("$text rupees detected");

    print("TTS speak function executed");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Detection Result"),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.file(File(widget.imagePath)),
            SizedBox(height: 20),
            Text("Detected Currency: $_result", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
