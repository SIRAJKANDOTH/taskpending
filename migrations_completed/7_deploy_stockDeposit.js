const StockDeposit = artifacts.require("./smartStrategies/deposit/StockDeposit.sol");


module.exports = async (deployer) => {
    await deployer.deploy(StockDeposit);
};
