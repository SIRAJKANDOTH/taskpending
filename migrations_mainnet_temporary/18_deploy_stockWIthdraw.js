const StockWithdraw = artifacts.require("./smartStrategies/withdraw/StockWithdraw.sol");


module.exports = async (deployer) => {

    await deployer.deploy(StockWithdraw);
    const stockWithdraw = await StockWithdraw.deployed();

};
