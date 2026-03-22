// sample-15-memstore_snapshot.cpp
// Take a snapshot of in-memory cache to a file
#include <unordered_map>
#include <string>
#include <fstream>
#include <iostream>

int main(){
    std::unordered_map<std::string,std::string> cache{{"a","1"},{"b","2"}};
    std::ofstream out("snapshot.db");
    for(auto &p:cache) out<<p.first<<"="<<p.second<<"\n";
    std::cout<<"wrote snapshot.db\n";
}
