#pragma once

#include <array>
#include <memory>
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

class ResizeLongestSide {
public:
  ResizeLongestSide(int target_length);
  ~ResizeLongestSide() = default;
  ResizeLongestSide(const ResizeLongestSide &) = delete;

  cv::Mat apply_image(const cv::Mat &image);
  cv::Mat apply_coords(const cv::Mat &coords,
                       const std::array<int, 2> &original_size);

private:
  int target_length;

  std::array<int, 2> get_preprocess_shape(int oldh, int oldw,
                                          int long_side_length);
};

class SAMImage {
public:
  SAMImage() { this->reset(); };
  ~SAMImage() = default;
  SAMImage(const SAMImage &) = delete;
  SAMImage &operator=(const SAMImage &) = delete;
  SAMImage(SAMImage &&) = default;
  SAMImage &operator=(SAMImage &&) = delete;

  std::vector<float> preprocess(const std::string &image_path);
  std::vector<float> encode(const std::vector<float> &data);
  void set_features(const cv::Mat &features);
  std::pair<std::vector<float>, std::vector<float>> transform_coords();
  std::pair<std::vector<float>, std::vector<float>>
  decode(const int num_points, const std::vector<float> &features,
         const std::vector<float> &point_coords,
         const std::vector<float> &point_labels);
  void postprocess(const std::vector<float> &scores,
                   const std::vector<float> &low_res_masks);
  bool add_point_and_label(const std::array<int, 2> &point, const int &label);
  bool pop_point_and_label();
  std::pair<std::vector<std::array<int, 2>>, std::vector<int>>
  get_points_and_labels();
  bool get_mask(const std::string &mask_path);
  void make_sticker(const std::string &output_path);
  int get_total_points();
  bool check_set_image();
  void clear();

private:
  // Helper methods
  void threshold_1d_simple(cv::Mat &masks, float thresh);
  cv::Rect get_bbox(const cv::Mat &mask);
  void reset();

  // Static parameters
  const float mask_threshold{0.0};
  const int img_size{1024};
  const std::array<float, 3> pixel_mean{123.675, 116.28, 103.53};
  const std::array<float, 3> pixel_std{58.395, 57.12, 57.375};

  // State variables
  ResizeLongestSide transform{img_size};
  bool is_image_set{false};
  cv::Mat image;
  cv::Mat features;
  cv::Mat mask;
  int total_points{0};
  std::vector<std::array<int, 2>> point_coords;
  std::vector<int> point_labels;
  std::array<int, 2> original_size;
  std::array<int, 2> input_size;
};

ResizeLongestSide::ResizeLongestSide(int target_length)
    : target_length(target_length) {}

cv::Mat ResizeLongestSide::apply_image(const cv::Mat &image) {
  auto target_size =
      get_preprocess_shape(image.rows, image.cols, target_length);
  cv::Mat resized;
  cv::resize(image, resized, cv::Size(target_size[1], target_size[0]), 0, 0,
             cv::INTER_LINEAR);

  return resized;
}

cv::Mat
ResizeLongestSide::apply_coords(const cv::Mat &coords,
                                const std::array<int, 2> &original_size) {
  float old_h = original_size[0];
  float old_w = original_size[1];

  auto target_size =
      get_preprocess_shape(original_size[0], original_size[1], target_length);
  float new_h = target_size[0];
  float new_w = target_size[1];

  cv::Mat coords_float = coords.clone();
  int batch = coords_float.size[0];
  int num_points = coords_float.size[1];

  coords_float = coords_float.reshape(1, {batch * num_points, 2});
  coords_float.convertTo(coords_float, CV_32F);

  // Apply scaling directly to each coordinate
  for (int i = 0; i < coords_float.rows; i++) {
    coords_float.at<float>(i, 0) *= (new_w / old_w);
    coords_float.at<float>(i, 1) *= (new_h / old_h);
  }

  coords_float = coords_float.reshape(1, {batch, num_points, 2});

  return coords_float;
}

std::array<int, 2>
ResizeLongestSide::get_preprocess_shape(int oldh, int oldw,
                                        int long_side_length) {
  float scale = long_side_length * 1.0 / std::max(oldh, oldw);
  float newh = oldh * scale;
  float neww = oldw * scale;

  int newh_int = static_cast<int>(newh + 0.5);
  int neww_int = static_cast<int>(neww + 0.5);

  return std::array<int, 2>{newh_int, neww_int};
}

