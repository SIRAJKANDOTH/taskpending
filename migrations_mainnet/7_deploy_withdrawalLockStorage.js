const LockStorage = artifacts.require("./smartStrategies/withdraw/storage/LockStorage.sol");

module.exports = async (deployer) => {
	await deployer.deploy(LockStorage);
	const lockStorage = await LockStorage.deployed();
    console.log("Address of lockStorage: " + lockStorage.address);
};
