// sample-14-compact_cache.cpp
// Compacting cache representation by rehashing when many deletions happen
#include <unordered_map>
#include <string>
#include <iostream>

int main(){
    std::unordered_map<std::string,std::string> c;
    for(int i=0;i<100;i++) c[std::to_string(i)]="v"+std::to_string(i);
    for(int i=0;i<90;i++) c.erase(std::to_string(i));
    c.rehash(0); // compact
    std::cout<<"size="<<c.size()<<" buckets="<<c.bucket_count()<<"\n";
}
