var StrategyMinter = artifacts.require("./strategies/StrategyMinter.sol");
var YearnItAll=artifacts.require("./strategies/YearnItAll.sol");


module.exports = async (deployer) => {
	await deployer.deploy(StrategyMinter);
	// await deployer.deploy(YearnItAll);
};
