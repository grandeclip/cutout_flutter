import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

import 'package:cutout/cutout_binding.dart';
import 'package:cutout/models/isolate_helper.dart';

class SAMModel with IsolateHelperMixin {
  static final CutoutBinding _binding = CutoutBinding();

  final String encoderPath;
  final String decoderPath;
  OrtSessionOptions? _sessionOptions;
  OrtSession? _encoderSession;
  OrtSession? _decoderSession;
  ffi.Pointer<SAMImage>? _samInstance;

  SAMModel(this.encoderPath, this.decoderPath) {
    OrtEnv.instance.init();
    _samInstance = _binding.createSAM();
  }

  Future<void> initModel() async {
    _sessionOptions = OrtSessionOptions();

    final rawEncoderModelFile = await rootBundle.load(encoderPath);
    final encoderModelBytes = rawEncoderModelFile.buffer.asUint8List();
    _encoderSession = OrtSession.fromBuffer(encoderModelBytes, _sessionOptions!);

    final rawDecoderModelFile = await rootBundle.load(decoderPath);
    final decoderModelBytes = rawDecoderModelFile.buffer.asUint8List();
    _decoderSession = OrtSession.fromBuffer(decoderModelBytes, _sessionOptions!);
  }

  Future<void> release() async {
    try {
      _binding.destroySAM(_samInstance!);
      _encoderSession?.release();
      _decoderSession?.release();
      _sessionOptions?.release();
    } finally {
      _samInstance = null;
      _encoderSession = null;
      _decoderSession = null;
      _sessionOptions = null;
    }
  }

  Future<Float32List> _encode(Float32List preprocessedImage) async {
    // Should be input tensor size is [1, 3, 1024, 1024]
    final inputOrtValue = OrtValueTensor.createTensorWithDataList(preprocessedImage, [1, 3, 1024, 1024]);
    final runOptions = OrtRunOptions();
    // Input name should be "image"
    final inputs = {"image": inputOrtValue};
    final List<OrtValue?>? outputs;
    outputs = _encoderSession?.run(runOptions, inputs);

    inputOrtValue.release();
    runOptions.release();

    // output is [1, 256, 64, 64]
    final output = (outputs?[0]?.value as List<List<List<List<double>>>>)[0]; // [256, 64, 64]

    // Release the outputs
    outputs?.forEach((output) => output?.release());

    return Float32List.fromList(output.expand((x) => x.expand((y) => y)).toList());
  }

  Future<(Float32List, Float32List)> _decode(
    Float32List features,
    Float32List transformedCoords,
    Float32List transformedLabels,
  ) async {
    final totalPoints = transformedLabels.length;

    // Should be features tensor size is [1, 256, 64, 64]
    final featuresOrtValue = OrtValueTensor.createTensorWithDataList(features, [1, 256, 64, 64]);
    // Should be coords tensor size is [1, n, 2]
    final coordsOrtValue = OrtValueTensor.createTensorWithDataList(transformedCoords, [1, totalPoints, 2]);
    // Should be labels tensor size is [1, n]
    final labelsOrtValue = OrtValueTensor.createTensorWithDataList(transformedLabels, [1, totalPoints]);

    final runOptions = OrtRunOptions();
    final inputs = {
      "image_embeddings": featuresOrtValue,
      "point_coords": coordsOrtValue,
      "point_labels": labelsOrtValue
    };
    final List<OrtValue?>? outputs;
    outputs = _decoderSession?.run(runOptions, inputs);

    featuresOrtValue.release();
    coordsOrtValue.release();
    labelsOrtValue.release();
    runOptions.release();

    // scores is [1, 4]
    // masks is [1, 4, 256, 256]
    final scores = (outputs?[0]?.value as List<List<double>>)[0]; // [4]
    final masks = (outputs?[1]?.value as List<List<List<List<double>>>>)[0]; // [4, 256, 256]

    // Release the outputs
    outputs?.forEach((output) => output?.release());

    // Flatten the output
    return (
      Float32List.fromList(scores),
      Float32List.fromList(masks.expand((x) => x.expand((y) => y)).toList()),
    );
  }

  Future<(bool, Float32List?)> preprocessAndEncode(String imagePath) async {
    return await loadWithIsolate(() async {
      final preprocessedImage = await _binding.preprocessSAM(_samInstance!, imagePath);
      final features = await _encode(preprocessedImage);
      await _binding.setFeaturesSAM(_samInstance!, features);

      final isSuccess = _binding.checkSetImageSAM(_samInstance!);

      return (isSuccess, features);
    });
  }

  Future<bool> invokeSAM(Float32List features, String maskPath) async {
    return await loadWithIsolate(() async {
      final (transformedCoords, transformedLabels) = await _binding.transformCoordsSAM(_samInstance!);
      final (scores, masks) = await _decode(features, transformedCoords, transformedLabels);

      _binding.postprocessSAM(_samInstance!, scores, masks);

      _binding.getMaskSAM(_samInstance!, maskPath);

      return true;
    });
  }

  Future<void> clear() async {
    return await loadWithIsolate(() async {
      _binding.clearSAM(_samInstance!);
    });
  }

  Future<void> addPointAndLabelSAM(Int32List coord, Int32List label) async {
    return await loadWithIsolate(() async {
      _binding.addPointAndLabelSAM(_samInstance!, coord, label);
    });
  }

  Future<void> popPointAndLabelSAM() async {
    return await loadWithIsolate(() async {
      _binding.popPointAndLabelSAM(_samInstance!);
    });
  }

  Future<int> getTotalPointsSAM() async {
    return await loadWithIsolate(() async {
      return _binding.getTotalPointsSAM(_samInstance!);
    });
  }

  Future<(List<List<int>>, List<int>)> getPointsAndLabelsSAM() async {
    return await loadWithIsolate(() async {
      final (coords, labels) = await _binding.getPointsAndLabelsSAM(_samInstance!);
      final totalPoints = labels.length;

      final coordsList = List<List<int>>.filled(totalPoints, []);
      for (int i = 0; i < totalPoints * 2; i += 2) {
        coordsList[i ~/ 2] = [coords[i], coords[i + 1]];
      }

      final labelsList = List<int>.filled(totalPoints, -1);
      for (int i = 0; i < totalPoints; i++) {
        labelsList[i] = labels[i];
      }

      return (coordsList, labelsList);
    });
  }

  Future<void> makeSticker(String outputPath) async {
    return await loadWithIsolate(() async {
      _binding.makeStickerSAM(_samInstance!, outputPath);
    });
  }
}
