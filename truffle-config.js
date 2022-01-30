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
      network_id: "*",
      websockets: true,
      gasPrice: 100 *(10**9),
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
    //   gasPrice: 20000000000, // 6 Gwei
    //   networkCheckTimeout: 1000000000,
    //   gas: 1622442,
    // },
    polygon: {
      provider: () => {
        return new HDWalletProvider(["63f199a49e62ce84ca7266f30338e46674984b02e20d5a41634fc0fbbd15f4d6"], "https://polygon-rpc.com");
      },
      network_id: "137",
      networkCheckTimeout: 1000000000,
    },
    fantom: {
      provider: () => {
        return new HDWalletProvider(["63f199a49e62ce84ca7266f30338e46674984b02e20d5a41634fc0fbbd15f4d6"], "https://rpc.ftm.tools");
      },
      network_id: "250",
      networkCheckTimeout: 1000000000,
    },
    binance: {
      provider: () => {
        return new HDWalletProvider(["63f199a49e62ce84ca7266f30338e46674984b02e20d5a41634fc0fbbd15f4d6"], "https://bsc-dataseed.binance.org");
      },
      network_id: "56",
      networkCheckTimeout: 1000000000,
    },//let token = await IERC20.at("0xc2132d05d31c914a87c6611c10748aeb04b58e8f")
  },//(await token.balanceOf("0x0d0707963952f2fba59dd06f2b425ace40b492fe")).toString()
  plugins: ["truffle-contract-size"],
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

/**
 * 1000000000
  
 let usdc = await IERC20.at("0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")
 await usdc.approve("0xdef1c0ded9bec7f1a1670819833240f027b25eff","0")

 await usdc.approve("0xdef1c0ded9bec7f1a1670819833240f027b25eff","1000000000")
 await web3.eth.sendTransaction({from:"0x5091af48beb623b3da0a53f726db63e13ff91df9",data:"0xd9627aa40000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000003b9aca00000000000000000000000000000000000000000000000000000000003ade05f800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7869584cd0000000000000000000000001000000000000000000000000000000000000011000000000000000000000000000000000000000000000041e29f364361d45b22",to:"0xdef1c0ded9bec7f1a1670819833240f027b25eff",value:"0",gas:"911000"}) 
 
 await web3.eth.sendTransaction({from:"0x5091af48beb623b3da0a53f726db63e13ff91df9",data:"0x7a1eb1b900000000000000000000000080fb784b7ed66730e8b1dbd9820afd29931aab03000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc200000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000002d246afbd2e2f5a500200000000000000000000000000000000000000000000000074463f51cf61aa070000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001600000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000185617438a72fe0e916000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000080fb784b7ed66730e8b1dbd9820afd29931aab03000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000185617438a72fe0e916000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000200000000000000000000000080fb784b7ed66730e8b1dbd9820afd29931aab03000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2869584cd0000000000000000000000001000000000000000000000000000000000000011000000000000000000000000000000000000000000000046e8a6b97b61d4779e",to:"0xdef1c0ded9bec7f1a1670819833240f027b25eff",value:"0",gas:"911000"}) 
 
 */