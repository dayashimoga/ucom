cmake_minimum_required(VERSION 3.10)
project(unicom_app LANGUAGES CXX)

set(BINARY_NAME "unicom_app")

cmake_policy(SET CMP0079 NEW)

find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED gtk+-3.0)

find_package(flutter CONFIG REQUIRED)

add_subdirectory(flutter)
