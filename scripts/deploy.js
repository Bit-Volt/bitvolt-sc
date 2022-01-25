const hre = require("hardhat");
const CONSTRUCTOR_ARGS = require("./arguments");

async function main() {
  const SimpleToken = await hre.ethers.getContractFactory("SHIBACHARTS");
  const simpleToken = await SimpleToken.deploy(...CONSTRUCTOR_ARGS);
  
  await simpleToken.deployed();

  console.log("Token deployed to:", simpleToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
