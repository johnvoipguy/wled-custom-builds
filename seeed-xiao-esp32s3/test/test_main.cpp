#include <Arduino.h>
#include <unity.h>

void setUp(void) {
    // Set up code here, if needed
}

void tearDown(void) {
    // Clean up code here, if needed
}

void test_example() {
    TEST_ASSERT_EQUAL(1, 1); // Example test case
}

void setup() {
    UNITY_BEGIN(); // Start Unity test framework
    RUN_TEST(test_example); // Run the example test
    UNITY_END(); // End Unity test framework
}

void loop() {
    // No loop code needed for tests
}