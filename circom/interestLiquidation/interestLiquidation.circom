pragma circom 2.1.7;

include "../utils.circom";

template InterestLiquidation() {
    // Public Inputs
    signal input loanAmount;         // Principal loan amount
    signal input collateralAmount;   // Collateral amount
    signal input interestRate;       // Interest rate in %
    signal input timePassed;         // Time passed (in days or blocks)
    signal input liquidationRatio;   // Liquidation ratio in %

    // Output signals
    signal output accruedInterest;   // The accrued interest
    signal output isLiquidatable;    // True if loan is liquidatable

    // Compute the accrued interest
    signal loanInterest;

    loanInterest <== loanAmount * interestRate / 100;

    accruedInterest <== (loanInterest * timePassed) / 100;

    // Compute the required collateral for liquidation
    signal requiredCollateral;
    requiredCollateral <== (loanAmount + accruedInterest) * liquidationRatio / 100;

    // Check if collateralAmount < requiredCollateral
    component liquidatableCheck = LessThan();
    liquidatableCheck.a <== collateralAmount;
    liquidatableCheck.b <== requiredCollateral;
    isLiquidatable <== liquidatableCheck.result; // 1 if liquidatable, 0 otherwise
}

component main {public [
    loanAmount,
    collateralAmount,
    interestRate, 
    timePassed,
    liquidationRatio
]} = InterestLiquidation();