const LockedWithdrawMinter = artifacts.require("./smartStrategies/LockedWithdrawMinter.sol")
const LockedWithdraw = artifacts.require("./smartStrategies/withdraw/LockedWithdraw.sol")
const APContract = artifacts.require("./aps/APContract.sol");


module.exports = async (deployer) => {
    const apContract = await APContract.deployed();
    const lockedWithdraw = await LockedWithdraw.deployed();

    await deployer.deploy(
        LockedWithdrawMinter,
        apContract.address,
        lockedWithdraw.address

    );
    const lockedWithdrawMinter = await LockedWithdrawMinter.deployed();

    console.log("Adding lockedWithdraw to the APContract")
    await apContract.addSmartStrategy("locked Withdraw", lockedWithdraw.address, lockedWithdrawMinter.address,"0x92506Ee00ad88354fa25E6CbFa7d42116d6823C0");

};