const hre = require("hardhat");

async function main() {
  const contract = await hre.ethers.deployContract("PERC20Token");

  await contract.waitForDeployment();

  console.log(`Contract address : ${contract.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
