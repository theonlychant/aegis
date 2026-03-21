// sample-10-evict_on_size.cpp
// Evict oldest entry when cache exceeds max size (simple vector order)
#include <unordered_map>
#include <vector>
#include <string>
#include <iostream>

int main(){
    size_t maxSize=2;
    std::vector<std::string> order;
    std::unordered_map<std::string,std::string> cache;
    auto put=[&](const std::string&k,const std::string&v){ if(cache.find(k)==cache.end()) order.push_back(k); cache[k]=v; if(order.size()>maxSize){ auto old=order.front(); order.erase(order.begin()); cache.erase(old); }};
    put("a","1"); put("b","2"); put("c","3");
    for(auto &p:cache) std::cout<<p.first<<":"<<p.second<<"\n";
}
