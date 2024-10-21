// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

interface InterestLiquidationVerifier {
    function verifyProof(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[7] calldata _pubSignals
    ) external view returns (bool);
}

interface IBalanceCollateralVerifier {
    function verifyProof(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[7] calldata _pubSignals
    ) external view returns (bool);
}

contract PrivateLending {
    InterestLiquidationVerifier interestLiquidationVerifier;
    IBalanceCollateralVerifier iBalanceCollateralVerifier;

    struct Loan {
        uint256 loanAmount;
        uint256 collateralAmount;
        bool isLoanApproved;
        uint256 accruedInterest;
        bool isLiquidatable;
    }

    mapping(address => Loan) public loans;

    event LoanApproved(
        address indexed user,
        uint256 loanAmount,
        uint256 collateralAmount
    );
    event InterestCalculated(
        address indexed user,
        uint256 accruedInterest,
        bool isLiquidatable
    );

    constructor(
        address _interestLiquidationVerifier,
        address _balanceCollateralVerifier
    ) {
        interestLiquidationVerifier = InterestLiquidationVerifier(
            _interestLiquidationVerifier
        );
        iBalanceCollateralVerifier = IBalanceCollateralVerifier(
            _balanceCollateralVerifier
        );
    }

    // Function to request a loan with collateral verification
    function requestLoan(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[7] memory input // Public inputs: [loanAmount, collateralAmount, requiredRatio]
    ) public {
        // Verify the collateral proof
        bool isValidCollateralProof = iBalanceCollateralVerifier.verifyProof(
            a,
            b,
            c,
            input
        );
        require(isValidCollateralProof, "Invalid collateral zk-SNARK proof");

        uint256 loanAmount = input[2];
        uint256 collateralAmount = input[5];

        // If the proof is valid, approve the loan
        loans[msg.sender] = Loan({
            loanAmount: loanAmount,
            collateralAmount: collateralAmount,
            isLoanApproved: true,
            accruedInterest: 0,
            isLiquidatable: false
        });

        emit LoanApproved(msg.sender, loanAmount, collateralAmount);
    }

    // Function to calculate interest and check for liquidation
    function calculateInterestAndCheckLiquidation(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[7] memory input // Public inputs: [loanAmount, collateralAmount, interestRate, timePassed, liquidationRatio]
    ) public {
        // Verify the interest and liquidation proof
        bool isValidInterestProof = interestLiquidationVerifier.verifyProof(
            a,
            b,
            c,
            input
        );
        require(
            isValidInterestProof,
            "Invalid interest liquidation zk-SNARK proof"
        );

        uint256 loanAmount = input[2];
        uint256 collateralAmount = input[3];
        uint256 interestRate = input[4];
        uint256 timePassed = input[5];
        uint256 liquidationRatio = input[6];

        // Calculate accrued interest
        uint256 loanInterest = (loanAmount * interestRate) / 100;

        uint256 accruedInterest = (loanInterest * timePassed) / 100;

        // Check if the loan is liquidatable
        uint256 requiredCollateral = ((loanAmount + accruedInterest) *
            liquidationRatio) / 100;

        bool isLiquidatable = (collateralAmount < requiredCollateral);

        // Update the loan details
        loans[msg.sender].collateralAmount = collateralAmount;
        loans[msg.sender].accruedInterest = accruedInterest;
        loans[msg.sender].isLiquidatable = isLiquidatable;

        emit InterestCalculated(msg.sender, accruedInterest, isLiquidatable);
    }

    // Function to view loan details
    function getLoanDetails(address user) public view returns (Loan memory) {
        return loans[user];
    }
}