std::vector<float> SAMImage::preprocess(const std::string &image_path) {
  cv::Mat image = cv::imread(image_path);
  this->reset();
  this->image = image.clone();

  cv::Mat input_image = transform.apply_image(image);
  // Start: Transform to format [1, C, H, W]
  // First transpose from [H, W, C] to [C, H, W]
  std::vector<cv::Mat> channels;
  cv::split(input_image, channels);

  // Create a new matrix to store the transposed channels
  int height = input_image.rows;
  int width = input_image.cols;
  int channels_count = input_image.channels();

  cv::Mat temp(channels_count, height * width, CV_32F);
  for (int i = 0; i < channels_count; i++) {
    channels[i].reshape(1, 1).copyTo(temp.row(i));
  }

  // Reshape to [C, H, W]
  cv::Mat transposed_image;
  transposed_image = temp.reshape(1, {channels_count, height, width});

  // Add extra dimension to make it [1, C, H, W]
  std::vector<int> new_shape = {1, channels_count, height, width};
  input_image = transposed_image.reshape(1, new_shape);
  // End: Transform to format [1, C, H, W]

  this->original_size = std::array<int, 2>{image.rows, image.cols};
  this->input_size =
      std::array<int, 2>{input_image.size[2], input_image.size[3]};

  cv::Mat pixel_mean = cv::Mat(this->pixel_mean);
  pixel_mean = pixel_mean.reshape(1, {1, 3, 1, 1});
  cv::Mat pixel_std = cv::Mat(this->pixel_std);
  pixel_std = pixel_std.reshape(1, {1, 3, 1, 1});

  // Process each channel separately for normalization
  std::vector<cv::Mat> norm_channels(3); // Variable name changed
  for (int c = 0; c < 3; c++) {
    // Extract slice for each channel
    cv::Mat channel(input_image.size[2], input_image.size[3], CV_32F);
    float *input_ptr = (float *)input_image.data +
                       c * input_image.size[2] * input_image.size[3];
    std::memcpy(channel.data, input_ptr,
                input_image.size[2] * input_image.size[3] * sizeof(float));

    // Apply normalization
    float mean_val = ((float *)pixel_mean.data)[c];
    float std_val = ((float *)pixel_std.data)[c];
    channel = (channel - mean_val) / std_val;

    // Copy normalized data back to original location
    std::memcpy(input_ptr, channel.data,
                input_image.size[2] * input_image.size[3] * sizeof(float));
  }

  int h = input_image.size[2];
  int w = input_image.size[3];
  int padh = this->img_size - h;
  int padw = this->img_size - w;

  // Padding should be applied using copyMakeBorder
  // Create a 4D tensor to store the result
  std::vector<int> padded_shape = {1, 3, h + padh, w + padw};
  cv::Mat padded_image(padded_shape.size(), padded_shape.data(), CV_32F,
                       cv::Scalar(0));

  // Process each channel separately for padding
  for (int c = 0; c < 3; c++) {
    // Extract current channel
    cv::Mat channel(h, w, CV_32F);
    float *input_ptr = (float *)input_image.data + c * h * w;
    std::memcpy(channel.data, input_ptr, h * w * sizeof(float));

    // Apply padding
    cv::Mat padded_channel;
    cv::copyMakeBorder(channel, padded_channel, 0, padh, // top, bottom
                       0, padw,                          // left, right
                       cv::BORDER_CONSTANT, cv::Scalar(0));

    // Copy result to 4D tensor
    float *output_ptr =
        (float *)padded_image.data + c * (h + padh) * (w + padw);
    std::memcpy(output_ptr, padded_channel.data,
                (h + padh) * (w + padw) * sizeof(float));
  }

  return std::vector<float>(padded_image.begin<float>(),
                            padded_image.end<float>());
}

void SAMImage::set_features(const cv::Mat &features) {
  this->features = features;
  this->is_image_set = true;
}

std::pair<std::vector<float>, std::vector<float>> SAMImage::transform_coords() {
  std::vector<int> point_coords_vector;
  for (const auto &coord : this->point_coords) {
    point_coords_vector.push_back(coord[0]);
    point_coords_vector.push_back(coord[1]);
  }

  // Create a (n, 1) dimension cv::Mat
  std::vector<int> point_coords_vector_shape = {this->total_points, 2};
  cv::Mat point_coords = cv::Mat(point_coords_vector_shape, CV_32F);
  for (int i = 0; i < this->total_points; i++) {
    point_coords.at<float>(i, 0) = point_coords_vector[i * 2];
    point_coords.at<float>(i, 1) = point_coords_vector[i * 2 + 1];
  }

  point_coords = point_coords.reshape(1, {1, this->total_points, 2});

  std::vector<int> point_labels_vector_shape = {this->total_points};
  cv::Mat point_labels = cv::Mat(point_labels_vector_shape, CV_32F);
  for (int i = 0; i < this->total_points; i++) {
    point_labels.at<float>(i, 0) = this->point_labels[i];
  }

  point_labels = point_labels.reshape(1, {1, this->total_points});

  point_coords =
      this->transform.apply_coords(point_coords, this->original_size);

  int batch = point_coords.size[0];
  int num_points = this->total_points;

  std::vector<float> point_coords_float_vector;
  point_coords = point_coords.reshape(1, {batch * num_points * 2, 1});
  point_coords_float_vector = std::vector<float>(point_coords.begin<float>(),
                                                 point_coords.end<float>());

  std::vector<float> point_labels_float_vector;
  point_labels = point_labels.reshape(1, {batch * num_points, 1});
  point_labels_float_vector = std::vector<float>(point_labels.begin<float>(),
                                                 point_labels.end<float>());

  return std::make_pair(point_coords_float_vector, point_labels_float_vector);
}

