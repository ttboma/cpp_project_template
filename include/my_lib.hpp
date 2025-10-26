#pragma once

// Windows DLL export/import macros
#ifdef _WIN32
    #ifdef mylib_EXPORTS
        #define MYLIB_API __declspec(dllexport)
    #else
        #define MYLIB_API __declspec(dllimport)
    #endif
#else
    #define MYLIB_API
#endif

namespace myproject {

/**
 * @brief Add two integers
 * @param a First integer
 * @param b Second integer
 * @return Sum of a and b
 */
MYLIB_API int add(int a, int b);

/**
 * @brief Multiply two integers
 * @param a First integer
 * @param b Second integer
 * @return Product of a and b
 */
MYLIB_API int multiply(int a, int b);

}  // namespace myproject
