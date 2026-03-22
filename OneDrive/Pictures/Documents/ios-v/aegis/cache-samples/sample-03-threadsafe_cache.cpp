// sample-03-threadsafe_cache.cpp
// Minimal thread-safe in-memory cache using mutex
#include <map>
#include <mutex>
#include <optional>
#include <string>
#include <iostream>

class ThreadSafeCache {
    std::map<std::string,std::string> m;
    std::mutex mu;
public:
    void put(const std::string& k,const std::string& v){ std::lock_guard<std::mutex> l(mu); m[k]=v; }
    std::optional<std::string> get(const std::string& k){ std::lock_guard<std::mutex> l(mu); auto it=m.find(k); if(it==m.end()) return {}; return it->second; }
};

int main(){ ThreadSafeCache c; c.put("k","v"); if(auto v=c.get("k")) std::cout<<*v<<"\n"; }
