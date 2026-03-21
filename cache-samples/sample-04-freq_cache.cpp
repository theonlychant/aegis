// sample-04-freq_cache.cpp
// Simple frequency-counting cache: stores counts per key
#include <unordered_map>
#include <string>
#include <iostream>

int main(){
    std::unordered_map<std::string,int> counts;
    auto inc=[&](const std::string& k){ counts[k]++; };
    inc("a"); inc("b"); inc("a");
    for(auto &p:counts) std::cout<<p.first<<":"<<p.second<<"\n";
}
