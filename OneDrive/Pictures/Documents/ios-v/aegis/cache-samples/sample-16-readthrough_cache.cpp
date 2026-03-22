// sample-16-readthrough_cache.cpp
// Read-through cache: loads from backing store on miss
#include <unordered_map>
#include <string>
#include <iostream>

std::string backing_load(const std::string&k){ return "loaded-"+k; }

int main(){
    std::unordered_map<std::string,std::string> cache;
    auto get=[&](const std::string&k){ if(cache.find(k)==cache.end()) cache[k]=backing_load(k); return cache[k]; };
    std::cout<<get("x")<<"\n";
}
