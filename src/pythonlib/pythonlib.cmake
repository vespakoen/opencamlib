# saner defaults
if(NOT DEFINED Python_FIND_STRATEGY)
  set(Python_FIND_STRATEGY LOCATION)
endif()
if(NOT DEFINED Python_FIND_REGISTRY)
  set(Python_FIND_REGISTRY NEVER)
endif()
if(NOT DEFINED Python_FIND_FRAMEWORK)
  set(Python_FIND_FRAMEWORK NEVER)
endif()
if(NOT DEFINED Python_FIND_VIRTUALENV)
  set(Python_FIND_VIRTUALENV FIRST)
endif()

if (CMAKE_VERSION VERSION_LESS 3.18)
  set(DEV_MODULE Development)
else()
  set(DEV_MODULE Development.Module)
endif()

find_package(Python COMPONENTS Interpreter ${DEV_MODULE} REQUIRED)
if(Python_FOUND)
  message(STATUS "Found Python: " ${Python_VERSION})
  message(STATUS "Python libraries: " ${Python_LIBRARIES})
  message(STATUS "Python executable: " ${Python_EXECUTABLE})
  message(STATUS "Python (arch-dependant) module destination: " ${Python_SITEARCH})
endif()
# find_package(Boost CONFIG COMPONENTS python REQUIRED)

# include dirs
include_directories(${PROJECT_SOURCE_DIR}/cutters)
include_directories(${PROJECT_SOURCE_DIR}/geo)
include_directories(${PROJECT_SOURCE_DIR}/algo)
include_directories(${PROJECT_SOURCE_DIR}/dropcutter)
include_directories(${PROJECT_SOURCE_DIR}/common)
include_directories(${PROJECT_SOURCE_DIR})

# this makes the ocl Python module
Python_add_library(
  ocl
MODULE
  pythonlib/ocl_cutters.cpp
  pythonlib/ocl_geometry.cpp
  pythonlib/ocl_algo.cpp
  pythonlib/ocl_dropcutter.cpp
  pythonlib/ocl.cpp
)

target_link_libraries(
  ocl
PRIVATE
  ocl_common
  ocl_dropcutter
  ocl_cutters
  ocl_geo
  ocl_algo
  Boost::math
  Boost::graph
  Boost::foreach
  Boost::python${Python_VERSION_MAJOR}${Python_VERSION_MINOR}
)

if(USE_OPENMP)
  target_link_libraries(ocl PRIVATE OpenMP::OpenMP_CXX)
endif()

file(TO_CMAKE_PATH "${Python_SITEARCH}/opencamlib" INSTALL_PATH)
install(TARGETS ocl LIBRARY DESTINATION "${INSTALL_PATH}")
if(NOT SKBUILD)
  install(
    DIRECTORY pythonlib/opencamlib/
    DESTINATION "${INSTALL_PATH}"
  )
endif()

if(USE_OPENMP AND APPLE)
  # add homebrew libomp paths to the INSTALL_RPATH, and the @loader_path last as a fallback.
  set_target_properties(ocl PROPERTIES
    INSTALL_RPATH "/opt/homebrew/opt/libomp/lib;/usr/local/opt/libomp/lib;@loader_path")
  # copy libomp into install directory
  install(
    FILES ${OpenMP_CXX_LIBRARIES}
    DESTINATION "${Python_SITEARCH}/opencamlib"
    PERMISSIONS OWNER_READ GROUP_READ WORLD_READ
  )
  # fix loader path
  add_custom_command(TARGET ocl POST_BUILD
    COMMAND ${CMAKE_INSTALL_NAME_TOOL} -change `otool -L $<TARGET_FILE:ocl> | grep libomp | cut -d ' ' -f1 | xargs echo` "@rpath/libomp.dylib" $<TARGET_FILE:ocl>
  )
endif()
