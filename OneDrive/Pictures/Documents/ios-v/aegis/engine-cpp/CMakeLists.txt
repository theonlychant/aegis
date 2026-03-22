cmake_minimum_required(VERSION 3.15)
project(engine-cpp)
add_library(engine_cpp_lib STATIC src/main.cpp)
target_include_directories(engine_cpp_lib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/../engine-c/include)
add_executable(engine_cpp_run src/main.cpp)
target_link_libraries(engine_cpp_run PRIVATE engine_cpp_lib engine_c)
set_target_properties(engine_cpp_lib engine_cpp_run PROPERTIES CXX_STANDARD 17)

# Build engine-c as an internal static lib so linking works locally
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../engine-c" engine_c_build)
target_link_libraries(engine_cpp_lib PRIVATE engine_c)

# Optional: link Rust-produced FFI library if provided via RUST_FFI_LIB variable
if(DEFINED RUST_FFI_LIB AND RUST_FFI_LIB)
	message(STATUS "Linking Rust FFI library: ${RUST_FFI_LIB}")
	add_library(rustffi SHARED IMPORTED)
	set_target_properties(rustffi PROPERTIES IMPORTED_LOCATION "${RUST_FFI_LIB}")
	target_link_libraries(engine_cpp_run PRIVATE rustffi)
endif()

# Link OpenSSL for integrity & signature verification
find_package(OpenSSL REQUIRED)
if(OpenSSL_FOUND)
    target_link_libraries(engine_cpp_run PRIVATE OpenSSL::Crypto OpenSSL::SSL)
endif()
