import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'scanner_utils.dart';
import 'detector_painters.dart';

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {

  CameraController _camera;
  CameraLensDirection _direction =  CameraLensDirection.back;
  bool _isDetecting = false;
  dynamic _scanResults;

  final FaceDetector _faceDetector = FirebaseVision.instance.faceDetector();
  final options = FirebaseVision.instance.imageLabeler();
  
  @override
  void initState() {
    _initializeCamera();
  }

  void _initializeCamera() async {
    final CameraDescription description = 
      await ScannerUtils.getCamera(_direction);
    _camera = CameraController(
      description,
      defaultTargetPlatform == TargetPlatform.iOS
          ? ResolutionPreset.low
          : ResolutionPreset.medium
    );
    await _camera.initialize();

    _camera.startImageStream((CameraImage image) {
      if (_isDetecting) return;
       
      _isDetecting = true;

      ScannerUtils.detect(
        image: image, 
        detectInImage: _faceDetector.processImage, 
        imageRotation: description.sensorOrientation
      ).then(
        (dynamic results) {
          setState(() {
            _scanResults = results;
          });
        }
      ).whenComplete(() => _isDetecting = false);
    });
  }

  Widget _buildResults() {
    Text noResultsText = Text('No results!');

    if (_scanResults == null ||
        _camera == null ||
        !_camera.value.isInitialized) {
      return noResultsText;
    }

    CustomPainter painter;

    final Size imageSize = Size(
      _camera.value.previewSize.height,
      _camera.value.previewSize.width
    );

    if (_scanResults is! List<Face>) return noResultsText;
    painter = FaceDetectorPainter(imageSize, _scanResults);

    return CustomPaint(painter: painter,);
  }

  Widget _buildImage() {
    return Container(
      constraints: const BoxConstraints.expand(),
      child: _camera == null
          ? Center(
            child: Text(
              'Initializing camera...',
              style: TextStyle(
                color: Colors.green,
                fontSize: 30.0
              ),
            ),
          )
          : Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CameraPreview(_camera),
              _buildResults()
            ],
          )
    );
  }

  void _toggleCameraDirection() async {
    if (_direction == CameraLensDirection.back) {
      _direction = CameraLensDirection.front;
    } else {
      _direction = CameraLensDirection.back;
    }

    await _camera.stopImageStream();
    await _camera.dispose();

    setState(() {
      _camera = null;
    });

    _initializeCamera();
  }
  
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ML Vision'),
        actions: <Widget>[
          PopupMenuButton(
            itemBuilder: (BuildContext context) => <PopupMenuEntry>[
              PopupMenuItem(
                child: Text('Detect Face'),
              )
            ],

          )
        ],
      ),
      body: _buildImage(),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleCameraDirection,
        child: _direction == CameraLensDirection.back
            ? Icon(Icons.camera_front)
            : Icon(Icons.camera_rear),
      ),
    );
  }

  @override
  void dispose() {
    _camera.dispose().then((_) {
      _faceDetector.close();
    });
    
    super.dispose();
  }
}