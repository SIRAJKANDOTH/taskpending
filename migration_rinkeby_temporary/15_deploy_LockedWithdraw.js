LockedWithdraw = artifacts.require("./smartStrategies/withdraw/LockedWithdraw.sol");

module.exports = async (deployer) => {
	await deployer.deploy(LockedWithdraw);
};