void SAMImage::threshold_1d_simple(cv::Mat &masks, float thresh) {
  int h = masks.size[0]; // 1080
  int w = masks.size[1]; // 810

  float *data = (float *)masks.data;
  int total = h * w;

  // #pragma omp parallel for
  for (int i = 0; i < total; ++i) {
    data[i] = (data[i] > thresh) ? 1.0f : 0.0f;
  }
  masks.convertTo(masks, CV_8UC1);
}

void SAMImage::postprocess(const std::vector<float> &scores,
                           const std::vector<float> &low_res_masks) {
  // Shape of low_res_masks: [4, 256, 256]
  cv::Mat mask = cv::Mat(low_res_masks, CV_32F);
  mask = mask.reshape(1, {4, 256 * 256});

  // Resize mask to original image size
  std::vector<cv::Mat> resized_masks;

  for (int i = 0; i < 4; i++) {
    // Extract i-th row and reshape to [256, 256]
    cv::Mat single_mask = mask.row(i).reshape(1, 256);

    // First resize
    cv::Mat resized_single_mask;
    cv::resize(single_mask, resized_single_mask,
               cv::Size(this->img_size, this->img_size), 0, 0,
               cv::INTER_LINEAR);

    // Second crop padding
    cv::Rect roi(0, 0, this->input_size[1], this->input_size[0]);
    resized_single_mask = resized_single_mask(roi);

    // Second resize - convert to original image size
    cv::resize(resized_single_mask, resized_single_mask,
               cv::Size(this->original_size[1], this->original_size[0]), 0, 0,
               cv::INTER_LINEAR);

    // Store result in vector
    resized_masks.push_back(resized_single_mask);
  }

  // Threshold masks
  for (int i = 0; i < 4; i++) {
    threshold_1d_simple(resized_masks[i], this->mask_threshold);
  }

  int max_index =
      std::max_element(scores.begin(), scores.end()) - scores.begin();

  cv::Mat pred = resized_masks[max_index];
  pred = pred * 255;
  pred.convertTo(pred, CV_8UC1);

  // kernel
  cv::Mat kernel = cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(3, 3));
  cv::Mat erode_kernel =
      cv::getStructuringElement(cv::MORPH_ERODE, cv::Size(5, 5));
  cv::Mat dilate_kernel =
      cv::getStructuringElement(cv::MORPH_DILATE, cv::Size(5, 5));
  cv::morphologyEx(pred, pred, cv::MORPH_OPEN, kernel);
  cv::GaussianBlur(pred, pred, cv::Size(5, 5), 2, 2, cv::BORDER_DEFAULT);
  cv::dilate(pred, pred, dilate_kernel, cv::Point(-1, -1), 3);
  cv::erode(pred, pred, erode_kernel, cv::Point(-1, -1), 3);
  cv::threshold(pred, pred, 75, 255, cv::THRESH_BINARY);
  pred.convertTo(pred, CV_8UC1);

  this->mask = pred;
}

bool SAMImage::add_point_and_label(const std::array<int, 2> &point,
                                   const int &label) {
  this->point_coords.push_back(point);
  this->point_labels.push_back(label);

  if (this->point_coords.size() == this->point_labels.size()) {
    this->total_points = this->point_coords.size();
    return true;
  }

  return false;
}

bool SAMImage::pop_point_and_label() {
  if (this->point_coords.empty() || this->point_labels.empty()) {
    return false;
  }

  this->point_coords.pop_back();
  this->point_labels.pop_back();

  if (this->point_coords.size() == this->point_labels.size()) {
    this->total_points = this->point_coords.size();
    return true;
  }

  return false;
}

std::pair<std::vector<std::array<int, 2>>, std::vector<int>>
SAMImage::get_points_and_labels() {
  return std::make_pair(this->point_coords, this->point_labels);
}

bool SAMImage::get_mask(const std::string &mask_path) {
  if (this->mask.empty()) {
    return false;
  }

  cv::imwrite(mask_path, this->mask);
  return true;
}

