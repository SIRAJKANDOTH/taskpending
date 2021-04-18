LockedWithdraw = artifacts.require("./smartStrategies/withdraw/LockedWithdraw.sol");
LockedWithdrawMinter = artifacts.require("./smartStrategies/LockedWithdrawMinter.sol")
APContract = artifacts.require("./aps/APContract.sol")
module.exports = async (deployer) => {

	const apContract = await APContract.deployed();
	await deployer.deploy(LockedWithdraw);
	const lockedWithdraw = await LockedWithdraw.deployed();
	await deployer.deploy(LockedWithdrawMinter, apContract.address, lockedWithdraw.address);
};
