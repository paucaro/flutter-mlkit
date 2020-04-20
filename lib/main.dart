import 'package:flutter/material.dart';
import 'package:interview_face_detector/app.dart';
import 'package:interview_face_detector/camera_app.dart';

void main() => runApp(
  MaterialApp(
    title: 'Face Recognition in Interview',
    theme: ThemeData(
      primarySwatch: Colors.pink
    ),
    home: CameraApp(),
  )
);



