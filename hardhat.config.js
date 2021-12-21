require("dotenv").config();

require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-truffle4");
require("@nomiclabs/hardhat-etherscan");
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",
  networks: {
    hardhat: {},
    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      gasPrice: "auto",
      accounts: [process.env.AC_PRIV_KEY],
    },
    kovan: {
      url: `https://eth-kovan.alchemyapi.io/v2/${process.env.API_KEY_ALCHEMY_KOVAN}`,
      accounts: [process.env.AC_PRIV_KEY],
    },
  },
  etherscan: {
    //@nomiclabs/hardhat-etherscan specifically names etherscan instead of bscscan
    apiKey: process.env.API_BSCSCAN,
  },
};
