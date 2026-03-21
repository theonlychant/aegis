cmake_minimum_required(VERSION 3.15)
project(engine-c)
add_library(engine_c STATIC src/bridge.c)
target_sources(engine_c PRIVATE src/wrapper.c)
add_executable(engine_c_test src/test_bridge.c)
target_link_libraries(engine_c_test PRIVATE engine_c)

# If the parent project provides a Rust FFI library path (RUST_FFI_LIB),
# import it and link to the engine_c target so consumers (tests) resolve symbols.
if(DEFINED RUST_FFI_LIB AND RUST_FFI_LIB)
	message(STATUS "engine-c: Importing Rust FFI library: ${RUST_FFI_LIB}")
	add_library(rustffi_static STATIC IMPORTED)
	set_target_properties(rustffi_static PROPERTIES IMPORTED_LOCATION "${RUST_FFI_LIB}")
	target_link_libraries(engine_c PRIVATE rustffi_static)
endif()
target_include_directories(engine_c PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
set_target_properties(engine_c PROPERTIES PUBLIC_HEADER include/aegis_ffi.h)
