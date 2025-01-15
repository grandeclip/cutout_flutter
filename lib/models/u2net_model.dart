import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

import 'package:cutout/cutout_binding.dart';
import 'package:cutout/models/isolate_helper.dart';

class U2NetModel with IsolateHelperMixin {
  static final CutoutBinding _binding = CutoutBinding();

  final String modelPath;
  OrtSessionOptions? _sessionOptions;
  OrtSession? _session;
  ffi.Pointer<U2NetSegmentImage>? _u2NetInstance;

  U2NetModel(this.modelPath) {
    OrtEnv.instance.init();
    _u2NetInstance = _binding.createU2Net();
  }

  Future<void> initModel() async {
    _sessionOptions = OrtSessionOptions();

    final rawModelFile = await rootBundle.load(modelPath);
    final modelBytes = rawModelFile.buffer.asUint8List();
    _session = OrtSession.fromBuffer(modelBytes, _sessionOptions!);
  }

  Future<void> release() async {
    try {
      _binding.destroyU2Net(_u2NetInstance!);
      _session?.release();
      _sessionOptions?.release();
    } finally {
      _u2NetInstance = null;
      _session = null;
      _sessionOptions = null;
    }
  }

  Future<Float32List> _preprocess(String imagePath) async {
    return await _binding.preprocessU2Net(_u2NetInstance!, imagePath);
  }

  Future<Float32List> _inference(Float32List preprocessedImage) async {
    // Should be input tensor size is [1, 3, 320, 320]
    final inputOrtValue = OrtValueTensor.createTensorWithDataList(preprocessedImage, [1, 3, 320, 320]);
    final runOptions = OrtRunOptions();
    // Input name should be "input.1"
    final inputs = {"input.1": inputOrtValue};
    final List<OrtValue?>? outputs;
    outputs = _session?.run(runOptions, inputs);

    inputOrtValue.release();
    runOptions.release();

    // Outputs are total 7 and the first one is the output of the model
    // Output size is [1, 1, 320, 320], so we get the last two dimensions
    final output = (outputs?[0]?.value as List<List<List<List<double>>>>)[0][0];

    // Release the outputs
    outputs?.forEach((output) => output?.release());

    // Flatten the output
    return Float32List.fromList(output.expand((x) => x).toList());
  }

  Future<bool> _postprocess(String imagePath, Float32List inferencedData, String outputPath) async {
    return await _binding.postprocessU2Net(_u2NetInstance!, inferencedData, outputPath);
  }

  /// Just a wrapper for the model inference
  Future<bool> run(String imagePath, String outputPath) async {
    return await loadWithIsolate(() async {
      final preprocessedImage = await _preprocess(imagePath);
      final inferencedData = await _inference(preprocessedImage);
      final isSuccess = await _postprocess(imagePath, inferencedData, outputPath);

      return isSuccess;
    });
  }
}
