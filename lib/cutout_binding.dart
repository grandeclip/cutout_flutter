import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

// C function signatures
// Start U2Net functions
base class U2NetSegmentImage extends ffi.Opaque {}

typedef _CCreateU2NetFunc = ffi.Pointer<U2NetSegmentImage> Function();
typedef _CDestroyU2NetFunc = ffi.Void Function(ffi.Pointer<U2NetSegmentImage>);
typedef _CClearU2NetFunc = ffi.Void Function(ffi.Pointer<U2NetSegmentImage>);
typedef _CPreprocessU2NetFunc = ffi.Void Function(
  ffi.Pointer<U2NetSegmentImage>,
  ffi.Pointer<Utf8>,
  ffi.Pointer<ffi.Float>,
);
typedef _CPostprocessU2NetFunc = ffi.Bool Function(
  ffi.Pointer<U2NetSegmentImage>,
  ffi.Pointer<ffi.Float>,
  ffi.Int32,
  ffi.Pointer<Utf8>,
);
// End U2Net functions

// Start SAMImage functions
base class SAMImage extends ffi.Opaque {}

typedef _CCreateSAMFunc = ffi.Pointer<SAMImage> Function();
typedef _CDestroySAMFunc = ffi.Void Function(ffi.Pointer<SAMImage>);
typedef _CClearSAMFunc = ffi.Void Function(ffi.Pointer<SAMImage>);
typedef _CPreprocessSAMFunc = ffi.Void Function(
  ffi.Pointer<SAMImage>,
  ffi.Pointer<Utf8>,
  ffi.Pointer<ffi.Float>,
);
typedef _CSetFeaturesSAMFunc = ffi.Void Function(
  ffi.Pointer<SAMImage>,
  ffi.Pointer<ffi.Float>,
  ffi.Int32,
);
typedef _CTransformCoordsSAMFunc = ffi.Void Function(
  ffi.Pointer<SAMImage>,
  ffi.Pointer<ffi.Float>,
  ffi.Pointer<ffi.Float>,
);
typedef _CPostprocessSAMFunc = ffi.Void Function(
  ffi.Pointer<SAMImage>,
  ffi.Pointer<ffi.Float>,
  ffi.Int32,
  ffi.Pointer<ffi.Float>,
  ffi.Int32,
);
typedef _CAddPointAndLabelSAMFunc = ffi.Bool Function(
  ffi.Pointer<SAMImage>,
  ffi.Pointer<ffi.Int32>,
  ffi.Pointer<ffi.Int32>,
);
typedef _CPopPointAndLabelSAMFunc = ffi.Bool Function(ffi.Pointer<SAMImage>);
typedef _CGetPointsAndLabelsSAMFunc = ffi.Void Function(
  ffi.Pointer<SAMImage>,
  ffi.Pointer<ffi.Int32>,
  ffi.Pointer<ffi.Int32>,
);
typedef _CGetMaskSAMFunc = ffi.Bool Function(
  ffi.Pointer<SAMImage>,
  ffi.Pointer<Utf8>,
);
typedef _CMakeStickerSAMFunc = ffi.Void Function(
  ffi.Pointer<SAMImage>,
  ffi.Pointer<Utf8>,
);
typedef _CGetTotalPointsSAMFunc = ffi.Int32 Function(ffi.Pointer<SAMImage>);
typedef _CCheckSetImageSAMFunc = ffi.Bool Function(ffi.Pointer<SAMImage>);
// End SAMImage functions

// Dart function signatures
// Start U2Net functions
typedef _CreateU2NetFunc = ffi.Pointer<U2NetSegmentImage> Function();
typedef _DestroyU2NetFunc = void Function(ffi.Pointer<U2NetSegmentImage>);
typedef _ClearU2NetFunc = void Function(ffi.Pointer<U2NetSegmentImage>);
typedef _PreprocessU2NetFunc = void Function(
  ffi.Pointer<U2NetSegmentImage>,
  ffi.Pointer<Utf8>,
  ffi.Pointer<ffi.Float>,
);
typedef _PostprocessU2NetFunc = bool Function(
  ffi.Pointer<U2NetSegmentImage>,
  ffi.Pointer<ffi.Float>,
  int,
  ffi.Pointer<Utf8>,
);
// End U2Net functions

