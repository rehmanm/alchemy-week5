// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from 'hardhat';

import {
  BullBear,
  BullBear__factory,
  MockV3Aggregator,
  MockV3Aggregator__factory,
  VRFCoordinatorV2Mock,
  VRFCoordinatorV2Mock__factory
} from '../typechain';

const delay = (ms: number) => new Promise((res) => setTimeout(res, ms));

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy

  const [owner, account1] = await ethers.getSigners();

  //Deploy MockPriceFeed First

  const mockPriceFeedFactory: MockV3Aggregator__factory =
    await ethers.getContractFactory("MockV3Aggregator");

  const mockPriceFeed: MockV3Aggregator = await mockPriceFeedFactory.deploy(
    8,
    3034715771688
  );

  await mockPriceFeed.deployed();
  console.log("Mock Price Feed deployed to:", mockPriceFeed.address);

  console.log(
    "MockV3Aggregator latestRoundData:",
    await mockPriceFeed.latestRoundData()
  );

  const bullBear_Factory: BullBear__factory = await ethers.getContractFactory(
    "BullBear"
  );
  const bullBear: BullBear = await bullBear_Factory.deploy(
    10,
    mockPriceFeed.address,
    "0x6168499c0cFfCaCD319c818142124B7A15E857ab" //https://docs.chain.link/docs/vrf-contracts/#configurations VRF Coordinator
  );

  await bullBear.deployed();

  console.log("BullBear deployed to:", bullBear.address);

  //return;
  //VRF set subscriptionid

  await bullBear.setSubscriptionId(1);

  // const mockPriceFeedFactory: MockV3Aggregator__factory =
  //   await ethers.getContractFactory("MockV3Aggregator");

  // const mockPriceFeed: MockV3Aggregator = mockPriceFeedFactory.attach(
  //
  // );

  // const bullBear_Factory: BullBear__factory = await ethers.getContractFactory(
  //   "BullBear"
  // );
  // const bullBear: BullBear = bullBear_Factory.attach(

  // );

  //await bullBear.setSubscriptionId();

  console.log("Current Price", await bullBear.currentPrice());

  console.log("Price Feed Address", await bullBear.priceFeed());

  //Revert as no token uri exist
  //console.log("tokenUri", await bullBear.tokenURI(0));

  console.log("mint start");
  const mint = await bullBear.safeMint(owner.address);

  console.log("mint", mint);

  console.log("balance", await bullBear.balanceOf(owner.address));

  console.log("total Supply", (await bullBear.totalSupply()).toString());

  console.log("tokenUri", await bullBear.tokenURI(0));

  console.log("owner address", await bullBear.ownerOf(0));

  console.log("current price", await bullBear.currentPrice());

  await mockPriceFeed.updateAnswer(2834715771688);
  console.log(
    "current price after update before waitTime",
    await bullBear.currentPrice()
  );

  const waitTime = 15000;
  console.log(`Waiting for ${waitTime / 1000} seconds`);
  await delay(waitTime);
  console.log(`Waiting for ${waitTime / 1000} seconds completed`);

  console.log("Checking UpKeep", await bullBear.checkUpkeep([]));

  await bullBear.performUpkeep([]);

  console.log(
    "current price after interval time completed and performUpKeep executed",
    await bullBear.currentPrice()
  );
  console.log("tokenUri", await bullBear.tokenURI(0));

  console.log("owner address", await bullBear.ownerOf(0));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
