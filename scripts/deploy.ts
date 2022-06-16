// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from 'hardhat';

import {
  BullBear,
  BullBear__factory
} from '../typechain';

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy

  const bullBear_Factory: BullBear__factory = await ethers.getContractFactory(
    "BullBear"
  );
  const bullBear: BullBear = await bullBear_Factory.deploy(
    10,
    "0xECe365B379E1dD183B20fc5f022230C044d51404",
    "0x6168499c0cFfCaCD319c818142124B7A15E857ab" //https://docs.chain.link/docs/vrf-contracts/#configurations VRF Coordinator
  );

  await bullBear.deployed();

  console.log("Greeter deployed to:", bullBear.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
