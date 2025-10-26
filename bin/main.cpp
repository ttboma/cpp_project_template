#include <iostream>

#include "my_lib.hpp"

int main() {
    std::cout << "MyProject Application\n";
    std::cout << "5 + 3 = " << myproject::add(5, 3) << "\n";
    std::cout << "5 * 3 = " << myproject::multiply(5, 3) << "\n";
    return 0;
}
