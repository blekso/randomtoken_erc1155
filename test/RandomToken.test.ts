import { ethers } from "hardhat";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { deployContract } from "../scripts/utils";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import {
  RandomToken,
  VictoryToken,
} from "../typechain-types";

describe("RandomToken", async () => {
  let randomToken: RandomToken;
  let victoryToken: VictoryToken;
  let deployer: SignerWithAddress;
  let accounts: SignerWithAddress[];
  let price: BigNumber;
  let maxSupply: number;
  let rewardAmount: BigNumber;

  beforeEach(async () => {
    [deployer, ...accounts] = await ethers.getSigners();

    price = BigNumber.from(0);
    maxSupply = 150;
    rewardAmount = ethers.utils.parseEther("50");
    // const RandomToken = await ethers.getContractFactory(
    //   "RandomToken"
    // );

    victoryToken = (await deployContract("VictoryToken", [
      "VictoryToken",
      "VT",
    ])) as VictoryToken;
    randomToken = (await deployContract("RandomToken", [
      "TokenZaIgricu",
      "TZI",
      price,
      maxSupply,
      rewardAmount,
      victoryToken.address,
    ])) as RandomToken;

    const minterRole = await victoryToken.MINTER_ROLE();
    await victoryToken.grantRole(
      minterRole,
      randomToken.address
    );
    // await randomToken.deployed();
  });

  it("Should successfully deploy RandomToken contract", async () => {
    console.log(await randomToken.name());
  });

  describe("Minting", async () => {
    it("Should successfully mint a token", async () => {
      const enemy = accounts[0];

      await randomToken.mint();
      await randomToken.connect(enemy).mint();
      await randomToken.attack(1, 2);

      const battleCount = await randomToken.battleCount();

      if (
        (
          await randomToken.tokenIdToChampion(1)
        ).attackPower.gt(
          (await randomToken.tokenIdToChampion(2))
            .defensePower
        )
      ) {
        expect(
          await randomToken.battleWinner(battleCount)
        ).to.equal(deployer.address);
      } else {
        expect(
          await randomToken.battleWinner(battleCount)
        ).to.equal(enemy.address);
      }
    });
  });

  describe("Upgrading", async () => {
    it("Should successfully upgrade a champion", async () => {
      await randomToken.mint();

      const attackPowerBefore = (
        await randomToken.tokenIdToChampion(1)
      ).attackPower;
      const defensePowerBefore = (
        await randomToken.tokenIdToChampion(1)
      ).defensePower;

      await expect(
        randomToken.upgradeChampion(1, true, true)
      )
        .to.emit(randomToken, "ChampionUpgraded")
        .withArgs(1, true, true);

      const attackPowerAfter = (
        await randomToken.tokenIdToChampion(1)
      ).attackPower;
      const defensePowerAfter = (
        await randomToken.tokenIdToChampion(1)
      ).defensePower;

      expect(attackPowerAfter).to.be.greaterThan(
        attackPowerBefore
      );
      expect(defensePowerAfter).to.be.greaterThan(
        defensePowerBefore
      );
    });

    it("Should successfully upgrade a champion with value sent", async () => {
      const upgradePrice = ethers.utils.parseEther("1");
      await randomToken.mint();
      await randomToken.setUpgradePrice(upgradePrice);

      const attackPowerBefore = (
        await randomToken.tokenIdToChampion(1)
      ).attackPower;
      const defensePowerBefore = (
        await randomToken.tokenIdToChampion(1)
      ).defensePower;

      await expect(
        randomToken.upgradeChampion(1, true, true, {
          value: upgradePrice.mul(2),
        })
      )
        .to.emit(randomToken, "ChampionUpgraded")
        .withArgs(1, true, true);

      const attackPowerAfter = (
        await randomToken.tokenIdToChampion(1)
      ).attackPower;
      const defensePowerAfter = (
        await randomToken.tokenIdToChampion(1)
      ).defensePower;

      expect(attackPowerAfter).to.be.greaterThan(
        attackPowerBefore
      );
      expect(defensePowerAfter).to.be.greaterThan(
        defensePowerBefore
      );
    });

    it("Should revert if ValueSentIsTooLow", async () => {
      const upgradePrice = ethers.utils.parseEther("1");
      await randomToken.mint();
      await randomToken.setUpgradePrice(upgradePrice);

      await expect(
        randomToken.upgradeChampion(1, true, true, {
          value: upgradePrice.mul(2).sub(1),
        })
      ).to.be.revertedWithCustomError(
        randomToken,
        "ValueSentIsTooLow"
      );
    });
  });
});
