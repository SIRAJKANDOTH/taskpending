const LockStorage = artifacts.require("./smartStrategies/withdraw/storage/LockStorage.sol");
const APContract = artifacts.require("./aps/APContract.sol");

module.exports = async (deployer) => {

    const apContract = await APContract.deployed();
    console.log("apContract address = ", apContract.address);
	await deployer.deploy(LockStorage, apContract.address);
	const lockStorage = await LockStorage.deployed();
};
