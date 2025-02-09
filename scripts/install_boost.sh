boost_cmake_url="https://github.com/boostorg/boost/releases/download/boost-1.87.0/boost-1.87.0-cmake.tar.gz"
archive_name="boost-1.87.0-cmake.tar.gz"
extracted_dir_name="boost-1.87.0"
build_type="Release"
config_type="Release"

# CMAKE_GENERATOR_PLATFORM

if [ "$1" == "--headers-only" ]; then
    echo "Installing Boost headers only"
    boost_libraries="math;foreach;graph"
else
    echo "Installing Boost + Boost.Python"
    boost_libraries="math;foreach;graph;python"
    include_python="1"
fi

ensure_installed() {
    if ! [ -x "$(command -v $1)" ]; then
        echo "Error: $1 is not installed." >&2
        exit 1
    fi
}

get_os() {
    if [ "${OCL_PLATFORM}" ]; then
        echo "${OCL_PLATFORM}"
    else
        if [[ "${OSTYPE}" =~ ^darwin.* ]]; then
            echo "macos"
        elif [[ "${OSTYPE}" =~ ^linux.* ]]; then
            echo "linux"
        else
            echo "windows"
        fi
    fi
}

num_procs() {
    determined_os=$(get_os)
    if [ "${determined_os}" = "macos" ]; then
        sysctl -n hw.logicalcpu
    elif [ "${determined_os}" = "linux" ]; then
        nproc
    else
        echo "${NUMBER_OF_PROCESSORS:-"2"}"
    fi
}

ensure_installed curl
ensure_installed cmake
ensure_installed tar

num_procs=$(num_procs)
determined_os=$(get_os)

echo "Determined OS: $determined_os"
echo "Determined num procs: $num_procs"

if [ "${determined_os}" == "windows" ]; then
    export CMAKE_INSTALL_PREFIX="/c/Program Files (x86)/Boost"
fi

echo "Downloading Boost"
curl -L -O $boost_cmake_url

echo "Extracting Boost"
tar -xzf $archive_name

echo "Compiling Boost"
cd $extracted_dir_name

python_exe="$(python -c 'import sys; print(sys.executable)')"

echo "Found python at: ${python_exe}"

cmake \
    -D CMAKE_BUILD_TYPE="${build_type}" \
    -D CMAKE_CONFIGURATION_TYPES="${config_type}" \
    -D Python_EXECUTABLE="${python_exe}" \
    -D Python_FIND_STRATEGY="LOCATION" \
    -D Python_FIND_REGISTRY="NEVER" \
    -D Python_FIND_FRAMEWORK="NEVER" \
    -D Python_FIND_VIRTUALENV="FIRST" \
    -D CMAKE_POLICY_DEFAULT_CMP0094=NEW \
    ${include_python:+"-D BOOST_ENABLE_PYTHON=ON"} \
    -D BOOST_INCLUDE_LIBRARIES="${boost_libraries}" \
    -S . \
    -B build

cmake \
    --build build \
    --config ${config_type} \
    --parallel $(num_procs)

if [ "${determined_os}" == "windows" ]; then
    cmake \
        --install build \
        --config ${config_type}
else
    cmake \
        --install build \
        --config ${config_type}
fi
echo "Boost installed successfully"