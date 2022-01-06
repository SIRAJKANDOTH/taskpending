const HDWalletProvider = require("@truffle/hdwallet-provider");
require("dotenv").config();
const package = require("./package");
const Web3 = require("web3");
const token = process.env.INFURA_TOKEN_WSS;
// const webSocketProvider = new Web3.providers.WebsocketProvider(token);
// // // const mnemonic = process.env.MNEMONIC;
// let privateKeys = [process.env.PRIVATE_KEY_3];
// let privateKeys = [0];


module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "999",
      websockets: true,
      gasPrice: 110000000000, // 110 Gwei 13576784 await web3.eth.getBlock("13000000")
      // gas: 2907896,
      networkCheckTimeout: 999999,
    },
    // rinkeby: {
    //   network_id: "4",
    //   provider: () => {
    //     return new HDWalletProvider(mnemonic, token);
    //   },
    //   gasPrice: 75000000000, // 75 Gwei
    //   networkCheckTimeout: 10000000,
    //   skipDryRun: true,
    // },
    // mainnet: {
    //   provider: () => {
    //     return new HDWalletProvider(privateKeys, webSocketProvider);
    //   },
    //   network_id: "1",
    //   gasPrice: 110000000000, // 110 Gwei
    //   networkCheckTimeout: 1000000000,
    //   // gas: 551720,
    //   gas: 2907896,
    // },
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.5.17", // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      settings: {          // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 200
        },
        evmVersion: "petersburg"
      }
    },
  },
  plugins: ["truffle-contract-size"],
};
