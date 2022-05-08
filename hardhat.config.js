require("hardhat-deploy")
require("dotenv").config()
require("@nomiclabs/hardhat-waffle")

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "rinkeby",
  networks: {
    hardhat: {
    },
    rinkeby: {
      //  url: process.env.RINKEBY_RPC_URL,
      //  accounts: [process.env.PRIVATE_KEY],
      url: "https://eth-rinkeby.alchemyapi.io/v2/V-kJsg-Glu5mIG5O4-N6BcoryXHlJwHp",
      accounts: ["0x1cad67b3186014f63212ea79fff1e45a4561675b7928bfa6557f6d6171150742"],
      chainId: 4,
      saveDeployments: true,
    }
  },
  namedAccounts: {
    deployer: {
      default: 0,
    }
  },
  solidity: "0.8.7",
};
