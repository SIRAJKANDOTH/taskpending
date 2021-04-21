const StockDeposit = artifacts.require("./smartStrategies/deposit/StockDeposit.sol");


module.exports = async (deployer) => {
    const apContract = await APContract.deployed();

    await deployer.deploy(StockDeposit);
    const stockDeposit = await StockDeposit.deployed();

};