// Start SAMImage functions
typedef _CreateSAMFunc = ffi.Pointer<SAMImage> Function();
typedef _DestroySAMFunc = void Function(ffi.Pointer<SAMImage>);
typedef _ClearSAMFunc = void Function(ffi.Pointer<SAMImage>);
typedef _PreprocessSAMFunc = void Function(
  ffi.Pointer<SAMImage>,
  ffi.Pointer<Utf8>,
  ffi.Pointer<ffi.Float>,
);
typedef _SetFeaturesSAMFunc = void Function(
  ffi.Pointer<SAMImage>,
  ffi.Pointer<ffi.Float>,
  int,
);
typedef _TransformCoordsSAMFunc = void Function(
  ffi.Pointer<SAMImage>,
  ffi.Pointer<ffi.Float>,
  ffi.Pointer<ffi.Float>,
);
typedef _PostprocessSAMFunc = void Function(
  ffi.Pointer<SAMImage>,
  ffi.Pointer<ffi.Float>,
  int,
  ffi.Pointer<ffi.Float>,
  int,
);
typedef _AddPointAndLabelSAMFunc = bool Function(
  ffi.Pointer<SAMImage>,
  ffi.Pointer<ffi.Int32>,
  ffi.Pointer<ffi.Int32>,
);
typedef _PopPointAndLabelSAMFunc = bool Function(ffi.Pointer<SAMImage>);
typedef _GetPointsAndLabelsSAMFunc = void Function(
  ffi.Pointer<SAMImage>,
  ffi.Pointer<ffi.Int32>,
  ffi.Pointer<ffi.Int32>,
);
typedef _GetMaskSAMFunc = bool Function(
  ffi.Pointer<SAMImage>,
  ffi.Pointer<Utf8>,
);
typedef _MakeStickerSAMFunc = void Function(
  ffi.Pointer<SAMImage>,
  ffi.Pointer<Utf8>,
);
typedef _GetTotalPointsSAMFunc = int Function(ffi.Pointer<SAMImage>);
typedef _CheckSetImageSAMFunc = bool Function(ffi.Pointer<SAMImage>);
// End SAMImage functions

class CutoutBinding {
  static final ffi.DynamicLibrary _lib = _openDynamicLibrary();

  // Getting a library that holds needed symbols
  static ffi.DynamicLibrary _openDynamicLibrary() {
    if (Platform.isAndroid) {
      return ffi.DynamicLibrary.open('libcutout.so');
    }

    return ffi.DynamicLibrary.process();
  }

  // Looking for the functions
  // Start U2Net functions
  final _CreateU2NetFunc _createU2Net = _lib.lookup<ffi.NativeFunction<_CCreateU2NetFunc>>('create_u2net').asFunction();
  final _DestroyU2NetFunc _destroyU2Net =
      _lib.lookup<ffi.NativeFunction<_CDestroyU2NetFunc>>('destroy_u2net').asFunction();
  final _ClearU2NetFunc _clearU2Net = _lib.lookup<ffi.NativeFunction<_CClearU2NetFunc>>('clear_u2net').asFunction();
  final _PreprocessU2NetFunc _preprocessU2Net =
      _lib.lookup<ffi.NativeFunction<_CPreprocessU2NetFunc>>('preprocess_u2net').asFunction();
  final _PostprocessU2NetFunc _postprocessU2Net =
      _lib.lookup<ffi.NativeFunction<_CPostprocessU2NetFunc>>('postprocess_u2net').asFunction();
  // End U2Net functions

