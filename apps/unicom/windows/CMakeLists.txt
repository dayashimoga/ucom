cmake_minimum_required(VERSION 3.14)
project(unicom_app LANGUAGES CXX)

set(BINARY_NAME "unicom_app")

cmake_policy(SET CMP0079 NEW)

add_definitions(-DUNICODE -D_UNICODE)

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

find_package(flutter CONFIG REQUIRED)

add_subdirectory(flutter)
add_subdirectory(runner)
