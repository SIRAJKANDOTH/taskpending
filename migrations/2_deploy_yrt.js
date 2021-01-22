var GnosisSafe = artifacts.require("./GnosisSafe.sol");
var Whitelist = artifacts.require("./whitelist/Whitelist.sol");
var APContract = artifacts.require("./aps/APContract.sol");

module.exports = async (deployer) => {
	await deployer.deploy(GnosisSafe);
	const gnosisSafe = await GnosisSafe.deployed();

	await deployer.deploy(Whitelist);
	const whitelist = await Whitelist.deployed();

	await deployer.deploy(APContract,gnosisSafe.address, whitelist.address);
	const apContract = await APContract.deployed();
	
};
