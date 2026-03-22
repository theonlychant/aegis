// sample-01_lru_cache.cpp
// LRU cache implementation with simple micro-benchmark and usage examples.
#include <unordered_map>
#include <list>
#include <chrono>
#include <iostream>
#include <string>
#include <thread>

template<typename K, typename V>
class LRUCache {
public:
    LRUCache(size_t capacity): cap(capacity) {}
    void put(const K &k, V v) {
        auto it = map.find(k);
        if (it != map.end()) {
            it->second->second = std::move(v);
            list.splice(list.begin(), list, it->second);
            return;
        }
        if (list.size() >= cap) {
            auto last = list.back().first;
            map.erase(last);
            list.pop_back();
        }
        list.emplace_front(k, std::move(v));
        map[k] = list.begin();
    }
    bool get(const K &k, V &out) {
        auto it = map.find(k);
        if (it == map.end()) return false;
        list.splice(list.begin(), list, it->second);
        out = it->second->second;
        return true;
    }
    size_t size() const { return map.size(); }
private:
    size_t cap;
    std::list<std::pair<K,V>> list;
    std::unordered_map<K, typename std::list<std::pair<K,V>>::iterator> map;
};

int main(){
    LRUCache<std::string,std::string> c(1000);
    // warm-up
    for(int i=0;i<1000;i++) c.put("k"+std::to_string(i), "v"+std::to_string(i));
    // benchmark: mix of gets/puts
    auto start = std::chrono::steady_clock::now();
    for(int i=0;i<20000;i++){
        std::string k = "k"+std::to_string(i%1500);
        std::string v;
        if(!c.get(k,v)) c.put(k, "new-"+k);
    }
    auto end = std::chrono::steady_clock::now();
    std::cout<<"ops elapsed ms="<<std::chrono::duration_cast<std::chrono::milliseconds>(end-start).count()<<" size="<<c.size()<<"\n";
    // usage example
    std::string out;
    if(c.get("k42", out)) std::cout<<"k42="<<out<<"\n";
}
