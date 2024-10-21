pragma circom 2.1.7;

// Helper template to check if a >= b (returns 1 if true, 0 otherwise)
template GreaterThanOrEqual() {
    signal input a;
    signal input b;
    signal output result;

    signal diff;
    diff <== a - b;

    // To check if a >= b, diff must be non-negative.
    // We decompose the diff into two parts: a boolean (isNonNegative) and an absolute value.
    signal isNonNegative;

    isNonNegative <-- 1 - (diff < 0); // If diff is negative, isNonNegative is 0, else it's 1

    result <== isNonNegative; // result is 1 if a >= b, 0 otherwise
}

template LessThan() {
    signal input a;
    signal input b;
    signal output result;

    // We check if a < b by comparing their difference
    signal diff;
    diff <== b - a;

    // If diff is positive (b > a), the result should be 1, otherwise 0
    component isPositive = IsPositive();
    isPositive.in <== diff;

    result <== isPositive.out;
}

// Helper template to check if a signal is positive (returns 1 if true, 0 otherwise)
template IsPositive() {
    signal input in;
    signal output out;

    // Decompose the signal into binary components
    out <--in >= 0 ? 1 : 0;
}