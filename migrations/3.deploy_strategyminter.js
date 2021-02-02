var StrategyMinter = artifacts.require("./strategies/StrategyMinter.sol");


module.exports = async (deployer) => {
	await deployer.deploy(StrategyMinter);
};
