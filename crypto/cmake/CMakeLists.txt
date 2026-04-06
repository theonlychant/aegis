option(VENDOR_CRYPTOPP "Build Crypto++ from source" OFF)

if (NOT APPLE)
    if (NOT VENDOR_CRYPTOPP)
        find_package(CryptoPP CONFIG QUIET)
    endif()

    if (CryptoPP_FOUND)
        target_link_libraries(local-encrypted PRIVATE CryptoPP::CryptoPP)
    else()
        message(STATUS "CryptoPP not found, using vendored build")

        # Example fallback (simplified)
        add_subdirectory(third_party/cryptopp)
        target_link_libraries(local-encrypted PRIVATE cryptopp)
    endif()
endif()