# Cache Samples

This folder contains longer example cache implementations in C++, Swift, and Objective-C intended as educational samples for different cache strategies and integration patterns.

Files:
- `cpp/sample-01_lru_cache.cpp` - full LRU cache class with usage examples and simple benchmark.
- `cpp/sample-02_persistent_kv.cpp` - file-backed key-value cache with basic serialization.
- `swift/sample-03_generic_cache.swift` - generic Swift cache with TTL and asynchronous loader.
- `swift/sample-04_persistent_cache.swift` - Codable-based persistent cache example.
- `objc/Cache.h` & `objc/Cache.m` - Objective-C LRU cache class with Foundation APIs.
- `objc/AsyncCache.h` & `objc/AsyncCache.m` - Objective-C async read-through cache using GCD.

Build / Run (examples):
- C++: `g++ -std=c++17 cpp/sample-01_lru_cache.cpp -O2 -o lru && ./lru`
- Swift: `swiftc swift/sample-03_generic_cache.swift -o swiftcache && ./swiftcache`
- Objective-C: `clang -ObjC -fobjc-arc objc/Cache.m objc/AsyncCache.m -framework Foundation -o objc_cache && ./objc_cache`
