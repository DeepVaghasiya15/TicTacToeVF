import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image/image.dart' as img;

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
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
  bool _showShutterEffect = false; // Boolean to control shutter effect display

  final AudioPlayer _audioPlayer = AudioPlayer(); // Initialize audio player

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _loadQueueFromLocalStorage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _stopTimer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Save the queue to local storage when app goes to background
      _saveQueueToLocalStorage();
    } else if (state == AppLifecycleState.resumed) {
      // Reload the queue and check network when the app comes back to the foreground
      _loadQueueFromLocalStorage().then((_) {
        _checkNetworkAndUpload();
      });
    }
  }


  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      _controller = CameraController(
        cameras![selectedCameraIndex],
        ResolutionPreset.veryHigh,
      );
      _initializeControllerFuture = _controller.initialize();
      setState(() {});
    }
  }

  Future<void> _checkNetworkAndUpload() async {
    ConnectivityResult result = (await Connectivity().checkConnectivity()) as ConnectivityResult;
    isConnected = result == ConnectivityResult.mobile || result == ConnectivityResult.wifi;

    if (isConnected) {
      _processUploadQueue();
    }
  }

  Future<void> _toggleCamera() async {
    if (cameras == null || cameras!.isEmpty) {
      return;
    }
    selectedCameraIndex = (selectedCameraIndex + 1) % cameras!.length;
    await _initializeCamera();
  }

  Future<void> _recordVideo() async {
    try {
      if (isRecording) {
        if (_controller.value.isRecordingVideo) {
          XFile videoFile = await _controller.stopVideoRecording();
          _stopTimer();
          setState(() {
            isRecording = false;
          });
          _queueUpload(File(videoFile.path));
        } else {
          print('Error: Not currently recording video');
        }
      } else {
        final directory = await getTemporaryDirectory();
        final path = join(directory.path, '${DateTime.now()}.mp4');
        await _controller.startVideoRecording();
        _startTimer();
        setState(() {
          isRecording = true;
        });
      }
    } catch (e, stacktrace) {
      print('Error recording video: $e');
      print('Stacktrace: $stacktrace');
    }
  }


  void _startTimer() {
    _elapsedTime = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  // Updated _takePhoto method with sound and shutter effect
  // Updated _takePhoto method with queue logic
  Future<void> _takePhoto() async {
    try {
      await _initializeControllerFuture;
      // Play shutter sound
      _audioPlayer.play(AssetSource('assets/shutter.mp3'));
      // Show shutter effect
      setState(() {
        _showShutterEffect = true;
      });
      // Hide the effect after 150 milliseconds
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() {
        _showShutterEffect = false;
      });

      // Capture photo
      XFile picture = await _controller.takePicture();
      File photoFile = File(picture.path);

      // Check if the camera is the front camera
      if (_controller.description.lensDirection == CameraLensDirection.front) {
        // Flip the photo horizontally if it's the front camera
        photoFile = await _flipPhoto(photoFile);
      }

      // Queue the photo for upload
      _queueUpload(photoFile);
      // Trigger queue processor after queuing the photo
      _processUploadQueue();
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

// Method to flip the photo horizontally
  Future<File> _flipPhoto(File photoFile) async {
    final img.Image originalImage = img.decodeImage(await photoFile.readAsBytes())!;
    final img.Image flippedImage = img.flipHorizontal(originalImage);

    final Directory tempDir = await getTemporaryDirectory();
    final String newFilePath = '${tempDir.path}/flipped_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final File flippedFile = File(newFilePath);

    await flippedFile.writeAsBytes(img.encodeJpg(flippedImage));

    return flippedFile;
  }


// Updated _queueUpload method to ensure it triggers upload if connected
  void _queueUpload(File file) {
    uploadQueue.add(file); // Add the file to the upload queue
    _saveQueueToLocalStorage(); // Save the queue to local storage
    if (isConnected) {
      _processUploadQueue(); // Start processing the queue if connected
    } else {
      print('No internet connection. File added to upload queue.');
    }
  }

// Ensure the queue is processed in the background
  Future<void> _processUploadQueue() async {
    if (!isUploading && uploadQueue.isNotEmpty) {
      isUploading = true;
      while (uploadQueue.isNotEmpty) {
        File file = uploadQueue.removeAt(0); // Remove the file from the queue
        await _uploadToFirebase(file); // Upload the file to Firebase
      }
      await _clearQueueFromLocalStorage(); // Clear the queue after successful upload
      isUploading = false;
    }
  }


  Future<void> _uploadToFirebase(File file) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String email = user.email ?? 'unknown_user';
        String fileName = file.path.endsWith('.mp4')
            ? '$email/${DateTime.now()}.mp4'
            : '$email/${DateTime.now()}.png';

        Reference firebaseStorageRef = FirebaseStorage.instance.ref().child(fileName);
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

  Future<void> _saveQueueToLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> paths = uploadQueue.map((file) => file.path).toList();
    await prefs.setStringList('uploadQueue', paths);
  }

  Future<void> _loadQueueFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? paths = prefs.getStringList('uploadQueue');
    if (paths != null) {
      uploadQueue = paths.map((path) => File(path)).toList();
    }
  }

  Future<void> _clearQueueFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('uploadQueue');
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
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: constraints.maxWidth,   // Use the available width
                            height: constraints.maxHeight - 80, // Use the available height
                            child: CameraPreview(_controller), // The camera preview
                          ),
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
          if (_showShutterEffect) // Shutter effect (brief white overlay)
            Container(
              color: Colors.white.withOpacity(0.8),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: _recordVideo,
            backgroundColor: isRecording ? Colors.red : Colors.white,
            child: Icon(Icons.videocam,color: isRecording ? Colors.white : Colors.red,),
          ),
          SizedBox(width: 25,),
          FloatingActionButton(
            onPressed: _takePhoto,
            backgroundColor: Colors.white,
            child: const Icon(Icons.camera_alt_rounded,color: Colors.black,),
          ),
          SizedBox(width: 25,),
          FloatingActionButton(
            onPressed: _toggleCamera,
            child: const Icon(Icons.switch_camera),
          ),
        ],
      ),
    );
  }

  String _formatElapsedTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}
