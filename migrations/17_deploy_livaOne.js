const LivaOne = artifacts.require("./strategies/LivaOneZapper.sol");
const LivaOneMinter = artifacts.require("./strategies/LivaOneMinter.sol");
const APContract = artifacts.require("./aps/APContract.sol");



module.exports = async (deployer) => {
    const apContract = await APContract.deployed();

    await deployer.deploy(LivaOne, apContract.address, [
        "0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8",
        "0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e",
        "0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B",
    ]);
    const livaOne = await LivaOne.deployed();
    await deployer.deploy(LivaOneMinter, apContract.address, livaOne.address);


};