  // Start SAMImage functions
  final _CreateSAMFunc _createSAM = _lib.lookup<ffi.NativeFunction<_CCreateSAMFunc>>('create_sam').asFunction();
  final _DestroySAMFunc _destroySAM = _lib.lookup<ffi.NativeFunction<_CDestroySAMFunc>>('destroy_sam').asFunction();
  final _ClearSAMFunc _clearSAM = _lib.lookup<ffi.NativeFunction<_CClearSAMFunc>>('clear_sam').asFunction();
  final _PreprocessSAMFunc _preprocessSAM =
      _lib.lookup<ffi.NativeFunction<_CPreprocessSAMFunc>>('preprocess_sam').asFunction();
  final _SetFeaturesSAMFunc _setFeaturesSAM =
      _lib.lookup<ffi.NativeFunction<_CSetFeaturesSAMFunc>>('set_features_sam').asFunction();
  final _TransformCoordsSAMFunc _transformCoordsSAM =
      _lib.lookup<ffi.NativeFunction<_CTransformCoordsSAMFunc>>('transform_coords_sam').asFunction();
  final _PostprocessSAMFunc _postprocessSAM =
      _lib.lookup<ffi.NativeFunction<_CPostprocessSAMFunc>>('postprocess_sam').asFunction();
  final _AddPointAndLabelSAMFunc _addPointAndLabelSAM =
      _lib.lookup<ffi.NativeFunction<_CAddPointAndLabelSAMFunc>>('add_point_and_label_sam').asFunction();
  final _PopPointAndLabelSAMFunc _popPointAndLabelSAM =
      _lib.lookup<ffi.NativeFunction<_CPopPointAndLabelSAMFunc>>('pop_point_and_label_sam').asFunction();
  final _GetPointsAndLabelsSAMFunc _getPointsAndLabelsSAM =
      _lib.lookup<ffi.NativeFunction<_CGetPointsAndLabelsSAMFunc>>('get_points_and_labels_sam').asFunction();
  final _GetMaskSAMFunc _getMaskSAM = _lib.lookup<ffi.NativeFunction<_CGetMaskSAMFunc>>('get_mask_sam').asFunction();
  final _MakeStickerSAMFunc _makeStickerSAM =
      _lib.lookup<ffi.NativeFunction<_CMakeStickerSAMFunc>>('make_sticker_sam').asFunction();
  final _GetTotalPointsSAMFunc _getTotalPointsSAM =
      _lib.lookup<ffi.NativeFunction<_CGetTotalPointsSAMFunc>>('get_total_points_sam').asFunction();
  final _CheckSetImageSAMFunc _checkSetImageSAM =
      _lib.lookup<ffi.NativeFunction<_CCheckSetImageSAMFunc>>('check_set_image_sam').asFunction();
  // End SAMImage functions

  // Wrapper functions
  // U2NetSegmentImage sections
  ffi.Pointer<U2NetSegmentImage> createU2Net() {
    return _createU2Net();
  }

  void destroyU2Net(ffi.Pointer<U2NetSegmentImage> u2net) {
    _destroyU2Net(u2net);
  }

  void clearU2Net(ffi.Pointer<U2NetSegmentImage> u2net) {
    _clearU2Net(u2net);
  }

  Future<Float32List> preprocessU2Net(ffi.Pointer<U2NetSegmentImage> u2net, String imagePath) async {
    late final ffi.Pointer<ffi.Float> floatPointer;
    final imagePathPointer = imagePath.toNativeUtf8();

    try {
      // imageSize is a constant value
      // It will return a float array of size (1 * 3 * 320 * 320) = 307200
      const outputImageSize = 320;
      const size = 1 * 3 * outputImageSize * outputImageSize;

      // allocate memory for the float array
      floatPointer = calloc<ffi.Float>(size);
      _preprocessU2Net(u2net, imagePathPointer, floatPointer);
      final floatArray = floatPointer.asTypedList(size);

      // copy the float array to a new Float32List
      final result = Float32List(floatArray.length);
      result.setAll(0, floatArray);

      return result;
    } finally {
      // free the memory allocated for the float array
      calloc.free(floatPointer);
      calloc.free(imagePathPointer);
    }
  }

