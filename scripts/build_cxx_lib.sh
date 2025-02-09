#!/usr/bin/env bash

set -xe

build_type="Release"
config_type="Release"

cmake \
    -D BUILD_CXX_LIB=ON \
    -D CMAKE_BUILD_TYPE="${build_type}" \
    -D CMAKE_CONFIGURATION_TYPES="${config_type}" \
    -S . -B build
cmake --build build --config "${config_type}" --parallel 4
cmake --install build --config "${config_type}" --prefix "$1" --verbose
