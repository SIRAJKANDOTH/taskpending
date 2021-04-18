const PlatformManagementFee = artifacts.require("./delegateContracts/ManagementFee.sol");
const ProfitManagementFee = artifacts.require("./delegateContracts/ProfitManagementFee.sol");
const HexUtils = artifacts.require("./utils/HexUtils.sol");
const Exchange = artifacts.require("./exchange/Exchange.sol");
const SafeUtils = artifacts.require("./safeUtils/SafeUtils.sol");

module.exports = async (deployer) => {

	await deployer.deploy(PlatformManagementFee);
	
	await deployer.deploy(ProfitManagementFee);
	
	await deployer.deploy(HexUtils);
	
	await deployer.deploy(Exchange);
	
	await deployer.deploy(SafeUtils);
	
};
