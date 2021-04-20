const LivaOne = artifacts.require("./strategies/LivaOneZapper.sol");
const LivaOneMinter = artifacts.require("./strategies/LivaOneMinter.sol");
const APContract = artifacts.require("./aps/APContract.sol");



module.exports = async (deployer) => {
    const apContract = await APContract.deployed();
    const livaOne = await LivaOne.deployed();

    await deployer.deploy(LivaOneMinter, apContract.address, livaOne.address);
    const livaOneMinter = await LivaOneMinter.deployed();

    console.log("adding Liva one to APContract")
    await apContract.addStrategy(
        "Liva One",
        livaOne.address,
        [
            "0xd27Dc2D8ceF541f94FbA737079F2DFeA39B2EEf8",
            "0xD8052918CAd9a8B3a564d7Aa4e680a0dc156380e",
            "0x3662ABD754eE1d8CB6f5F1D4E315932b36e9955B",
        ],
        livaOneMinter.address,
        "0x92506Ee00ad88354fa25E6CbFa7d42116d6823C0",
        "0x92506Ee00ad88354fa25E6CbFa7d42116d6823C0",
        "2000000000000000"
    );

};