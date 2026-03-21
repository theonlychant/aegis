// sample-18-approximate_set_cache.cpp
// Very small bloom-filter style presence check using std::hash (toy example)
#include <vector>
#include <string>
#include <functional>
#include <iostream>

int main(){
    std::vector<bool> bits(1024,false);
    auto add=[&](const std::string&s){ auto h=std::hash<std::string>{}(s)%bits.size(); bits[h]=true; };
    auto maybe_contains=[&](const std::string&s){ auto h=std::hash<std::string>{}(s)%bits.size(); return bits[h]; };
    add("x"); std::cout<<(maybe_contains("x")?"maybe":"no")<<"\n"; std::cout<<(maybe_contains("y")?"maybe":"no")<<"\n";
}
