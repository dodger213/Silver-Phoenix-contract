import {ethers} from 'hardhat';

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log('Deploying contracts with the account:', deployer.address);
  const SilverPhoenix = await ethers.getContractFactory('SilverPhoenix');
  const silverPhoenix = await SilverPhoenix.deploy();
  await silverPhoenix.deployed();
  console.log('SilverPhoenix deployed to:', silverPhoenix.address);
}