const PlatformManagementFeeStorage = artifacts.require("./delegateContracts/storage/ManagementFeeStorage.sol");


module.exports = async (deployer) => {

    await deployer.deploy(PlatformManagementFeeStorage,"500000000000000000");

};
