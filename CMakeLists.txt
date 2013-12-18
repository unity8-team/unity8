cmake_minimum_required(VERSION 2.8.9)

project(reminders-app C CXX)

set(CMAKE_AUTOMOC ON)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -fno-permissive -pedantic -Wall -Wextra -fPIC")

add_subdirectory(3rdParty)
add_subdirectory(src)
