const LockStorage = artifacts.require("./smartStrategies/withdraw/storage/LockStorage.sol");
const APContract = artifacts.require("./aps/APContract.sol");

module.exports = async (deployer) => {
	// const apContract = await APContract.deployed();
	await deployer.deploy(LockStorage, "0xc078e9f3994bef168e1af3b2195a2c4149cc3f36");
	// const lockStorage = await LockStorage.deployed();
    // console.log("Address of lockStorage: " + lockStorage.address);
};