  Future<bool> postprocessU2Net(ffi.Pointer<U2NetSegmentImage> u2net, Float32List bytesMask, String outputPath) async {
    late final ffi.Pointer<ffi.Float> bytesMaskPointer;
    final outputPathPointer = outputPath.toNativeUtf8();

    try {
      final bytesMaskSize = bytesMask.length;

      // convert mask to pointers
      bytesMaskPointer = calloc<ffi.Float>(bytesMaskSize);
      final maskBuffer = bytesMaskPointer.asTypedList(bytesMaskSize);
      maskBuffer.setAll(0, bytesMask);

      return await Future.value(_postprocessU2Net(
        u2net,
        bytesMaskPointer,
        bytesMaskSize,
        outputPathPointer,
      ));
    } finally {
      calloc.free(bytesMaskPointer);
      calloc.free(outputPathPointer);
    }
  }

  // SAMImage sections
  ffi.Pointer<SAMImage> createSAM() {
    return _createSAM();
  }

  void destroySAM(ffi.Pointer<SAMImage> sam) {
    _destroySAM(sam);
  }

  void clearSAM(ffi.Pointer<SAMImage> sam) {
    _clearSAM(sam);
  }

  int getTotalPointsSAM(ffi.Pointer<SAMImage> sam) {
    return _getTotalPointsSAM(sam);
  }

  Future<Float32List> preprocessSAM(ffi.Pointer<SAMImage> sam, String imagePath) async {
    late final ffi.Pointer<ffi.Float> floatPointer;
    final imagePathPointer = imagePath.toNativeUtf8();

    try {
      // imageSize is a constant value
      // It will return a float array of size (1 * 3 * 1024 * 1024) = 3145728
      const size = 1 * 3 * 1024 * 1024;

      // allocate memory for the float array
      floatPointer = calloc<ffi.Float>(size);
      _preprocessSAM(sam, imagePathPointer, floatPointer);
      final floatArray = floatPointer.asTypedList(size);

      // copy the float array to a new Float32List
      final result = Float32List(floatArray.length);
      result.setAll(0, floatArray);

      return result;
    } finally {
      calloc.free(floatPointer);
      calloc.free(imagePathPointer);
    }
  }

  Future<void> setFeaturesSAM(ffi.Pointer<SAMImage> sam, Float32List features) async {
    late final ffi.Pointer<ffi.Float> featuresPointer;

    try {
      final featuresSize = features.length;
      featuresPointer = calloc<ffi.Float>(featuresSize);
      final featuresBuffer = featuresPointer.asTypedList(featuresSize);
      featuresBuffer.setAll(0, features);

      _setFeaturesSAM(sam, featuresPointer, featuresSize);
    } finally {
      calloc.free(featuresPointer);
    }
  }

  Future<(Float32List, Float32List)> transformCoordsSAM(ffi.Pointer<SAMImage> sam) async {
    late final ffi.Pointer<ffi.Float> coordsPointer;
    late final ffi.Pointer<ffi.Float> labelsPointer;
    late final totalPoints = getTotalPointsSAM(sam);

    try {
      late final coordsSize = totalPoints * 2;
      late final labelsSize = totalPoints;

      // allocate memory for the float array
      coordsPointer = calloc<ffi.Float>(coordsSize);
      labelsPointer = calloc<ffi.Float>(labelsSize);
      _transformCoordsSAM(sam, coordsPointer, labelsPointer);

      final coordsArray = coordsPointer.asTypedList(coordsSize);
      final labelsArray = labelsPointer.asTypedList(labelsSize);

      final coordsResult = Float32List(coordsArray.length);
      final labelsResult = Float32List(labelsArray.length);
      coordsResult.setAll(0, coordsArray);
      labelsResult.setAll(0, labelsArray);

      return (coordsResult, labelsResult);
    } finally {
      calloc.free(coordsPointer);
      calloc.free(labelsPointer);
    }
  }

