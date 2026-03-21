// sample-06-weakref_cache.cpp
// Demonstrates storing std::weak_ptr values in cache
#include <unordered_map>
#include <memory>
#include <string>
#include <iostream>

struct Value{ std::string v; Value(std::string s):v(std::move(s)){} };

int main(){
    std::unordered_map<std::string,std::weak_ptr<Value>> cache;
    auto p=std::make_shared<Value>("data");
    cache["k"]=p;
    p.reset();
    if(auto w=cache["k"].lock()) std::cout<<w->v<<"\n"; else std::cout<<"expired\n";
}
