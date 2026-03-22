// sample-08-lfu_cache.cpp
// Simple LFU cache (not optimized for production)
#include <unordered_map>
#include <map>
#include <string>
#include <iostream>

class LFUCache{
    std::unordered_map<std::string,std::pair<std::string,int>> m;
public:
    void put(const std::string&k,const std::string&v){ m[k]={v,1}; }
    std::optional<std::string> get(const std::string&k){ auto it=m.find(k); if(it==m.end()) return {}; it->second.second++; return it->second.first; }
    std::string evict(){ int min=INT_MAX; std::string key=""; for(auto &p:m) if(p.second.second<min){min=p.second.second; key=p.first;} if(!key.empty()) m.erase(key); return key; }
};

int main(){ LFUCache c; c.put("x","1"); c.put("y","2"); c.get("x"); std::cout<<c.evict()<<"\n"; }
