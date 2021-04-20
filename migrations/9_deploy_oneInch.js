const PriceModule = artifacts.require("./price/PriceModule.sol");
const HexUtils = artifacts.require("./utils/HexUtils.sol");
const OneInch = artifacts.require("./oneInchMock/OneInch.sol");




module.exports = async (deployer) => {

	const priceModule = await PriceModule.deployed();
	const hexUtils = await HexUtils.deployed();
	await deployer.deploy(OneInch, hexUtils.address, priceModule.address);

	
};
