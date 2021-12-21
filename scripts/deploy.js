
const hre = require("hardhat");

async function main() {
  const SimpleToken = await hre.ethers.getContractFactory("SimpleToken");
  const simpleToken = await SimpleToken.deploy('SimpleToken', 'SIM', '1000000000');

  await simpleToken.deployed();

  console.log("Token deployed to:", simpleToken.address);
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
