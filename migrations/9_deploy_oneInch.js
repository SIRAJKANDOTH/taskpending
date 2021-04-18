const PriceModule = artifacts.require("./price/PriceModule.sol");
const OneInch = artifacts.require("./oneInchMock/OneInch.sol");




module.exports = async (deployer) => {

	const priceModule = await PriceModule.deployed();

	await deployer.deploy(OneInch, priceModule.address);

	
};