void SAMImage::make_sticker(const std::string &output_path) {
  cv::Mat mask = this->mask.clone();

  cv::Mat cutout;
  cv::bitwise_and(this->image, this->image, cutout, mask);

  // Split BGR channels
  std::vector<cv::Mat> channels;
  cv::split(cutout, channels);

  // Add alpha channel (mask)
  channels.push_back(mask);

  // Merge all channels to create BGRA image
  cv::Mat rgba_image;
  cv::merge(channels, rgba_image);

  // Get bounding box and crop
  cv::Rect bbox = get_bbox(mask);
  cv::Mat cropped = rgba_image(bbox);

  // Save image
  cv::imwrite(output_path, cropped);
}

int SAMImage::get_total_points() { return this->total_points; }

bool SAMImage::check_set_image() { return this->is_image_set; }

void SAMImage::clear() { this->reset(); }

void SAMImage::reset() {
  this->is_image_set = false;
  this->image.release();
  this->features.release();
  this->mask.release();
  this->total_points = 0;
  this->point_coords.clear();
  this->point_labels.clear();
  this->original_size = std::array<int, 2>{0, 0};
  this->input_size = std::array<int, 2>{0, 0};
}

cv::Rect SAMImage::get_bbox(const cv::Mat &mask) {
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

// Avoiding name mangling
extern "C" {
FUNCTION_ATTRIBUTE
SAMImage *create_sam() { return new SAMImage(); }

FUNCTION_ATTRIBUTE
void destroy_sam(SAMImage *sam) { delete sam; }

FUNCTION_ATTRIBUTE
void preprocess_sam(SAMImage *sam, const char *image_path, float *output_data) {
  auto preprocessed = sam->preprocess(image_path);
  std::copy(preprocessed.begin(), preprocessed.end(), output_data);
}

FUNCTION_ATTRIBUTE
void set_features_sam(SAMImage *sam, const float *features, int features_size) {
  std::vector<float> features_vector(features, features + features_size);
  cv::Mat features_mat(features_vector, CV_32F);
  features_mat = features_mat.reshape(1, {1, 256, 64, 64});
  sam->set_features(features_mat);
}

FUNCTION_ATTRIBUTE
void transform_coords_sam(SAMImage *sam, float *point_coords,
                          float *point_labels) {
  auto transformed = sam->transform_coords();
  auto coords = transformed.first;
  auto labels = transformed.second;

  std::copy(coords.begin(), coords.end(), point_coords);
  std::copy(labels.begin(), labels.end(), point_labels);
}

FUNCTION_ATTRIBUTE
void postprocess_sam(SAMImage *sam, const float *scores, int scores_size,
                     const float *low_res_masks, int low_res_masks_size) {
  std::vector<float> scores_vector(scores, scores + scores_size);
  std::vector<float> low_res_masks_vector(low_res_masks,
                                          low_res_masks + low_res_masks_size);
  sam->postprocess(scores_vector, low_res_masks_vector);
}

FUNCTION_ATTRIBUTE
bool add_point_and_label_sam(SAMImage *sam, const int *point,
                             const int *label) {
  std::array<int, 2> point_array{point[0], point[1]};
  int label_int = label[0];
  return sam->add_point_and_label(point_array, label_int);
}

FUNCTION_ATTRIBUTE
bool pop_point_and_label_sam(SAMImage *sam) {
  return sam->pop_point_and_label();
}

FUNCTION_ATTRIBUTE
void get_points_and_labels_sam(SAMImage *sam, int *output_point_coords,
                               int *output_point_labels) {
  if (!sam)
    return;

  auto points_and_labels = sam->get_points_and_labels();
  auto &point_coords = points_and_labels.first;
  auto &point_labels = points_and_labels.second;

  // Safe memory copy
  for (size_t i = 0; i < point_coords.size(); ++i) {
    output_point_coords[i * 2] = point_coords[i][0];
    output_point_coords[i * 2 + 1] = point_coords[i][1];
  }
  std::copy(point_labels.begin(), point_labels.end(), output_point_labels);
}

FUNCTION_ATTRIBUTE
bool get_mask_sam(SAMImage *sam, const char *mask_path) {
  return sam->get_mask(mask_path);
}

FUNCTION_ATTRIBUTE
void make_sticker_sam(SAMImage *sam, const char *output_path) {
  sam->make_sticker(output_path);
}

FUNCTION_ATTRIBUTE
int get_total_points_sam(SAMImage *sam) { return sam->get_total_points(); }

FUNCTION_ATTRIBUTE
bool check_set_image_sam(SAMImage *sam) { return sam->check_set_image(); }

FUNCTION_ATTRIBUTE
void clear_sam(SAMImage *sam) { sam->clear(); }
}
