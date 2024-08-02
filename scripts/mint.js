const hre = require("hardhat");
const { encryptDataField, decryptNodeResponse } = require("@swisstronik/utils");
const sendShieldedTransaction = async (signer, destination, data, value) => {
  const rpcLink = hre.network.config.url;
  const [encryptedData] = await encryptDataField(rpcLink, data);
  return await signer.sendTransaction({
    from: signer.address,
    to: destination,
    data: encryptedData,
    value,
  });
};

async function main() {
  const contractAddress = "0x9AFD6a8FC2408494d3D81bc889D2B960E05A06CD";
  const [signer] = await hre.ethers.getSigners();

  const contractFactory = await hre.ethers.getContractFactory("PERC20Token");
  const contract = contractFactory.attach(contractAddress);

  const functionName = "mint";
  const mintAmount = hre.ethers.parseUnits("1", 18); // Mint 1 token
  const mintTx = await sendShieldedTransaction(
    signer,
    contractAddress,
    contract.interface.encodeFunctionData(functionName, [signer.address, mintAmount]),
    0
  );

  await mintTx.wait();

  console.log("Mint Transaction Receipt: ", mintTx.hash);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
