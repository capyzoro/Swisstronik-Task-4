#!/bin/bash

print_blue() {
    echo -e "\033[34m$1\033[0m"
}

print_red() {
    echo -e "\033[31m$1\033[0m"
}

print_green() {
    echo -e "\033[32m$1\033[0m"
}

print_pink() {
    echo -e "\033[95m$1\033[0m"
}

prompt_for_input() {
    read -p "$1" input
    echo $input
}

print_blue "Installing Hardhat and necessary dependencies..."
echo
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
echo

print_blue "Removing default package.json file..."
echo
rm package.json
echo

print_blue "Creating package.json file again..."
echo
cat <<EOL > package.json
{
  "name": "hardhat-project",
  "devDependencies": {
    "@nomicfoundation/hardhat-toolbox": "^3.0.0",
    "hardhat": "^2.17.1"
  },
  "dependencies": {
    "@openzeppelin/contracts": "^4.9.3",
    "@swisstronik/utils": "^1.2.1"
  }
}
EOL

print_blue "Initializing Hardhat project..."
npx hardhat
echo
print_blue "Removing the default Hardhat configuration file..."
echo
rm hardhat.config.js
echo
read -p "Enter your wallet private key: " PRIVATE_KEY

if [[ $PRIVATE_KEY != 0x* ]]; then
  PRIVATE_KEY="0x$PRIVATE_KEY"
fi

cat <<EOL > hardhat.config.js
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.19",
  networks: {
    swisstronik: {
      url: "https://json-rpc.testnet.swisstronik.com/",
      accounts: ["$PRIVATE_KEY"],
    },
  },
};
EOL

print_blue "Hardhat configuration file has been updated."
echo

rm -f contracts/Lock.sol
sleep 2

echo
print_pink "Enter TOKEN NAME:"
read -p "" TOKEN_NAME
echo
print_pink "Enter TOKEN SYMBOL:"
read -p "" TOKEN_SYMBOL
echo
cat <<EOL > contracts/PERC20Token.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PERC20Token is ERC20 {
    constructor() ERC20("$TOKEN_NAME", "$TOKEN_SYMBOL") {
        _mint(msg.sender, 1000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}
EOL
echo

npm install
echo
print_blue "Compiling the contract..."
echo
npx hardhat compile
echo

print_blue "Creating scripts directory and the deployment script..."
echo

mkdir -p scripts

cat <<EOL > scripts/deploy.js
const hre = require("hardhat");

async function main() {
  const contract = await hre.ethers.deployContract("PERC20Token");

  await contract.waitForDeployment();

  console.log(\`Contract address : \${contract.target}\`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
EOL
echo

npx hardhat run scripts/deploy.js --network swisstronik
echo

print_green "Contract deployment successful, Copy the above contract address and save it somewhere, you need to submit it in Testnet website"
echo
print_blue "Creating mint.js file..."
echo
read -p "Enter your Token Contract Address: " CONTRACT_ADDRESS
echo
cat <<EOL > scripts/mint.js
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
  const contractAddress = "$CONTRACT_ADDRESS";
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
EOL

cat <<EOL > scripts/transfer.js
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
  const contractAddress = "$CONTRACT_ADDRESS";
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
  console.log("Transfer Transaction Hash:", \`https://explorer-evm.testnet.swisstronik.com/tx/\${transferTx.hash}\`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
EOL

print_blue "Minting $TOKEN_SYMBOL..."
npx hardhat run scripts/mint.js --network swisstronik
echo
print_blue "Transferring $TOKEN_SYMBOL..."
npx hardhat run scripts/transfer.js --network swisstronik
echo
print_green "Copy the above Tx URL and save it somewhere, you need to submit it on Testnet page"
echo
sed -i 's/0x[0-9a-fA-F]*,\?\s*//g' hardhat.config.js
echo
print_blue "PRIVATE_KEY has been removed from hardhat.config.js."
echo
print_blue "Pushing these files to your GitHub Repo link"
git add . && git commit -m "Initial commit" && git push origin main
echo
print_pink "Follow @ZunXBT on X for more one click guide like this"
echo
