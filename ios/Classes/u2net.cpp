#pragma once

#include <array>
#include <opencv2/opencv.hpp>
#include <stdbool.h>
#include <string>
#include <vector>

#if defined(__GNUC__)
// Attributes to prevent 'unused' function from being removed and to make it
// visible
#define FUNCTION_ATTRIBUTE                                                     \
  __attribute__((visibility("default"))) __attribute__((used))
#elif defined(_MSC_VER)
// Marking a function for export
#define FUNCTION_ATTRIBUTE __declspec(dllexport)
#endif

class U2NetSegmentImage {
public:
  U2NetSegmentImage() {};
  ~U2NetSegmentImage() = default;
  U2NetSegmentImage(const U2NetSegmentImage &) = delete;
  U2NetSegmentImage &operator=(const U2NetSegmentImage &) = delete;
  U2NetSegmentImage(U2NetSegmentImage &&) = default;
  U2NetSegmentImage &operator=(U2NetSegmentImage &&) = delete;

  std::vector<float> preprocess(const std::string &image_path);
  bool postprocess(const std::vector<float> &mask_vector,
                   const std::string &output_path);
  void clear();

private:
  cv::Rect get_bbox(const cv::Mat &mask);

  // 5% of the image area: 320 * 320 * 0.05 = 5120
  const int area_threshold = 5120;

  cv::Mat image;
};

std::vector<float>
U2NetSegmentImage::preprocess(const std::string &image_path) {
  // mean, std, and image size are constant values
  std::array<float, 3> mean = {0.485f, 0.456f, 0.406f};
  std::array<float, 3> std = {0.229f, 0.224f, 0.225f};
  std::array<int, 2> size = {320, 320};

  cv::Mat image = cv::imread(image_path);
  this->image = image.clone();

  cv::Mat resized, float_img;
  cv::resize(image, resized, cv::Size(size[0], size[1]), 0, 0,
             cv::INTER_LANCZOS4);

  double max_val;
  cv::minMaxLoc(resized, nullptr, &max_val);
  resized.convertTo(float_img, CV_32F, 1.0 / max_val);

  std::vector<cv::Mat> channels(3);
  cv::split(float_img, channels);

  for (int i = 0; i < 3; ++i) {
    channels[i] = (channels[i] - mean[i]) / std[i];
  }

  cv::Mat normalized;
  cv::merge(channels, normalized);

  // 채널 순서 변경 (H, W, C) -> (C, H, W)
  cv::Mat transposed;
  std::vector<cv::Mat> transposed_channels;
  cv::split(normalized, transposed_channels);
  cv::vconcat(transposed_channels, transposed);

  // 배치 차원 추가 (C, H, W) -> (1, C, H, W)
  cv::Mat reshaped = transposed.reshape(1, {1, 3, size[0], size[1]});

  return std::vector<float>(reshaped.begin<float>(), reshaped.end<float>());
}

bool U2NetSegmentImage::postprocess(const std::vector<float> &mask_vector,
                                    const std::string &output_path) {
  cv::Mat mask_mat(320, 320, CV_32F, const_cast<float *>(mask_vector.data()));
  cv::Mat normalized_mask;
  cv::normalize(mask_mat, normalized_mask, 0, 255, cv::NORM_MINMAX, CV_8U);

  // count non-zero elements
  int non_zero_count = cv::countNonZero(normalized_mask);
  if (non_zero_count < area_threshold) {
    return false;
  }

  // Resize mask
  cv::Mat resized_mask;
  cv::resize(normalized_mask, resized_mask, image.size(), 0, 0,
             cv::INTER_LANCZOS4);

  // Make smooth mask
  cv::Mat kernel = cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(3, 3));
  cv::Mat processed_mask;
  cv::morphologyEx(resized_mask, processed_mask, cv::MORPH_OPEN, kernel);
  cv::GaussianBlur(processed_mask, processed_mask, cv::Size(5, 5), 2, 2);
  cv::threshold(processed_mask, processed_mask, 75, 255, cv::THRESH_BINARY);

  // Cutout
  cv::Mat cutout;
  cv::bitwise_and(image, image, cutout, processed_mask);

  cv::Mat result;
  cv::cvtColor(cutout, result, cv::COLOR_BGR2BGRA);
  result.setTo(cv::Scalar(0, 0, 0, 0), processed_mask == 0);

  // Crop
  cv::Rect bbox = get_bbox(processed_mask);
  cv::Mat cropped = result(bbox);

  cv::imwrite(output_path, cropped);

  return true;
}

cv::Rect U2NetSegmentImage::get_bbox(const cv::Mat &mask) {
  std::vector<cv::Point> points;
  cv::findNonZero(mask, points);

  if (points.empty()) {
    return cv::Rect();
  }

  int x_min = std::numeric_limits<int>::max();
  int y_min = std::numeric_limits<int>::max();
  int x_max = std::numeric_limits<int>::min();
  int y_max = std::numeric_limits<int>::min();

  for (const auto &point : points) {
    x_min = std::min(x_min, point.x);
    y_min = std::min(y_min, point.y);
    x_max = std::max(x_max, point.x);
    y_max = std::max(y_max, point.y);
  }

  return cv::Rect(x_min, y_min, x_max - x_min + 1, y_max - y_min + 1);
}

void U2NetSegmentImage::clear() { image.release(); }

// Avoiding name mangling
extern "C" {
FUNCTION_ATTRIBUTE
U2NetSegmentImage *create_u2net() { return new U2NetSegmentImage(); }

FUNCTION_ATTRIBUTE
void destroy_u2net(U2NetSegmentImage *u2net) { delete u2net; }

FUNCTION_ATTRIBUTE
void preprocess_u2net(U2NetSegmentImage *u2net, const char *input_path,
                      float *output_data) {
  auto preprocessed = u2net->preprocess(input_path);
  std::copy(preprocessed.begin(), preprocessed.end(), output_data);
}

FUNCTION_ATTRIBUTE
bool postprocess_u2net(U2NetSegmentImage *u2net, float *mask_buffer,
                       int mask_size, const char *output_path) {
  std::vector<float> mask_vector(mask_buffer, mask_buffer + mask_size);
  return u2net->postprocess(mask_vector, output_path);
}

FUNCTION_ATTRIBUTE
void clear_u2net(U2NetSegmentImage *u2net) { u2net->clear(); }
}
