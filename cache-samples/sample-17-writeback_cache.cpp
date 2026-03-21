// sample-17-writeback_cache.cpp
// Write-back cache: collect dirty entries and flush on demand
#include <unordered_map>
#include <string>
#include <iostream>
#include <vector>

int main(){
    std::unordered_map<std::string,std::pair<std::string,bool>> cache; // value, dirty
    auto put=[&](const std::string&k,const std::string&v){ cache[k]={v,true}; };
    auto flush=[&](){ std::vector<std::pair<std::string,std::string>> to_write; for(auto &p:cache) if(p.second.second) to_write.push_back({p.first,p.second.first}); for(auto &e:to_write) std::cout<<"flush "<<e.first<<"="<<e.second<<"\n"; };
    put("a","1"); put("b","2"); flush();
}
