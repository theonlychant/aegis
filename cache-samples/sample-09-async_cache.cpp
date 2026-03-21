// sample-09-async_cache.cpp
// Shows asynchronous loading into cache via std::async
#include <future>
#include <unordered_map>
#include <mutex>
#include <string>
#include <iostream>

int main(){
    std::unordered_map<std::string,std::string> cache;
    std::mutex mu;
    auto load_async=[&](const std::string&k){ return std::async(std::launch::async,[&]{ std::this_thread::sleep_for(std::chrono::milliseconds(50)); return std::string("val-")+k; }); };
    auto f=load_async("k");
    { std::lock_guard<std::mutex> l(mu); cache["k"]=f.get(); }
    std::cout<<cache["k"]<<"\n";
}
