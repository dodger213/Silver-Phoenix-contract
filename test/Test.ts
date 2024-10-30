import { expect } from "chai";
import { ethers } from "hardhat";
import { SilverPhoenix } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("SilverPhoenix", function () {
  let silverPhoenix: SilverPhoenix;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let feeReceiver: SignerWithAddress;

  beforeEach(async function () {
    [owner, addr1, addr2, feeReceiver] = await ethers.getSigners();
    
    const SilverPhoenix = await ethers.getContractFactory("SilverPhoenix");
    silverPhoenix = await SilverPhoenix.deploy();
    await silverPhoenix.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await silverPhoenix.owner()).to.equal(owner.address);
    });

    it("Should have correct name and symbol", async function () {
      expect(await silverPhoenix.name()).to.equal("Silver Phoenix");
      expect(await silverPhoenix.symbol()).to.equal("SPX");
    });

    it("Should have correct decimals", async function () {
      expect(await silverPhoenix.decimals()).to.equal(8);
    });

    it("Should mint initial supply to owner", async function () {
      const totalSupply = await silverPhoenix.totalSupply();
      expect(await silverPhoenix.balanceOf(owner.address)).to.equal(totalSupply);
    });
  });

  describe("Trading and Fees", function () {
    it("Should enable trading", async function () {
      await silverPhoenix.enableTrading();
      // Try a transfer after enabling trading
      const amount = ethers.parseUnits("1000", 8);
      await silverPhoenix.transfer(addr1.address, amount);
      expect(await silverPhoenix.balanceOf(addr1.address)).to.be.gt(0);
    });

    it("Should exclude address from fees", async function () {
      await silverPhoenix.excludeFromFees(addr1.address, true);
      expect(await silverPhoenix.isExcludedFromFees(addr1.address)).to.be.true;
    });
  });

  describe("Fee Receiver", function () {
    it("Should change fee receiver", async function () {
      await silverPhoenix.changeFeeReceiver(addr1.address);
      // You would need to implement a getter for feeReceiver to test this
      // or test it through a transfer and checking received fees
    });
  });

  describe("Swap Settings", function () {
    it("Should set swap token amount", async function () {
      const newSwapAmount = ethers.parseUnits("1000", 8);
      await silverPhoenix.setSwapTokenAmount(newSwapAmount, true);
      // You would need to implement a getter for swapTokenAmount to test this
    });
  });

  describe("Token Transfers", function () {
    beforeEach(async function () {
      await silverPhoenix.enableTrading();
    });

    it("Should transfer tokens between accounts", async function () {
      const amount = ethers.parseUnits("1000", 8);
      await silverPhoenix.transfer(addr1.address, amount);
      
      const addr1Balance = await silverPhoenix.balanceOf(addr1.address);
      // Account for 4% transfer fee
      expect(addr1Balance).to.equal(amount * 96n / 100n);
    });

    it("Should fail when transferring more than balance", async function () {
      const initialBalance = await silverPhoenix.balanceOf(addr1.address);
      const excessAmount = initialBalance + ethers.parseUnits("1", 8);
      
      await expect(
        silverPhoenix.connect(addr1).transfer(addr2.address, excessAmount)
      ).to.be.reverted;
    });
  });

  describe("Emergency Functions", function () {
    it("Should allow owner to claim stuck tokens", async function () {
      const amount = ethers.parseUnits("1000", 8);
      await silverPhoenix.transfer(silverPhoenix.getAddress(), amount);
      await silverPhoenix.claimStuckTokens(await silverPhoenix.getAddress());
    });
  });
});
