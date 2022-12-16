const hre = require("hardhat");
require("dotenv").config({
  path: `${__dirname}/.env`,
});

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", await deployer.getAddress());
  console.log("Account balance:", (await deployer.getBalance()).toString());
  console.log(`NFT Distributor address: ${process.env.NFT_DISTRIBUTOR_ADDRESS}`);

  console.log(`====================`);

  // Deploy QuizardManager
  const QuizardManager = await ethers.getContractFactory("QuizardManager");
  const quizardManager = await QuizardManager.deploy();
  await quizardManager.deployed();

  console.log(`QuizardManager deployed to: ${quizardManager.address}`);

  // Deploy QuizardFactory
  const QuizardFactory = await ethers.getContractFactory("QuizardFactory");
  const quizardFactory = await QuizardFactory.deploy();
  await quizardFactory.deployed();

  console.log(`QuizardFactory deployed to: ${quizardFactory.address}`);

  // Set the QuizardManager address in the QuizardFactory
  await quizardFactory.setQuizardManager(quizardManager.address);

  // Set the QuizardFactory address in the QuizardManager
  await quizardManager.setQuizardFactory(quizardFactory.address);

  // Deploy QuizardNFT
  const QuizardNFT = await ethers.getContractFactory("QuizardNFT");
  const quizardNFT = await QuizardNFT.deploy("Quizard NFT", "QUIZARDNFT", false, quizardManager.address);
  await quizardNFT.deployed();

  console.log(`QuizardNFT deployed to: ${quizardNFT.address}`);

  console.log(`====================`);

  // Set the QuizardNFT address in the QuizardManager
  await quizardManager.setQuizardNFT(quizardNFT.address);

  // Set the NFT distributor address
  await quizardManager.setNFTDistributor(process.env.NFT_DISTRIBUTOR_ADDRESS);

  // Check the settings of the QuizardManager
  console.log(`QuizardManager factory`, await quizardManager.getQuizardFactory());
  console.log(`QuizardManager distributor`, await quizardManager.getNFTDistributor());
  console.log(`QuizardManager nft`, await quizardManager.getQuizardNFT());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
