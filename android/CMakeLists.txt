cmake_minimum_required(VERSION 3.4.1)
project(cutout)

include_directories(../include)
add_library(lib_opencv SHARED IMPORTED)
set_target_properties(lib_opencv PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}/libopencv_java4.so)

find_library(log-lib log)

add_library(
    cutout SHARED
    ../ios/Classes/u2net.cpp
    ../ios/Classes/sam.cpp
)
target_link_libraries(cutout lib_opencv ${log-lib})
