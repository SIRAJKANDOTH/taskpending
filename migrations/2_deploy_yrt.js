var yrToken = artifacts.require("./yrToken.sol");
var GnosisSafe = artifacts.require("./GnosisSafe.sol");
var Whitelist = artifacts.require("./whitelist/Whitelist.sol");
var APContract = artifacts.require("./aps/APContract.sol");


module.exports = async(deployer) => {
  deployer.deploy(Whitelist).then(async(whLst)=>{
    let aps = await deployer.deploy(APContract);
    
    var tkn = await deployer.deploy(yrToken, 10000000000000);
    await deployer.deploy(GnosisSafe, [tkn.address],whLst.address,aps.address);
  });
  

};


