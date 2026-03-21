// sample-12-timewheel_ttl.cpp
// Simple TTL expiration using periodic sweep (time wheel omitted for brevity)
#include <unordered_map>
#include <chrono>
#include <thread>
#include <string>
#include <iostream>

int main(){
    std::unordered_map<std::string,std::pair<std::string,std::chrono::steady_clock::time_point>> m;
    m["k"]={"v", std::chrono::steady_clock::now()+std::chrono::seconds(1)};
    std::this_thread::sleep_for(std::chrono::milliseconds(1100));
    auto now=std::chrono::steady_clock::now();
    for(auto it=m.begin(); it!=m.end(); ){
        if(it->second.second<=now) it=m.erase(it); else ++it;
    }
    std::cout<<"size="<<m.size()<<"\n";
}
