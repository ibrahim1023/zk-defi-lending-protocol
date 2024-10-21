pragma circom  2.1.7;

include "../utils.circom";

template BalanceCollateralVerification () {

    signal input loanAmount;
    signal input requiredRatio;

    signal input userBalance;
    signal input collateralAmount;
    signal input collateralPrice;

    signal output isValidBalance;
    signal output isValidCollateral;

    // Check if userBalance >= loanAmount
    component balanceCheck = GreaterThanOrEqual();
    balanceCheck.a <== userBalance;
    balanceCheck.b <== loanAmount;
    isValidBalance <== balanceCheck.result;

    signal requiredCollateral;
    requiredCollateral <== loanAmount * requiredRatio / 100;

    signal collateralValue;
        collateralValue <== collateralAmount * collateralPrice;

    // Check if collateralValue >= requiredCollateral
    component collateralCheck = GreaterThanOrEqual();
    collateralCheck.a <== collateralValue;
    collateralCheck.b <== requiredCollateral;
    isValidCollateral <== collateralCheck.result;
}

component main {public [loanAmount,
  requiredRatio,
  userBalance,
  collateralAmount,
  collateralPrice]} = BalanceCollateralVerification();
