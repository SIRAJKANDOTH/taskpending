const PlatformManagementFee = artifacts.require("./delegateContracts/ManagementFee.sol");


module.exports = async (deployer) => {

    await deployer.deploy(PlatformManagementFee);

};
