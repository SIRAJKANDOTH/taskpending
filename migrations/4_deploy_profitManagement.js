const ProfitManagementFee = artifacts.require("./delegateContracts/ProfitManagementFee.sol");

module.exports = async (deployer) => {
	
	await deployer.deploy(ProfitManagementFee);
	
};
