const APContract = artifacts.require("./aps/APContract.sol");
const PlatformManagementFee = artifacts.require("./delegateContracts/ManagementFee.sol");
const ProfitManagementFee = artifacts.require("./delegateContracts/ProfitManagementFee.sol");
const HexUtils = artifacts.require("./utils/HexUtils.sol");
const Exchange = artifacts.require("./exchange/Exchange.sol");
const SafeUtils = artifacts.require("./safeUtils/SafeUtils.sol");

module.exports = async (deployer) => {
	
    // const hexUtils = await HexUtils.deployed();
	// const exchange = await Exchange.deployed();
	// const managementFee = await PlatformManagementFee.deployed();
	// const profitManagementFee = await ProfitManagementFee.deployed();
	// const safeUtils = await SafeUtils.deployed();

	await deployer.deploy(
		APContract,
		"0xf8C992D12DC8a15e156869058717baC13d383F26",
		"0x4912a6e4c4da1a6d5d44520f81ca19352d8de7a7",      
		"0x826f9f3f4f2748f75cb57eb258603613e280b756",
		"0xAE9a070bed8b80050e3b8A26c169496b55C00D94",
		"0x1717ceaa4ba8b418595118c69b205715e469b966",
		"0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E",
		"0x7dF98189D32aa4e92649dBe5d837126bE4e53d1B",
		"0x7f629de3b0a9607befafb5f18d525f6e30f61afd"
	);

};
