#include <chrono>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

// Simple C++ benchmark that times reading a large corpus and running the engine-cpp demo
int main() {
    std::ifstream f("../rules/corpora/malicious.txt");
    std::stringstream buf;
    buf << f.rdbuf();
    std::string data = buf.str();
    // Repeat to enlarge
    std::string big;
    for (int i = 0; i < 200; ++i) big += data;

    auto start = std::chrono::high_resolution_clock::now();
    // Simulate work: count occurrences of "malicious" substring
    size_t found = 0;
    std::string pat = "malicious";
    for (int iter = 0; iter < 100; ++iter) {
        size_t pos = 0;
        while ((pos = big.find(pat, pos)) != std::string::npos) {
            ++found; pos += pat.size();
        }
    }
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> diff = end - start;
    std::cout << "Found: " << found << " Time: " << diff.count() << "s\n";
    return 0;
}
