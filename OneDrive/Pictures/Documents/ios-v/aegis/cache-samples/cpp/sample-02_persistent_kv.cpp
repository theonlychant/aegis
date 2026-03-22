// sample-02_persistent_kv.cpp
// File-backed key-value cache with simple serialization.
#include <unordered_map>
#include <string>
#include <fstream>
#include <sstream>
#include <iostream>

class PersistentKV {
    std::unordered_map<std::string,std::string> m;
    std::string path;
public:
    PersistentKV(std::string p):path(std::move(p)){ load(); }
    void put(const std::string&k,const std::string&v){ m[k]=v; }
    bool get(const std::string&k,std::string&out){ auto it=m.find(k); if(it==m.end()) return false; out=it->second; return true; }
    void save(){ std::ofstream o(path, std::ios::trunc); for(auto &p:m) o<<escape(p.first)<<"="<<escape(p.second)<<"\n"; }
private:
    static std::string escape(const std::string&s){ std::ostringstream ss; for(unsigned char c:s) if(c=='\\' || c=='=') ss<<'\\'<<c; else ss<<c; return ss.str(); }
    static std::string unescape(const std::string&s){ std::string r; for(size_t i=0;i<s.size();++i){ if(s[i]=='\\' && i+1<s.size()){ r.push_back(s[i+1]); ++i; } else r.push_back(s[i]); } return r; }
    void load(){ std::ifstream i(path); std::string line; while(std::getline(i,line)){ auto pos=line.find('='); if(pos==std::string::npos) continue; auto k=line.substr(0,pos); auto v=line.substr(pos+1); m[unescape(k)]=unescape(v); } }
};

int main(){
    PersistentKV kv("kv.db");
    kv.put("hello","world");
    kv.put("count","42");
    kv.save();
    std::string out;
    if(kv.get("hello",out)) std::cout<<"hello="<<out<<"\n";
}
