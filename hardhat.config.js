require("@nomiclabs/hardhat-waffle");
require('dotenv').config()

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.7.3",
};

module.exports = {
  solidity: "0.7.3",
  networks: {
    kovan: {
      url: `https://eth-kovan.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: [`0x${process.env.KOVAN_PRIVATE_KEY}`]
    }
  }
};