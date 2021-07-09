const Web3 = require("web3");
let web3 = new Web3("ws://localhost:8545");

const generate = () => {
  let instruction = web3.eth.abi.encodeFunctionCall(
    {
      name: "managementFeeCleanUp",
      type: "function",
      inputs: [],
    },
    []
  );
  return instruction;
};
// 0x749CD1474F4DF41D3810D0004A0a710D4AFC1BbF
// 0x8d2f54f100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000de30da39c46104798bb5aa3fe8b9e0e1f348163f;

// 0xa7be86ef
console.log(generate());
