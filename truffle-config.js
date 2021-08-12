const HDWalletProvider = require("@truffle/hdwallet-provider");
require("dotenv").config();
const package = require("./package");
const Web3 = require("web3");
const webSocketProvider = new Web3.providers.WebsocketProvider(
  process.env.INFURA_TOKEN_WSS
);
const mnemonic = process.env.MNEMONIC;
const token = process.env.INFURA_TOKEN;
let privateKeys = [process.env.PRIVATE_KEY];

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "999",
      gasPrice: 30000000000, // 8 Gwei
      networkCheckTimeout: 999999,
    },
    rinkeby: {
      network_id: "4",
      provider: () => {
        return new HDWalletProvider(mnemonic, token);
      },
      gasPrice: 75000000000, // 75 Gwei
      networkCheckTimeout: 10000000,
      skipDryRun: true,
    },
    mainnet: {
      provider: () => {
        return new HDWalletProvider(privateKeys, webSocketProvider);
      },
      network_id: "1",
      gasPrice: 20000000000, // 6 Gwei
      networkCheckTimeout: 1000000000,
      gas: 1622442,
    },
  },
  plugins: ["truffle-contract-size"],
  compilers: {
    solc: {
      version: package.dependencies.solc,
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
        evmVersion: "petersburg",
      },
    },
  },
  plugins: ["truffle-contract-size"],
};
