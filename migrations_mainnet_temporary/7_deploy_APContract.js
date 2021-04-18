const APContract = artifacts.require("./aps/APContract.sol");
const PlatformManagementFee = artifacts.require("./delegateContracts/ManagementFee.sol");
const ProfitManagementFee = artifacts.require("./delegateContracts/ProfitManagementFee.sol");
const HexUtils = artifacts.require("./utils/HexUtils.sol");
const Exchange = artifacts.require("./exchange/Exchange.sol");
const SafeUtils = artifacts.require("./safeUtils/SafeUtils.sol");

module.exports = async (deployer) => {
	
    const hexUtils = await HexUtils.deployed();
	const exchange = await Exchange.deployed();
	const managementFee = await PlatformManagementFee.deployed();
	const profitManagementFee = await ProfitManagementFee.deployed();
	const safeUtils = await SafeUtils.deployed();

	await deployer.deploy(
		APContract,
		"0xf8C992D12DC8a15e156869058717baC13d383F26",
		managementFee.address,      
		profitManagementFee.address,
		hexUtils.address,
		exchange.address,
		"0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E",
		"0x7dF98189D32aa4e92649dBe5d837126bE4e53d1B",
		safeUtils.address
	);

};
