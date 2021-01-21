var yrToken = artifacts.require("./yrToken.sol");
var GnosisSafe = artifacts.require("./GnosisSafe.sol");
var Whitelist = artifacts.require("./whitelist/Whitelist.sol");
var APContract = artifacts.require("./aps/APContract.sol");

module.exports = async (deployer) => {
	await deployer.deploy(Whitelist);
	const whitelist = await Whitelist.deployed();

	await deployer.deploy(APContract,whitelist.address);
	const apContract = await APContract.deployed();
  
	await deployer.deploy(GnosisSafe);
};
