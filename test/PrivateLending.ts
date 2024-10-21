import { expect } from "chai";
import hre from "hardhat";

describe("PrivateLending Contract", function () {
  let privateLending: any;
  let balanceCollateralVerifier: any, interestLiquidationVerifier: any;
  let owner: any;
  let mockCollateralProof: any;
  let mockInterestProof: any;

  beforeEach(async () => {
    [owner] = await hre.ethers.getSigners();

    const InterestLiquidation = await hre.ethers.getContractFactory(
      "InterestLiquidation"
    );

    interestLiquidationVerifier = await InterestLiquidation.deploy();

    const BalanceCollateralVerifier = await hre.ethers.getContractFactory(
      "BalanceCollateralVerifier"
    );

    balanceCollateralVerifier = await BalanceCollateralVerifier.deploy();

    const PrivateLendingFactory = await hre.ethers.getContractFactory(
      "PrivateLending"
    );
    privateLending = await PrivateLendingFactory.deploy(
      interestLiquidationVerifier.target,
      balanceCollateralVerifier.target
    );
  });

  // Mock proof data (these would typically come from your zk-SNARK proof generation)
  mockCollateralProof = {
    a: [
      "0x27af2599248567262221545a1c5073d2d7f6dad073e5e9f3707fa6eaa07bb876",
      "0x151336b26f504759b650305d73c78963d1c052dab540dfd7491d49fe72036077",
    ],
    b: [
      [
        "0x28482077559dd412afa93e58ffcb4e8ea73a9e89df89f8322a42fde1bcbd9880",
        "0x18a1f14517d283f7b536156e501d9eb4b6bdaba4d1f27646801c3a07ad0dbce7",
      ],
      [
        "0x0d85958f69d107c450a003d1050c19943c53448b705eaabfca9524db53ca0cbb",
        "0x2cf316701fc96f22e43368074f2bb63b1dbfa2032c0f3aa05aa1079af1449292",
      ],
    ],
    c: [
      "0x0866760b9ae0d00633a333931182c8ab3196923d0238a4ad383d81ad10e5e4a5",
      "0x043f3fa21a74dfaf748d8790a5e66c8a52e2764618063063813ebc395295db47",
    ],
    input: [
      "0x0000000000000000000000000000000000000000000000000000000000000001",
      "0x0000000000000000000000000000000000000000000000000000000000000001",
      "0x0000000000000000000000000000000000000000000000000000000000001388",
      "0x0000000000000000000000000000000000000000000000000000000000000096",
      "0x0000000000000000000000000000000000000000000000000000000000002710",
      "0x0000000000000000000000000000000000000000000000000000000000001f40",
      "0x0000000000000000000000000000000000000000000000000000000000000002",
    ],
  };

  mockInterestProof = {
    a: [
      "0x1be677e3e88bb6fe03d564f47a4a74d2067e7af6ac4de8cbb5cf85ea9f23fb68",
      "0x0cfbfb6220c5349afb2cec90b01e66905579eeca7f07c5c0fb0a776b6c7aa062",
    ],
    b: [
      [
        "0x0a4f94b309df259674471615327eec706c04c6d1f49e61aff231c0e1a28a037c",
        "0x126eb461d497aa476f46fd50c06e88488c4a99a8f9bef6bfcb65060a36cde321",
      ],
      [
        "0x0a5e705af8fb8285f38667e8991e47f0854a512366eed6040f43b28da5fa7107",
        "0x194f98b93f6b1a3326f70eee85723417ccacdfdee36a753332b16b9038d815e4",
      ],
    ],
    c: [
      "0x2fd00cf6147be782cb077f247d70b35a255e435921fb252a5eff9b9fc7f81732",
      "0x2c54ea540d09c05eb10a815b4283d0eab7a8504400197b778deacde963576cee",
    ],
    input: [
      "0x000000000000000000000000000000000000000000000000000000000000004b",
      "0x0000000000000000000000000000000000000000000000000000000000000001",
      "0x0000000000000000000000000000000000000000000000000000000000001388",
      "0x0000000000000000000000000000000000000000000000000000000000001770",
      "0x0000000000000000000000000000000000000000000000000000000000000005",
      "0x000000000000000000000000000000000000000000000000000000000000001e",
      "0x0000000000000000000000000000000000000000000000000000000000000078",
    ],
  };

  it("Should approve loan with valid collateral proof", async () => {
    await expect(
      privateLending
        .connect(owner)
        .requestLoan(
          mockCollateralProof.a,
          mockCollateralProof.b,
          mockCollateralProof.c,
          mockCollateralProof.input
        )
    )
      .to.emit(privateLending, "LoanApproved")
      .withArgs(owner.address, 5000, 8000);

    const loanDetails = await privateLending.getLoanDetails(owner.address);
    expect(loanDetails.loanAmount).to.equal(5000);
    expect(loanDetails.collateralAmount).to.equal(8000);
    expect(loanDetails.isLoanApproved).to.equal(true);
  });

  it("Should calculate interest and check liquidation", async () => {
    // First, request a loan
    await privateLending
      .connect(owner)
      .requestLoan(
        mockCollateralProof.a,
        mockCollateralProof.b,
        mockCollateralProof.c,
        mockCollateralProof.input
      );

    // Now, calculate interest and check liquidation
    await expect(
      privateLending
        .connect(owner)
        .calculateInterestAndCheckLiquidation(
          mockInterestProof.a,
          mockInterestProof.b,
          mockInterestProof.c,
          mockInterestProof.input
        )
    )
      .to.emit(privateLending, "InterestCalculated")
      .withArgs(owner.address, 75, true);

    const loanDetails = await privateLending.getLoanDetails(owner.address);
    expect(loanDetails.accruedInterest).to.equal(75);
    expect(loanDetails.isLiquidatable).to.equal(true);
  });

  it("Should not approve loan with invalid collateral proof", async () => {
    // Modify the proof data to be invalid
    const invalidProof = {
      ...mockCollateralProof,
      input: ["0", "0", "0", "0", "0", "0", "0"],
    };

    await expect(
      privateLending
        .connect(owner)
        .requestLoan(
          invalidProof.a,
          invalidProof.b,
          invalidProof.c,
          invalidProof.input
        )
    ).to.be.revertedWith("Invalid collateral zk-SNARK proof");
  });

  it("Should not calculate interest with invalid proof", async () => {
    // First, request a loan
    await privateLending
      .connect(owner)
      .requestLoan(
        mockCollateralProof.a,
        mockCollateralProof.b,
        mockCollateralProof.c,
        mockCollateralProof.input
      );

    // Modify the proof data to be invalid
    const invalidProof = {
      ...mockInterestProof,
      input: ["0", "0", "0", "0", "0", "0", "0"],
    };

    await expect(
      privateLending
        .connect(owner)
        .calculateInterestAndCheckLiquidation(
          invalidProof.a,
          invalidProof.b,
          invalidProof.c,
          invalidProof.input
        )
    ).to.be.revertedWith("Invalid interest liquidation zk-SNARK proof");
  });
});
