// sample-07-sharded_cache.cpp
// Simple sharded cache using multiple maps to reduce contention
#include <vector>
#include <map>
#include <mutex>
#include <string>
#include <optional>
#include <functional>
#include <iostream>

class ShardedCache{
    static const int SHARDS=4;
    std::vector<std::map<std::string,std::string>> maps;
    std::vector<std::mutex> locks;
public:
    ShardedCache():maps(SHARDS),locks(SHARDS){}
    void put(const std::string&k,const std::string&v){ auto i=std::hash<std::string>{}(k)%SHARDS; std::lock_guard<std::mutex> l(locks[i]); maps[i][k]=v; }
    std::optional<std::string> get(const std::string&k){ auto i=std::hash<std::string>{}(k)%SHARDS; std::lock_guard<std::mutex> l(locks[i]); auto it=maps[i].find(k); if(it==maps[i].end()) return {}; return it->second; }
};

int main(){ ShardedCache c; c.put("a","1"); if(auto v=c.get("a")) std::cout<<*v<<"\n"; }
