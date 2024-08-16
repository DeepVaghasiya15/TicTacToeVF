import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  List<CameraDescription>? cameras;
  int selectedCameraIndex = 0;
  bool isRecording = false;
  Timer? _timer;
  int _elapsedTime = 0;

  List<File> uploadQueue = [];
  bool isConnected = true;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Initialize Camera
  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      _controller = CameraController(
        cameras![selectedCameraIndex], // Select the camera based on the index
        ResolutionPreset.veryHigh,
      );
      _initializeControllerFuture = _controller.initialize();
      setState(() {}); // Rebuild the widget after the camera is initialized
    }
  }

  // Monitor Network Connectivity
  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    setState(() {
      isConnected = result.contains(ConnectivityResult.mobile) || result.contains(ConnectivityResult.wifi);
    });
    // Print connectivity status
    print('Connectivity changed: $result');

    // Optionally process the upload queue
    if (isConnected) {
      _processUploadQueue();
    }
  }


  // Toggle Camera
  Future<void> _toggleCamera() async {
    if (cameras == null || cameras!.isEmpty) {
      return;
    }
    selectedCameraIndex = (selectedCameraIndex + 1) % cameras!.length;
    await _initializeCamera();
  }

  // Record Video
  Future<void> _recordVideo() async {
    try {
      if (isRecording) {
        // Stop recording
        XFile videoFile = await _controller.stopVideoRecording();
        _stopTimer();
        setState(() {
          isRecording = false;
        });
        // Queue the recorded video for upload
        _queueUpload(File(videoFile.path));
      } else {
        // Start recording
        final directory = await getTemporaryDirectory();
        final path = join(directory.path, '${DateTime.now()}.mp4');
        await _controller.startVideoRecording();
        _startTimer();
        setState(() {
          isRecording = true;
        });
      }
    } catch (e) {
      print('Error recording video: $e');
    }
  }


  // Start Timer
  void _startTimer() {
    _elapsedTime = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime++;
      });
    });
  }

  // Stop Timer
  void _stopTimer() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _controller.dispose();
    _stopTimer();
    super.dispose();
  }

  // Capture Photo
  Future<void> _takePhoto() async {
    try {
      await _initializeControllerFuture;
      XFile picture = await _controller.takePicture();
      _queueUpload(File(picture.path));
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  // Queue upload if offline, or upload directly if online
  void _queueUpload(File file) {
    uploadQueue.add(file);
    if (isConnected) {
      _processUploadQueue();
    } else {
      print('No internet connection. File added to upload queue.');
    }
  }

  // Process Upload Queue
  void _processUploadQueue() async {
    if (!isUploading && uploadQueue.isNotEmpty) {
      isUploading = true;
      while (uploadQueue.isNotEmpty && isConnected) {
        File file = uploadQueue.removeAt(0);
        await _uploadToFirebase(file);
      }
      isUploading = false;
    }
  }

  // Upload to Firebase
  Future<void> _uploadToFirebase(File file) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String email = user.email ?? 'unknown_user';
        String fileName = file.path.endsWith('.mp4')
            ? '$email/${DateTime.now()}.mp4'
            : '$email/${DateTime.now()}.png';

        Reference firebaseStorageRef =
        FirebaseStorage.instance.ref().child(fileName);

        await firebaseStorageRef.putFile(file);
        String downloadURL = await firebaseStorageRef.getDownloadURL();
        print('File uploaded to Firebase: $downloadURL');
      } else {
        print('User not authenticated');
      }
    } catch (e) {
      print('Error uploading file to Firebase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Camera',
            style: TextStyle(
              fontFamily: 'Lato',
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: Theme.of(context).colorScheme.inversePrimary,
            )),
        centerTitle: true,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      child: CameraPreview(_controller),
                    );
                  },
                ),
                if (isRecording)
                  Positioned(
                    top: 5,
                    left: 100,
                    right: 100,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatElapsedTime(_elapsedTime),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return const Center(child: Text('Error initializing camera'));
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            heroTag: 'recordVideo',
            onPressed: _recordVideo,
            backgroundColor: isRecording ? Colors.red : null,
            child: Icon(isRecording ? Icons.stop : Icons.videocam),
          ),
          const SizedBox(width: 20),
          FloatingActionButton(
            heroTag: 'takePhoto',
            onPressed: _takePhoto,
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(width: 20),
          FloatingActionButton(
            heroTag: 'toggleCamera',
            onPressed: _toggleCamera,
            child: const Icon(Icons.switch_camera),
          ),
        ],
      ),
    );
  }

  // Format Elapsed Time
  String _formatElapsedTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