  Future<void> postprocessSAM(ffi.Pointer<SAMImage> sam, Float32List scores, Float32List lowResMasks) async {
    late final ffi.Pointer<ffi.Float> scoresPointer;
    late final ffi.Pointer<ffi.Float> lowResMasksPointer;

    try {
      final scoresSize = scores.length;
      final lowResMasksSize = lowResMasks.length;

      // convert scores and lowResMasks to pointers
      scoresPointer = calloc<ffi.Float>(scoresSize);
      final scoresBuffer = scoresPointer.asTypedList(scoresSize);
      scoresBuffer.setAll(0, scores);

      lowResMasksPointer = calloc<ffi.Float>(lowResMasksSize);
      final lowResMasksBuffer = lowResMasksPointer.asTypedList(lowResMasksSize);
      lowResMasksBuffer.setAll(0, lowResMasks);

      _postprocessSAM(sam, scoresPointer, scoresSize, lowResMasksPointer, lowResMasksSize);
    } finally {
      calloc.free(scoresPointer);
      calloc.free(lowResMasksPointer);
    }
  }

  Future<bool> addPointAndLabelSAM(ffi.Pointer<SAMImage> sam, Int32List coord, Int32List label) async {
    late final ffi.Pointer<ffi.Int32> coordPointer;
    late final ffi.Pointer<ffi.Int32> labelPointer;

    try {
      final coordSize = coord.length; // must be 2
      final labelSize = label.length; // must be 1

      coordPointer = calloc<ffi.Int32>(coordSize);
      final coordBuffer = coordPointer.asTypedList(coordSize);
      coordBuffer.setAll(0, coord);

      labelPointer = calloc<ffi.Int32>(labelSize);
      final labelBuffer = labelPointer.asTypedList(labelSize);
      labelBuffer.setAll(0, label);

      final isSuccess = _addPointAndLabelSAM(sam, coordPointer, labelPointer);

      return isSuccess;
    } finally {
      calloc.free(coordPointer);
      calloc.free(labelPointer);
    }
  }

  bool popPointAndLabelSAM(ffi.Pointer<SAMImage> sam) {
    return _popPointAndLabelSAM(sam);
  }

  Future<(Int32List, Int32List)> getPointsAndLabelsSAM(ffi.Pointer<SAMImage> sam) async {
    late final ffi.Pointer<ffi.Int32> coordsPointer;
    late final ffi.Pointer<ffi.Int32> labelsPointer;

    try {
      final totalPoints = getTotalPointsSAM(sam);
      final coordsSize = totalPoints * 2;
      final labelsSize = totalPoints;

      coordsPointer = calloc<ffi.Int32>(coordsSize);
      labelsPointer = calloc<ffi.Int32>(labelsSize);
      _getPointsAndLabelsSAM(sam, coordsPointer, labelsPointer);

      final coordsArray = coordsPointer.asTypedList(coordsSize);
      final labelsArray = labelsPointer.asTypedList(labelsSize);

      final coordsResult = Int32List(coordsArray.length);
      final labelsResult = Int32List(labelsArray.length);
      coordsResult.setAll(0, coordsArray);
      labelsResult.setAll(0, labelsArray);

      return (coordsResult, labelsResult);
    } finally {
      calloc.free(coordsPointer);
      calloc.free(labelsPointer);
    }
  }

  Future<void> getMaskSAM(ffi.Pointer<SAMImage> sam, String outputPath) async {
    final outputPathPointer = outputPath.toNativeUtf8();

    try {
      _getMaskSAM(sam, outputPathPointer);
    } finally {
      calloc.free(outputPathPointer);
    }
  }

  Future<void> makeStickerSAM(ffi.Pointer<SAMImage> sam, String outputPath) async {
    final outputPathPointer = outputPath.toNativeUtf8();

    try {
      _makeStickerSAM(sam, outputPathPointer);
    } finally {
      calloc.free(outputPathPointer);
    }
  }

  bool checkSetImageSAM(ffi.Pointer<SAMImage> sam) {
    return _checkSetImageSAM(sam);
  }
}
