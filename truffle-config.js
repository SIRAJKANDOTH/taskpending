const HDWalletProvider = require("@truffle/hdwallet-provider");
require("dotenv").config();
const package = require("./package");
const mnemonic = process.env.MNEMONIC;
const token = process.env.INFURA_TOKEN;
let privateKeys = [process.env.PRIVATE_KEY];

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*", // Match any network id
      websockets: true,
      gasPrice: 90000000000,
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
    goerli: {
      provider: () => {
        return new HDWalletProvider(
          "provide admit leaf net sun account error double end glue civil else",
          "https://goerli.infura.io/v3/" + "22a5f30310ca4933b9301d28efac5236"
        );
      },
      network_id: "5",
      gasPrice: 25000000000, // 25 Gwei
    },
    kovan: {
      provider: () => {
        return new HDWalletProvider(
          mnemonic,
          "https://kovan.infura.io/v3/" + token
        );
      },
      network_id: "42",
      gasPrice: 25000000000, // 25 Gwei
    },
    mainnet: {
      provider: () => {
        return new HDWalletProvider(privateKeys, token);
      },
      network_id: "1",
      gasPrice: 40000000000, // 115 Gwei
      networkCheckTimeout: 1000000000,
      gas: 2656227,
    },
    xdai: {
      provider: () => {
        return new HDWalletProvider(mnemonic, "https://dai.poa.network");
      },
      network_id: "100",
      gasPrice: 1000000000, // 1 Gwei
    },
    volta: {
      provider: () => {
        return new HDWalletProvider(
          mnemonic,
          "https://volta-rpc.energyweb.org"
        );
      },
      network_id: "73799",
      gasPrice: 1,
    },
    ewc: {
      provider: () => {
        return new HDWalletProvider(mnemonic, "https://rpc.energyweb.org");
      },
      network_id: "246",
      gasPrice: 1,
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
