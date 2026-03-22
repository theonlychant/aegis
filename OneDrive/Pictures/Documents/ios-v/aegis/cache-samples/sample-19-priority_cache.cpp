// sample-19-priority_cache.cpp
// Cache that keeps items with highest priority (toy example)
#include <map>
#include <string>
#include <iostream>

int main(){
    std::multimap<int,std::string> mm; // priority -> key
    mm.insert({5,"a"}); mm.insert({1,"b"}); mm.insert({10,"c"});
    auto it=mm.rbegin(); std::cout<<"top="<<it->second<<"\n";
}
