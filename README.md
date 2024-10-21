# ZK DeFi Lending Protocol

This project implements a Private DeFi Lending/Borrowing Protocol that uses zk-SNARKs to ensure the privacy of loan balances, collateral, and interest calculations. The protocol is designed to facilitate decentralized finance while protecting user data from exposure on-chain.

The protocol uses zero-knowledge proofs (ZKPs) to verify operations without revealing sensitive information, including:

Loan requests
Collateral checks
Interest calculations
Liquidation status

## Features

- **Private Lending/Borrowing**: Users can take loans and submit collateral without revealing the amounts on-chain.
- **zk-SNARK Verification**: Groth16 zk-SNARK proofs ensure privacy while maintaining security.
- **Efficient Contract Design**: The protocol optimizes interactions by combining key functions like interest calculation and liquidation check in one circuit.
- **Modular Structure**: Separation of circuits for loan requests and interest/liquidation ensures clean and maintainable code.

## Technology Stack

- **Solidity (>=0.7.0)**: Smart contracts for interaction with zk-SNARK verifiers.
- **Circom**: Used for building zk-SNARK circuits for private operations.
- **Groth16**: The zk-SNARK proving system used in the protocol.
- **snarkJS**: For generating proofs and verifier contracts.
- **TypeScript**: For writing unit tests to ensure the correctness of the contracts.

## Circuits

Two main circuits power the protocol:

1. **Collateral Verification Circuit**: This circuit verifies that the borrower has submitted sufficient collateral for a loan without revealing the amount on-chain.
2. **Interest Calculation and Liquidation Circuit**: This circuit calculates the loan interest and determines if a loan should be liquidated based on zk-SNARK verified inputs.

## Contracts

The smart contracts are written in Solidity and interact with zk-SNARK verifiers to maintain privacy.

1. **Groth16Verifier.sol**: Verifier contracts (of both circuits) generated using snarkJS for verifying zk-SNARK proofs.
2. **PrivateLending.sol**: The main contract managing loans, interest calculations, collateral checks, and liquidation status. It interacts with both zk-SNARK verifier contracts.

## Circom

The circom circuits require the following procedure: 

1. Compile the circuits

```
cd circuits
```

```
circom balanceCollateralVerification.circom --r1cs --wasm --sym --c
```

2. Compute the witness

```
node balanceCollateralVerification_js/generate_witness.js balanceCollateralVerification_js/balanceCollateralVerification.wasm input.json witness.wtns
```

3. Generate and validate the proof for our input

First we'll generate a [trusted setup](https://docs.circom.io/background/background/)
```
snarkjs powersoftau new bn128 12 pot12_0000.ptau -v
snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="First contribution" -v
snarkjs powersoftau prepare phase2 pot12_0001.ptau pot12_final.ptau -v
```

Next, we generate a .zkey file that will contain the proving and verification keys
```
snarkjs groth16 setup balanceCollateralVerification.r1cs pot12_final.ptau balanceCollateralVerification_0000.zkey
snarkjs zkey contribute balanceCollateralVerification_0000.zkey balanceCollateralVerification_0001.zkey --name="1st Contributor Name" -v
snarkjs zkey export verificationkey balanceCollateralVerification_0001.zkey verification_key.json
```

Generating the proof
```
snarkjs groth16 prove balanceCollateralVerification_0001.zkey witness.wtns proof.json public.json
```

Verifying the proof
```
snarkjs groth16 verify verification_key.json public.json proof.json
```

4. Generate a solidity verifier contract

```
snarkjs zkey export solidityverifier balanceCollateralVerification_0001.zkey balanceCollateralVerifier.sol
```

5. Create the input parameters

```
snarkjs generatecall
```

And the same steps can be applied for InterestLiquidation circuit 

## Usage

### Compile the contracts
```
npx hardhat compile
```

### Run the tests
```
npx hardhat test
```

## Tests 

```
PrivateLending Contract
    ✔ Should approve loan with valid collateral proof
    ✔ Should calculate interest and check liquidation
    ✔ Should not approve loan with invalid collateral proof
    ✔ Should not calculate interest with invalid proof
```
