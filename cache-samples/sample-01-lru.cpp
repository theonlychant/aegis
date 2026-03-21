// sample-01-lru.cpp
// Minimal LRU cache example (C++)
#include <list>
#include <unordered_map>
#include <iostream>

template<typename K, typename V>
struct LRUCache {
    size_t capacity;
    std::list<std::pair<K,V>> items;
    std::unordered_map<K, decltype(items.begin())> index;
    LRUCache(size_t c):capacity(c){}
    void put(const K& k,const V& v){
        auto it=index.find(k);
        if(it!=index.end()){ items.erase(it->second); index.erase(it); }
        items.emplace_front(k,v);
        index[k]=items.begin();
        if(index.size()>capacity){ auto last=items.end(); --last; index.erase(last->first); items.pop_back(); }
    }
    bool get(const K& k, V& out){ auto it=index.find(k); if(it==index.end()) return false; items.splice(items.begin(), items, it->second); out=items.front().second; return true; }
};

int main(){ LRUCache<std::string,std::string> c(2); c.put("a","1"); c.put("b","2"); std::string v; if(c.get("a",v)) std::cout<<"a="<<v<<"\n"; c.put("c","3"); if(!c.get("b",v)) std::cout<<"b evicted\n"; }
