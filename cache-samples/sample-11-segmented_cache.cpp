// sample-11-segmented_cache.cpp
// Segmented LRU-like cache with two segments (probation + protected)
#include <unordered_map>
#include <list>
#include <string>
#include <iostream>

int main(){
    std::list<std::string> probation, protected_seg;
    std::unordered_map<std::string,std::string> store;
    auto access=[&](const std::string&k){ if(store.find(k)==store.end()) return; protected_seg.remove(k); protected_seg.push_front(k); };
    store["a"]="1"; probation.push_back("a"); access("a");
    for(auto &k:protected_seg) std::cout<<k<<"\n";
}
