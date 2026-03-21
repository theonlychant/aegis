cmake_minimum_required(VERSION 3.10)
project(aegis_local_encrypted LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Try to locate Crypto++ headers and library
find_path(CRYPTOPP_INCLUDE_DIR NAMES cryptlib.h PATHS /usr/include /usr/local/include PATH_SUFFIXES cryptopp crypto++)
find_library(CRYPTOPP_LIBRARY NAMES cryptopp libcryptopp PATHS /usr/lib /usr/local/lib)

if(NOT CRYPTOPP_INCLUDE_DIR OR NOT CRYPTOPP_LIBRARY)
  message(FATAL_ERROR "Crypto++ not found. Set CRYPTOPP_INCLUDE_DIR and CRYPTOPP_LIBRARY to point to your Crypto++ installation.")
endif()

message(STATUS "Crypto++ include: ${CRYPTOPP_INCLUDE_DIR}")
message(STATUS "Crypto++ lib: ${CRYPTOPP_LIBRARY}")

include_directories(${CRYPTOPP_INCLUDE_DIR})

include(CheckIncludeFiles)
check_include_files("cryptopp/gcm.h;cryptopp/cryptlib.h" HAVE_CRYPTOPP_HEADERS)
if(NOT HAVE_CRYPTOPP_HEADERS)
  message(FATAL_ERROR "Crypto++ headers (cryptopp/gcm.h, cryptopp/cryptlib.h) not found in ${CRYPTOPP_INCLUDE_DIR}. Install Crypto++ dev package (e.g., libcryptopp-dev) and retry.")
endif()

add_library(aegis_local_encrypted STATIC
  crypto/crypto.cpp
  c_bridge/bridge.cpp
)

target_include_directories(aegis_local_encrypted PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(aegis_local_encrypted PRIVATE ${CRYPTOPP_LIBRARY})

# Test executable
enable_testing()
add_executable(test_crypto tests/test_crypto.cpp)
target_link_libraries(test_crypto PRIVATE aegis_local_encrypted ${CRYPTOPP_LIBRARY})
add_test(NAME test_crypto COMMAND test_crypto)
