// Importing necessary functionalities from the Hardhat package.
import { ethers } from 'hardhat';

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log('Deploying contracts with the account:', deployer.address);
  const SilverPhoenix = await ethers.getContractFactory('SilverPhoenix');
  const silverPhoenix = await SilverPhoenix.deploy();
  await silverPhoenix.deployed();
  console.log('SilverPhoenix deployed to:', silverPhoenix.address);
}

// This pattern allows the use of async/await throughout and ensures that errors are caught and handled properly.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });