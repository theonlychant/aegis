#include <iostream>
#include <vector>
#include <string>
#include "../crypto/crypto.hpp"

int main(){
  using namespace std;
  vector<uint8_t> key(32); // 256-bit key (for AES-256)
  for(size_t i=0;i<key.size();++i) key[i] = (uint8_t)i;
  vector<uint8_t> nonce(12);
  for(size_t i=0;i<nonce.size();++i) nonce[i] = (uint8_t)(i+1);
  string message = "The quick brown fox jumps over the lazy dog";
  vector<uint8_t> pt(message.begin(), message.end());

  vector<uint8_t> ct; vector<uint8_t> tag;
  bool ok = aegis::crypto::encrypt(key, nonce, pt, ct, tag);
  if(!ok){ cerr<<"encrypt failed"<<endl; return 2; }
  vector<uint8_t> out;
  ok = aegis::crypto::decrypt(key, nonce, ct, tag, out);
  if(!ok){ cerr<<"decrypt failed"<<endl; return 3; }
  string recovered(out.begin(), out.end());
  cout << "recovered: " << recovered << endl;
  return (recovered==message) ? 0 : 4;
}
