import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:cutout/models/u2net_model.dart';

class U2NetScreen extends StatefulWidget {
  const U2NetScreen({super.key});

  @override
  U2NetScreenState createState() => U2NetScreenState();
}

class U2NetScreenState extends State<U2NetScreen> {
  String imagePath = 'assets/images/sample.jpg';
  final modelPath = 'assets/models/u2net.onnx';
  late U2NetModel model;
  late Directory tempDir;
  late String outputPath;
  bool _isInitialized = false;

  final ImagePicker _picker = ImagePicker();
  bool _useDefaultImage = true;
  bool _isSuccess = false;

  int? _loadModelTime;
  int? _runModelTime;

  String? _errorMessage;

  Key _imageKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      tempDir = await getTemporaryDirectory();
      await _cleanTempFiles();

      outputPath = '${tempDir.path}/postprocessed.png';

      final loadModelStartTime = DateTime.now();
      model = U2NetModel(modelPath);
      await model.initModel();
      final loadModelEndTime = DateTime.now();

      if (mounted) {
        setState(() {
          _loadModelTime = loadModelEndTime.difference(loadModelStartTime).inMilliseconds;
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Initialization error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Initialization failed: $e';
        });
      }
    }
  }

  Future<void> _cleanTempFiles() async {
    try {
      final dir = Directory(tempDir.path);
      if (await dir.exists()) {
        await for (final file in dir.list()) {
          if (file.path.toLowerCase().endsWith('.png')) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('Error cleaning temp files: $e');
    }
  }

  @override
  void dispose() {
    _cleanTempFiles();
    model.release();
    super.dispose();
  }

  Future<String> _readImage() async {
    final dir = await getTemporaryDirectory();

    if (_useDefaultImage) {
      final byteData = await rootBundle.load(imagePath);
      final buffer = byteData.buffer;
      final tempFile = File('${dir.path}/temp_image.png');
      await tempFile.writeAsBytes(buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      return tempFile.path;
    } else {
      return await _pickImage() ?? '';
    }
  }

  Future<void> inference() async {
    if (!_isInitialized) {
      print('Waiting for initialization...');
      await _initialize();
    }

    try {
      imageCache.clear();
      imageCache.clearLiveImages();

      setState(() {
        _imageKey = UniqueKey();
      });

      imagePath = await _readImage();

      if (imagePath.isEmpty) {
        setState(() {
          _errorMessage = 'Image path is not valid';
        });

        return;
      }

      final runModelStartTime = DateTime.now();
      final isSuccess = await model.run(imagePath, outputPath);
      final runModelEndTime = DateTime.now();
      _runModelTime = runModelEndTime.difference(runModelStartTime).inMilliseconds;

      setState(() {
        _isSuccess = isSuccess;
      });

      imageCache.clear();
      imageCache.clearLiveImages();

      setState(() {
        _errorMessage = null;
        _imageKey = UniqueKey();
      });
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<void> changeUseDefaultImage() async {
    setState(() {
      _useDefaultImage = !_useDefaultImage;
    });

    if (_useDefaultImage) {
      imagePath = 'assets/images/sample.jpg';
    }
  }

  Future<String?> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      // file extension is not jpg, jpeg or png
      if (image != null &&
          !image.path.toLowerCase().endsWith('.jpg') &&
          !image.path.toLowerCase().endsWith('.jpeg') &&
          !image.path.toLowerCase().endsWith('.png')) {
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/temp_picked_image.jpg';
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(await image!.readAsBytes());
      return tempPath;
    } catch (e) {
      print('Error picking image: $e');
    }
    return null;
  }

  Widget _buildImageWithCache(String? path) {
    if (path == null || !_isInitialized || !File(path).existsSync()) {
      return Container();
    }

    return Image.file(
      File(path),
      key: _imageKey,
      cacheWidth: null,
      cacheHeight: null,
      gaplessPlayback: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('U2Net Demo')),
      body: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 50),
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: changeUseDefaultImage,
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              _useDefaultImage ? Colors.blue.shade100 : Colors.red.shade100,
                            ),
                          ),
                          child: Text(_useDefaultImage ? 'Use Default Image' : 'Use Picked Image'),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: inference,
                      child: const Text('Inference'),
                    ),
                    if (_loadModelTime != null) Text('Load model time: $_loadModelTime ms'),
                    if (_runModelTime != null) Text('Run model time: $_runModelTime ms'),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_errorMessage != null) Text(_errorMessage!),
                    SizedBox(
                      width: 150,
                      child: _isInitialized && _isSuccess ? _buildImageWithCache(imagePath) : Container(),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 150,
                      child: _isInitialized && _isSuccess ? _buildImageWithCache(outputPath) : Container(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
