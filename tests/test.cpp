// g++ -I../cpp/ -o test test.cpp
#include "shader_parser.hpp"

int main(int argc, char** argv)
{
    ShaderLib::ShaderParser parser("../");
    auto test = parser.generateShaderFromFiles({"test.shader"});
    std::cout << test[0] << std::endl;
    return 0;
}