var yrToken = artifacts.require("./yrToken.sol");
var GnosisSafe = artifacts.require("./GnosisSafe.sol");
var Whitelist = artifacts.require("./whitelist/Whitelist.sol");

// @NOTE: Deploy the token for test purpose (not required in production)
// module.exports = (deployer) => {
//   var wL = deployer.deploy(Whitelist);
//   var tkn = deployer.deploy(yrToken, 10000000000000);
//   Promise.all([wL, tkn]).then((res) => {
//     console.log("--------------------------------------------------------Response",res)
//     // await deployer.deploy(GnosisSafe, res[0].address, res[1].address);
//   });
// };
module.exports = async(deployer) => {
  deployer.deploy(Whitelist).then(async(whLst)=>{
    var tkn = await deployer.deploy(yrToken, 10000000000000);
    await deployer.deploy(GnosisSafe, tkn.address,whLst.address);
  });
  

};

// module.exports = async (deployer) => {
//   deployer.deploy(Whitelist)
//   deployer.deploy(yrToken, 10000000000000).then(async (token) => {
//     // await deployer.deploy(GnosisSafe, token.address);
//     console.log(token)
//   });
// };

