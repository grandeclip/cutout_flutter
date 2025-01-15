import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:cutout/models/sam_model.dart';

class SAMScreen extends StatefulWidget {
  const SAMScreen({super.key});

  @override
  SAMScreenState createState() => SAMScreenState();
}

class SAMScreenState extends State<SAMScreen> {
  String imagePath = 'assets/images/sample.jpg';
  final encodeModelPath = 'assets/models/sam_encoder.onnx';
  final decodeModelPath = 'assets/models/sam_decoder.onnx';
  late SAMModel model;
  late Directory tempDir;
  late String outputPath;
  late String outputMaskPath;
  late String outputMaskedImagePath;
  Float32List? _features;
  bool _isInitialized = false;
  bool _isSticker = false;

  final ImagePicker _picker = ImagePicker();
  bool _useDefaultImage = true;
  bool _isPrepareSuccess = false;

  int? _loadModelTime;
  int? _runEncodeModelTime;
  int? _runDecodeModelTime;

  String? _selectedCoords;
  String? _errorMessage;

  Key _imageKey = UniqueKey();
  Key _stickerImageKey = UniqueKey();
  // 이미지 컨테이너의 크기를 측정하기 위한 key 추가
  final GlobalKey _boxImageKey = GlobalKey();
  final GlobalKey _boxStickerImageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      tempDir = await getTemporaryDirectory();
      await _cleanTempFiles();

      outputPath = '${tempDir.path}/output.png';
      outputMaskPath = '${tempDir.path}/output_mask.png';

      final loadModelStartTime = DateTime.now();
      model = SAMModel(encodeModelPath, decodeModelPath);
      await model.initModel();
      final loadModelEndTime = DateTime.now();

      setState(() {
        _loadModelTime = loadModelEndTime.difference(loadModelStartTime).inMilliseconds;
        _isInitialized = true;
      });
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

  Widget _buildImageWithCache(String? path) {
    if (path == null || !_isInitialized || !File(path).existsSync()) {
      return Container();
    }

    // 이미지 파일을 먼저 로드하여 원본 크기 정보를 얻습니다
    final image = Image.file(
      File(path),
      key: _imageKey,
      cacheWidth: null,
      cacheHeight: null,
      gaplessPlayback: false,
      fit: BoxFit.contain,
    );

    return SizedBox(
      key: _boxImageKey,
      width: 400, // 최대 너비 지정
      child: GestureDetector(
        onTapDown: (TapDownDetails details) {
          _handleImageTap(details.localPosition, path);
        },
        child: image,
      ),
    );
  }

  Widget _buildStickerImageWithCache(String? path) {
    if (path == null || !_isInitialized || !File(path).existsSync()) {
      return Container();
    }

    // 이미지 파일을 먼저 로드하여 원본 크기 정보를 얻습니다
    final image = Image.file(
      File(path),
      key: _stickerImageKey,
      cacheWidth: null,
      cacheHeight: null,
      gaplessPlayback: false,
      fit: BoxFit.contain,
    );

    return SizedBox(
      key: _boxStickerImageKey,
      width: 400, // 최대 너비 지정
      child: image,
    );
  }

  Future<void> _handleImageTap(Offset tapPosition, String imagePath) async {
    // 현재 표시된 이미지의 실제 크기를 구합니다
    final RenderBox renderBox = _boxImageKey.currentContext?.findRenderObject() as RenderBox;
    final Size displaySize = renderBox.size;

    // 원본 이미지의 크기를 구합니다
    final File imageFile = File(imagePath);
    final Uint8List bytes = await imageFile.readAsBytes();
    final ui.Image originalImage = await decodeImageFromList(bytes);

    // 비율 계산
    final scaleX = originalImage.width / displaySize.width;
    final scaleY = originalImage.height / displaySize.height;

    // 클릭 좌표를 원본 이미지의 좌표로 변환
    final originalX = (tapPosition.dx * scaleX).round();
    final originalY = (tapPosition.dy * scaleY).round();

    // 좌표가 이미지 범위 내에 있는지 확인
    if (originalX >= 0 && originalX < originalImage.width && originalY >= 0 && originalY < originalImage.height) {
      // SAM 모델에 좌표 전달
      final coord = Int32List.fromList([originalX, originalY]);
      final label = Int32List.fromList([1]); // 1은 positive point를 의미

      await model.addPointAndLabelSAM(coord, label);
      final totalPoints = await model.getTotalPointsSAM();
      print('Added - total points: $totalPoints');

      final (coords, labels) = await model.getPointsAndLabelsSAM();
      print('All coords: $coords');
      print('All labels: $labels');

      final runDecodeModelStartTime = DateTime.now();
      await model.invokeSAM(_features!, outputMaskPath);
      final runDecodeModelEndTime = DateTime.now();
      _runDecodeModelTime = runDecodeModelEndTime.difference(runDecodeModelStartTime).inMilliseconds;

      setState(() {
        _isSticker = false;
        _selectedCoords = coords.toString();
      });
    }
  }

  Future<void> changeUseDefaultImage() async {
    setState(() {
      _useDefaultImage = !_useDefaultImage;

      if (_useDefaultImage) {
        imagePath = 'assets/images/sample.jpg';
      }
    });
  }

  Future<void> preprocessAndEncode() async {
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

      await model.clear();
      final runEncodeModelStartTime = DateTime.now();
      final (isPrepareSuccess, features) = await model.preprocessAndEncode(imagePath);
      final runEncodeModelEndTime = DateTime.now();
      _runEncodeModelTime = runEncodeModelEndTime.difference(runEncodeModelStartTime).inMilliseconds;

      setState(() {
        _isPrepareSuccess = isPrepareSuccess;
        outputMaskedImagePath = imagePath;
        _features = features;
      });

      imageCache.clear();
      imageCache.clearLiveImages();

      setState(() {
        _errorMessage = null;
        _imageKey = UniqueKey();
        _isSticker = false;
      });
    } catch (e) {
      print('Error preprocess and encode: $e');
    }
  }

  Future<void> makeSticker() async {
    imageCache.clear();
    imageCache.clearLiveImages();

    await model.makeSticker(outputPath);

    setState(() {
      _stickerImageKey = UniqueKey();
      _isSticker = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SAM Demo')),
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
                        const SizedBox(width: 20),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: preprocessAndEncode,
                          child: const Text('Prepare'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: makeSticker,
                          child: const Text('Inference'),
                        ),
                      ],
                    ),
                    if (_loadModelTime != null) Text('Load model time: $_loadModelTime ms'),
                    if (_runEncodeModelTime != null) Text('Run encode model time: $_runEncodeModelTime ms'),
                    if (_selectedCoords != null) Text('Selected coords: $_selectedCoords'),
                    if (_runDecodeModelTime != null) Text('Run decode model time: $_runDecodeModelTime ms'),
                  ],
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null) Text(_errorMessage!),
                if (!_isSticker)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      child: _isInitialized && _isPrepareSuccess
                          ? _buildImageWithCache(outputMaskedImagePath)
                          : Container(),
                    ),
                  ),
                if (_isSticker)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        child: _buildImageWithCache(imagePath),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 150,
                        child: _buildStickerImageWithCache(outputPath),
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
