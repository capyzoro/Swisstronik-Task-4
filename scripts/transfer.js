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

  const functionName = "transfer";
  const transferAmount = hre.ethers.parseUnits("1", 18); // Transfer 1 token
  const transferTx = await sendShieldedTransaction(
    signer,
    contractAddress,
    contract.interface.encodeFunctionData(functionName, ["0x16af037878a6cAce2Ea29d39A3757aC2F6F7aac1", transferAmount]),
    0
  );

  await transferTx.wait();
  console.log("Transfer Transaction Hash:", `https://explorer-evm.testnet.swisstronik.com/tx/${transferTx.hash}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
