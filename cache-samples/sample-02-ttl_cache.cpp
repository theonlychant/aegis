// sample-02-ttl_cache.cpp
// Simple TTL (time-to-live) file-backed cache example (C++)
#include <chrono>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>

namespace fs = std::filesystem;
using namespace std::chrono;

void put_ttl(const fs::path& dir, const std::string& key, const std::string& value, int ttl_seconds){
    fs::create_directories(dir);
    auto p = dir / key;
    std::ofstream out(p, std::ios::binary);
    out << value;
    auto expire = system_clock::to_time_t(system_clock::now() + seconds(ttl_seconds));
    fs::last_write_time(p, file_time_type::clock::now() + seconds(ttl_seconds));
}

bool get_ttl(const fs::path& dir, const std::string& key, std::string& out){
    auto p = dir / key;
    if(!fs::exists(p)) return false;
    std::ifstream in(p, std::ios::binary);
    out.assign((std::istreambuf_iterator<char>(in)), {});
    return true;
}

int main(){ fs::path d = "./ttl_cache"; put_ttl(d,"x","hello",5); std::string v; if(get_ttl(d,"x",v)) std::cout<<v<<"\n"; }
