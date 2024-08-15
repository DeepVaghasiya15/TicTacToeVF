import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
    if (isRecording) {
      XFile videoFile = await _controller.stopVideoRecording();
      _stopTimer();
      setState(() {
        isRecording = false;
      });
      print('Video saved to ${videoFile.path}');
      _navigateToPreviewScreen(videoFile.path, true);
    } else {
      final directory = await getTemporaryDirectory();
      final path = join(
        directory.path,
        '${DateTime.now()}.mp4',
      );
      await _controller.startVideoRecording();
      _startTimer();
      setState(() {
        isRecording = true;
      });
      print('Recording video to $path');
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

  // On Tap Focus
  void _onTapFocus(TapDownDetails details, BoxConstraints constraints) {
    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    _controller.setFocusPoint(offset);
  }

  // Navigate to Preview Screen
  void _navigateToPreviewScreen(String path, bool isVideo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewScreen(
          filePath: path,
          isVideo: isVideo,
        ),
      ),
    );
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
                      onTapDown: (details) => _onTapFocus(details, constraints),
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
            onPressed: () async {
              try {
                await _initializeControllerFuture;
                final directory = await getTemporaryDirectory();
                final path = join(
                  directory.path,
                  '${DateTime.now()}.png',
                );
                XFile picture = await _controller.takePicture();
                await picture.saveTo(path);
                print('Picture saved to $path');
                _navigateToPreviewScreen(path, false);
              } catch (e) {
                print(e);
              }
            },
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

// Preview Screen Widget
class PreviewScreen extends StatelessWidget {
  final String filePath;
  final bool isVideo;

  const PreviewScreen({
    Key? key,
    required this.filePath,
    required this.isVideo,
  }) : super(key: key);

  Future<void> _uploadToFirebaseStorage(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent user from dismissing dialog
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String email = user.email ?? ''; // Get the email address of the user
        String fileName =
        isVideo ? '$email/${DateTime.now()}.mp4' : '$email/${DateTime.now()}.png';

        Reference firebaseStorageRef =
        FirebaseStorage.instance.ref().child(fileName);
        File file = File(filePath);
        await firebaseStorageRef.putFile(file);
        // Optionally, you can get the download URL of the uploaded file
        String downloadURL = await firebaseStorageRef.getDownloadURL();
        // Handle the URL as needed (e.g., save it to a database)
        Navigator.pop(context); // Close the dialog
        Navigator.pop(context); // Close the PreviewScreen
        print('File uploaded to Firebase Storage. Download URL: $downloadURL');
      } else {
        // Handle case where user is not authenticated
        print('User not authenticated');
      }
    } catch (e) {
      print('Error uploading file to Firebase Storage: $e');
      Navigator.pop(context); // Close the dialog
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Preview",
            style: TextStyle(
              fontFamily: 'Lato',
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: Theme.of(context).colorScheme.inversePrimary,
            )),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: isVideo
                  ? AspectRatio(
                aspectRatio: 9 / 16,
                child: VideoPlayerScreen(filePath: filePath),
              )
                  : Image.file(File(filePath)),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Take Again',
                    style: TextStyle(
                        fontFamily: 'Lato', fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => _uploadToFirebaseStorage(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0), // Adjust padding to decrease height
                ),
                child: const Icon(Icons.check, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Video Player Screen Widget
class VideoPlayerScreen extends StatefulWidget {
  final String filePath;

  const VideoPlayerScreen({
    Key? key,
    required this.filePath,
  }) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.file(File(widget.filePath));

    await _videoController.initialize();

    _videoController.addListener(() {
      if (_videoController.value.position == _videoController.value.duration) {
        _videoController.seekTo(Duration.zero);
        _videoController.play();
      }
    });

    setState(() {});
    _videoController.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _videoController.value.isInitialized
          ? Center(
        child: AspectRatio(
          aspectRatio: _videoController.value.aspectRatio,
          child: VideoPlayer(_videoController),
        ),
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
