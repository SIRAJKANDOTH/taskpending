const APContract = artifacts.require("./aps/APContract.sol");
const PlatformManagementFee = artifacts.require("./delegateContracts/ManagementFee.sol");
const ProfitManagementFee = artifacts.require("./delegateContracts/ProfitManagementFee.sol");
const HexUtils = artifacts.require("./utils/HexUtils.sol");
const Exchange = artifacts.require("./exchange/Exchange.sol");
const CleanUp = artifacts.require("./cleanUp/CleanUp.sol");
const Whitelist = artifacts.require("./whitelist/Whitelist.sol");
const PriceModule = artifacts.require("./price/PriceModule.sol");
const OneInch = artifacts.require("./oneInchMock/OneInch.sol");

module.exports = async (deployer) => {
	
    const hexUtils = await HexUtils.deployed();
	const exchange = await Exchange.deployed();
	const managementFee = await PlatformManagementFee.deployed();
	const profitManagementFee = await ProfitManagementFee.deployed();
	const cleanUp = await CleanUp.deployed();
	const whitelist = await Whitelist.deployed();
	const priceModule = await PriceModule.deployed();
	const oneInch = await OneInch.deployed();

	await deployer.deploy(
		APContract,
		whitelist.address,
		managementFee.address,      
		profitManagementFee.address,
		hexUtils.address,
		exchange.address,
		oneInch.address,
		priceModule.address,
		cleanUp.address
	);

};
