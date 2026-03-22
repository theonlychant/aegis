// sample-20-bounded_mmap_cache.cpp
// Placeholder: shows idea of bounded memory via reserving vector (not true mmap here)
#include <vector>
#include <string>
#include <iostream>

int main(){
    std::vector<char> buffer;
    buffer.reserve(1024*16); // reserve 16KB
    std::string s="cached-data";
    buffer.insert(buffer.end(), s.begin(), s.end());
    std::cout<<"buffered="<<buffer.size()<<" bytes\n";
}
