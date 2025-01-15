# CutOut

## Overview

Flutter package for CutOut image segmentation implementation that enables the utilization of C++ code for image processing. This package provides a bridge between Flutter and native C++ image segmentation models, offering efficient and high-performance image segmentation capabilities in Flutter applications. The integration of C++ code allows developers to leverage existing computer vision algorithms while maintaining the cross-platform benefits of Flutter. Currently, supports iOS and Android.

## Key Features

- Supports latest OpenCV 4.10.0
- Supports ONNXRuntime 1.15.1 (depends on [onnxruntime_flutter](https://github.com/gtbluesky/onnxruntime_flutter) 1.4.1)
- Enables conversion and utilization of Python code from research or POC projects to C++
- Supports major segmentation models including U2Net and Segment Anything(SAM)

## Getting Started

```yaml
dependencies:
  cutout: x.y.z
```

### Build for iOS and Android packages

- iOS

    ```bash
    cd ${YOUR_APPLICATION}/ios && pod install
    ```

- Android

    ```bash
    cd ${YOUR_APPLICATION}/android && ./gradlew clean
    ```

### Download models

You can use [example models](./example/assets/models/) or download them [models assets](https://github.com/grandeclip/cutout_flutter/releases/tag/v0.0.0). The models in both locations are identical.

### Update OpenCV version

Check out [`set_opencv.sh`](./script/set_opencv.sh) file. (ref. [flutter_native_opencv](https://github.com/westracer/flutter_native_opencv))

## Usage Example

Check out [example](./example/) directory.

## Licenses

This package is licensed under the Apache License, Version 2.0. This package includes the following third-party models:

- [U-2-Net](https://github.com/xuebinqin/U-2-Net) - [Apache-2.0](https://github.com/xuebinqin/U-2-Net?tab=Apache-2.0-1-ov-file)
- [Segment Anything](https://github.com/facebookresearch/segment-anything) - [Apache-2.0](https://github.com/facebookresearch/segment-anything?tab=Apache-2.0-1-ov-file)
