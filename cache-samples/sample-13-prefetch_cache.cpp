// sample-13-prefetch_cache.cpp
// Prefetch next keys on hit (demo behavior)
#include <unordered_map>
#include <string>
#include <iostream>

int main(){
    std::unordered_map<std::string,std::string> store{{"1","one"},{"2","two"},{"3","three"}};
    std::unordered_map<std::string,std::string> cache;
    auto get=[&](const std::string&k){ if(store.find(k)!=store.end()) { cache[k]=store[k]; if(k!="3") cache[std::to_string(std::stoi(k)+1)]=store[std::to_string(std::stoi(k)+1)]; return cache[k]; } return std::string(); };
    std::cout<<get("1")<<"\n"; if(cache.find("2")!=cache.end()) std::cout<<"prefetched 2="<<cache["2"]<<"\n";
}
