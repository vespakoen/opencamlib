#!/usr/bin/env bash

set -xe

cmake -D BUILD_CXX_LIB=ON -S . -B build
cmake --build build --parallel 4
cmake --install build --prefix $1 --verbose
