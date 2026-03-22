// sample-05-persistent_kv.cpp
// Very small file-backed key-value store (not robust, demo only)
#include <fstream>
#include <unordered_map>
#include <string>
#include <iostream>

int main(){
    std::unordered_map<std::string,std::string> m;
    std::ifstream in("kv.db");
    std::string k,v;
    while(in>>k>>v) m[k]=v;
    m["hello"]="world";
    std::ofstream out("kv.db");
    for(auto &p:m) out<<p.first<<" "<<p.second<<"\n";
    std::cout<<"Stored hello\n";
}
