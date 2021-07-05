let lockedWithdrawStorage = artifacts.require("./smartStrategies/withdraw/storage/LockStorage.sol");

module.exports = async (deployer) => {
	await deployer.deploy(lockedWithdrawStorage,
    "0xB24Ff34F5AE7F8Dde93A197FB406c1E78EEC0B25");
};