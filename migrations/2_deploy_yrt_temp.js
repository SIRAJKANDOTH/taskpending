var CreateAndAddModules = artifacts.require("./yrToken.sol");

module.exports = function(deployer) {
    deployer.deploy(CreateAndAddModules,400000000000);
};