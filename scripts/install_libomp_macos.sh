#!/usr/bin/env bash

set -ex

armloc=$(brew fetch --bottle-tag=arm64_sonoma libomp | grep -i downloaded | grep tar.gz | cut -f2 -d: | xargs echo)
x64loc=$(brew fetch --bottle-tag=sonoma libomp | grep -i downloaded | grep tar.gz | cut -f2 -d: | xargs echo)
cp "${armloc}" "/tmp/libomp-arm64.tar.gz"
mkdir /tmp/libomp-arm64 || true
tar -xzvf /tmp/libomp-arm64.tar.gz -C /tmp/libomp-arm64
cp "$x64loc" /tmp/libomp-x86_64.tar.gz
mkdir /tmp/libomp-x86_64 || true
tar -xzvf /tmp/libomp-x86_64.tar.gz -C /tmp/libomp-x86_64

libomp_x86_64_dir=$(find /tmp/libomp-x86_64/libomp -depth 1)
libomp_arm64_dir=$(find /tmp/libomp-arm64/libomp -depth 1)

mkdir -p /tmp/libomp-cross/lib
cp -r "${libomp_x86_64_dir}/include" /tmp/libomp-cross

lipo -create "${libomp_x86_64_dir}/lib/libomp.dylib" "${libomp_arm64_dir}/lib/libomp.dylib" -output /tmp/libomp-cross/lib/libomp.dylib

