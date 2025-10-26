#include <gtest/gtest.h>

#include "my_lib.hpp"

TEST(AddTest, PositiveNumbers) {
    EXPECT_EQ(myproject::add(2, 3), 5);
    EXPECT_EQ(myproject::add(10, 20), 30);
}

TEST(AddTest, NegativeNumbers) {
    EXPECT_EQ(myproject::add(-2, -3), -5);
    EXPECT_EQ(myproject::add(-10, 5), -5);
}

TEST(MultiplyTest, PositiveNumbers) {
    EXPECT_EQ(myproject::multiply(2, 3), 6);
    EXPECT_EQ(myproject::multiply(5, 4), 20);
}

TEST(MultiplyTest, Zero) {
    EXPECT_EQ(myproject::multiply(0, 5), 0);
    EXPECT_EQ(myproject::multiply(10, 0), 0);
}
