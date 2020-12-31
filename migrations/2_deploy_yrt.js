var yrToken = artifacts.require("./yrToken.sol");
var GnosisSafe = artifacts.require("./GnosisSafe.sol");

// @NOTE: Deploy the token for test purpose (not required in production)
module.exports = async (deployer) => {
  deployer.deploy(yrToken, 10000000000000).then(async (token) => {
    await deployer.deploy(GnosisSafe, token.address);
  });
};
