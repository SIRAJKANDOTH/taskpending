const APContract = artifacts.require("./aps/APContract.sol");
const StockDeposit = artifacts.require("./smartStrategies/deposit/StockDeposit.sol");
const StockWithdraw = artifacts.require("./smartStrategies/deposit/StockWithdraw.sol");


module.exports = async (deployer) => {
    const apContract = await APContract.deployed();

    await deployer.deploy(StockDeposit);
    const stockDeposit = await StockDeposit.deployed();

    await deployer.deploy(StockWithdraw);
    const stockWithdraw = await StockWithdraw.deployed();

    console.log("Adding Stock withdraw and deposit to APContract")
    await apContract.setStockDepositWithdraw(
        stockDeposit.address,
        stockWithdraw.address
    );

};
