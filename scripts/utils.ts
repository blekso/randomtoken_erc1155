import { ethers } from "hardhat";
import { Contract } from "ethers";

export const deployContract = async <T extends Contract>(
    factoryName: string,
    args?: any[]
  ) => {
    const Factory = await ethers.getContractFactory(factoryName);
    const contract = args
      ? await Factory.deploy(...args)
      : await Factory.deploy();
    await contract.deployed();
  
    return contract as T;
  };